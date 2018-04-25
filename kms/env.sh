#!/bin/bash
ret=$(curl https://ipapi.co/json| grep -v org)
ret=`echo $ret | sed 's/ip/public_ip/g'`

IP_INFO=`echo $ret | sed 's/"//g'| sed 's/{//g'| sed 's/}//g'| sed '/^$/g'| sed 's/[[:space:]]//g'`

export PRIVATE_IP=$(cat /etc/hosts | grep `hostname` |awk '{print $1}')
export PUBLIC_IP=`echo $IP_INFO | awk -F ',' '{print $1}' | awk -F ':' '{print $2}'`

export TAG_INFO=`echo private_ip:$PRIVATE_IP,$IP_INFO`

export KMS_VOLUME='/home/waypal/volume/kms-cluster/kms'
export COTURN_VOLUME='/home/waypal/volume/kms-cluster/coturn'
export MONITOR_VOLUME='/home/waypal/volume/kms-cluster/monitor'

export GRAPHITE_SERVER_IP='172.17.101.170'
export GRAPHITE_SERVER_PORT='12003'

export CONSUL_IP=$PRIVATE_IP
export EXPOSE_IP=$PRIVATE_IP

export KMS_NAME=`hostname`
KMS_IP=`cat /etc/hosts | grep $KMS_NAME| awk '{print $1}'`
export KMS_URI='ws://'$KMS_IP':8888/kurento'

export REGION='DEV'
