#!/bin/bash

##
# This script automatically does the following upon the completion of a torrent:
# 1. Ping pushover with result
# 2. determine type of file/directory
# 3. send file/directory to offsite storage

torrentid=$1
torrentname=$2
torrentpath=$3

# General Options
HOST='HOSTADDRESS' # Reset with Host Address
USER='USERNAME' # Reset with user name
PASS='PASSWORD' # no password. using scp public key
ROOT='LOCALROOT' # Reset with local root for downloads
TARGETDIRRSS='/Volumes/Public-XS/TV-Inbox' # Remote directory for RSS Feeds
TARGETDIRMANUAL='/Volumes/Public-XS/Torrent-Inbox' # Remote directory for Manual Torrents
NOW=$(date +"%m-%d-%y")
DELUGESERVER='127.0.0.1' # deluged server address
DELUGEPORT='xxxxx' # deluged port
DELUGEUSER='xxxxx' # login for deluged
DELUGEPASS='xxxxx' # Password for deluged

# Pushover Options
USEPUSHOVER='1';
PUSHOVERTOKEN='TokenString' # Pushover Token for pushover notifications
PUSHOVERUSER='UserString' # Pushover user for pushover notifications
PUSHOVERDEVICE='DeviceName' # Pushover device for pushover notifications

## Mark torrent in log
echo "------" >> ~execute_script.log
echo $NOW >> ~/execute_script.log 
echo "Torrent Details: ***" $torrentname "***" $torrentpath "***" $torrentid "***"  >> ~/execute_script.log

## Ping Pushover
if [ "$USEPUSHOVER" == "1"]
then
	curl -s \
        -F "token=$PUSHOVERTOKEN" \
        -F "user=$PUSHOVERUSER" \
        -F "message=$torrentname downloaded" \
        -F "device=$PUSHOVERDEVICE" \
        https://api.pushover.net/1/messages.json

	echo "     Ping to Pushover Sent." >> ~/execute_script.log
fi

if [ "$ROOT/deluge.tv/" == "$torrentpath" ]
then
	echo "     This is an auto-rss torrent, deleting from deluge and sending with SCP" >> ~/execute_script.log
	deluge-console "connect $DELUGESERVER:$DELUGEPORT $DELUGEUSER $DELUGEPASS; del $torrentid"
	if [ -f "$torrentpath/$torrentname" ]
	then
		echo "     Torrent is a single file" >> ~/execute_script.log
		scp "$torrentpath/$torrentname" $USER@$HOST:$TARGETDIRRSS
	else
		echo "     Torrent is a folder" >> ~/execute_script.log
		scp -r "$torrentpath/$torrentname" $USER@$HOST:$TARGETDIRRSS
	fi
elif [ "$ROOT/deluge.files/" == "$torrentpath" ]
then
	echo "     This is a manual torrent, sending with SCP" >> ~/execute_script.log
	if [ -f "$torrentpath/$torrentname" ]
	then
		echo "     Torrent is a single file" >> ~/execute_script.log
		scp "$torrentpath/$torrentname" $USER@$HOST:$TARGETDIRMANUAL
	else
		echo "     Torrent is a folder" >> ~/execute_script.log
		scp -r "$torrentpath/$torrentname" $USER@$HOST:$TARGETDIRMANUAL
	fi
else
	echo "     This is an unrecognized torrent, sending with SCP" >> ~execute_script.log
	if [ -f "$torrentpath/$torrentname" ]
	then
		echo "     Torrent is a single file" >> ~/execute_script.log
		scp "$torrentpath/$torrentname" $USER@$HOST:$TARGETDIRMANUAL
	else
		echo "     Torrent is a folder" >> ~execute_script.log
		scp -r "$torrentpath/$torrentname" $USER@HOST:$TARGETDIRMANUAL
	fi
fi
NEWNOW=$(date +"%m-%d-%y")

# Ping pushover again for completed FTP
if [ "$USEPUSHOVER" == "1"]
then
	curl -s \
        -F "token=$PUSHOVERTOKEN" \
        -F "user=$PUSHOVERUSER" \
        -F "message=$torrentname FTP completed" \
        -F "device=$PUSHOVERDEVICE" \
        https://api.pushover.net/1/messages.json
    echo "     Upload finished at $NEWNOW. Final pushover ping sent." >> ~/execute_script.log
	echo "------" >> ~/execute_script.log
else
	echo "     Upload finished at $NEWNOW." >> ~/execute_script.log
	echo "------" >> ~/execute_script.log
fi


# Cleanup old files to ensure that the server doesn't get full

find $ROOT/deluge.tv -iname "*" -mtime +5 -print0 | xargs -0 rm -fR
find $ROOT/deluge.files -iname "*" -mtime +5 -print0 | xargs -0 rm -fR
