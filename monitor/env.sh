#!/bin/bash
export PRIVATE_IP=$(cat /etc/hosts | grep `hostname` |awk '{print $1}')
ret=$(curl https://ipapi.co/json| grep -v org)
ret=`echo $ret | sed 's/ip/public_ip/g'`
IP_INFO=`echo $ret | sed 's/"//g'| sed 's/{//g'| sed 's/}//g'| sed '/^$/g'| sed 's/[[:space:]]//g'`

export PUBLIC_IP=`echo $IP_INFO | awk -F ',' '{print $1}' | awk -F ':' '{print $2}'`

export WAYPAL_DB_USER='waypal'
export WAYPAL_DB_PWD='waypal'

export MONITOR_VOLUME='/home/waypal/volume/monitor'
export KMS_VOLUME='/home/waypal/volume/kms'

export ACADVISOR_HOSTNAME=`hostname`
export ACADVISOR_DB='cadvisor'

export INFLUXBD_SERVER_IP=${PUBLIC_IP}
export INFLUXDB_SERVER_PORT='8086'

export GRAFANA_SERVER_IP=${PUBLIC_IP}
export GRAFANA_SERVER_PORT='13000'

export GRAPHITE_SERVER_IP=${PUBLIC_IP}
export GRAPHITE_SERVER_PORT='12003'

export ESEARCH_SERVER_URL='http://'${PUBLIC_IP}':9200'



