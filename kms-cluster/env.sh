#!/bin/bash
ret=$(curl https://ipapi.co/json| grep -v org)
ret=`echo $ret | sed 's/ip/public_ip/g'`

IP_INFO=`echo $ret | sed 's/"//g'| sed 's/{//g'| sed 's/}//g'| sed '/^$/g'| sed 's/[[:space:]]//g'`

export PRIVATE_IP=$(cat /etc/hosts | grep `hostname` |awk '{print $1}')
export PUBLIC_IP=`echo $IP_INFO | awk -F ',' '{print $1}' | awk -F ':' '{print $2}'`
export TAG_INFO=`echo private_ip:$PRIVATE_IP,$IP_INFO`
export KMS_VOLUME='/home/waypal/volume/kms-cluster/kms'
export COTURN_VOLUME='/home/waypal/volume/kms-cluster/coturn'
export CONSUL_VOLUME='/home/waypal/volume/kms-cluster/consul'
export TELEGRAF_VOLUME='/home/waypal/volume/kms-cluster/telegraf'
export TRANSCODER_VOLUME='/home/waypal/volume/kms-cluster/transcoder'
export TRANSCODER_DB_VOLUME='/home/waypal/nas-volume/config/docker/transcoderdb'

export GRAPHITE_SERVER_IP='172.17.101.170'
export GRAPHITE_SERVER_PORT='12003'

export CONSUL_IP=$PRIVATE_IP
export EXPOSE_IP=$PRIVATE_IP
echo "!!!!Warning:Please configure consul server IP"
export JOIN_IP="172.17.101.173"

export KMS_IGNORE='##'
export KMS_NAME=`hostname`
KMS_IP=`cat /etc/hosts | grep $KMS_NAME| awk '{print $1}'`
export KMS_URI='ws://'$KMS_IP':8888/kurento'

export USERID=`id -u waypal`
export USERGID=`id -g waypal`

export REGION='pro'
export SERVICE_NAME=$REGION-$PRIVATE_IP
