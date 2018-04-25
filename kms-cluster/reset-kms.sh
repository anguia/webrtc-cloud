#!/bin/bash
filePath=/home/waypal/conf/kms-cluster/log
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
	echo "Start reset kms cluster!!!" >$logfile 
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

pushd $filePath 
echo "" >>$logfile
echo "" >>$logfile
echo "#####################################################" >>$logfile
echo `date "+%Y-%m-%d %H:%M:%S.%N"` >> $logfile
echo "start reset" >>$logfile

$dockerCompose kill coturn kms
check_status 'kill coturn and kms'

$dockerCompose kill consul-agent
check_status 'kill consul agent'

$dockerCompose down
check_status 'close all containers'

$dockerCompose up -d 
check_status 'docker compose update and start all containers'

docker system prune --force
check_status 'prune unused docker resource!!!'

#docker volume rm $(docker volume ls -qf dangling=true)
#check_status 'clean unused local volume'

echo engine | sudo -S ip link set dev docker0 down
check_status 'set ip link docker0 down'
echo "end reset" >>$logfile
echo `date "+%Y-%m-%d %H:%M:%S.%N"` >> $logfile
echo "#####################################################" >>$logfile
popd
