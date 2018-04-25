#!/bin/bash
filePath=/home/waypal/conf/monitor/docker-compose
fileDate=`date +%Y-%m-%d`
logfile=reset-kms-$fileDate.log
dockerCompose=/usr/local/bin/docker-compose

source /home/waypal/.bash_profile
env >$logfile 2>&1

if [ ! -d "$filePath" ]; then
	echo "$filePath is not exit"
	exit 1
fi

pushd $filePath
if [ ! -f "$logfile" ]; then
	touch $logfile
	echo "Start reset kms coturn and kmonitor docker!!!" >$logfile 
fi
popd

function check_status
{
	if [ $? -eq 0 ]; then
		echo "$1 is success!" >>$logfile
	else
		echo "$1 is failed!!!">>$logfile	
	fi
}

pushd /home/waypal/conf/monitor/docker-compose
echo "" >>$logfile
echo "" >>$logfile
echo "#####################################################" >>$logfile
echo `date +%Y-%m-%d %H:%M:%S` >> $logfile
echo "start reset" >>$logfile

$dockerCompose kill coturn
check_status 'kill coturn'

$dockerCompose kill kms
check_status 'kill kms'

$dockerCompose kill kmonitor
check_status 'kill kmonitor'

$dockerCompose rm --force coturn 
check_status 'rm coturn'

$dockerCompose rm --force kms 
check_status 'rm kms'

$dockerCompose rm --force kmonitor
check_status 'rm kmonitor'

$dockerCompose up -d coturn kms kmonitor
check_status 'docker compose update coturn kms and kmonitor'

docker network prune --force
check_status 'prune unused docker network!!!'

echo engine | sudo -S ip link set dev docker0 down
check_status 'set ip link docker0 down'
echo "end reset" >>$logfile
echo "#####################################################" >>$logfile
popd
