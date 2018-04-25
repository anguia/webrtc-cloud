#!/bin/bash
ret=$(curl https://ipapi.co/json| grep -v org)
ret=`echo $ret | sed 's/ip/public_ip/g'`

IP_INFO=`echo $ret | sed 's/"//g'| sed 's/{//g'| sed 's/}//g'| sed '/^$/g'| sed 's/[[:space:]]//g'`

export PRIVATE_IP=$(cat /etc/hosts | grep `hostname` |awk '{print $1}')
export PUBLIC_IP=`echo $IP_INFO | awk -F ',' '{print $1}' | awk -F ':' '{print $2}'`
export CONSUL_VOLUME='/home/waypal/volume/consul-cluster/consul'
export TAG_INFO=`echo private_ip:$PRIVATE_IP,$IP_INFO`

export CONSUL_IP=$PRIVATE_IP
export EXPOSE_IP=$PRIVATE_IP
echo "!!!!Warning:Please configure consul server IP"
export JOIN_IP="172.17.101.173"

export REGION='dev'
export NETWORK=$REGION-net
ret=`docker network ls |grep $NETWORK`
if [[ $ret == *$NETWORK* ]]
then
  echo "Share network:$NETWORK had created"
  echo $ret
else
  echo "Create share network"
  ret=`docker network create --driver=bridge --subnet=192.168.100.0/24 $NETWORK`
  ret=`docker network ls |grep $NETWORK`
  echo $ret
fi

export SERVICE_NAME=$REGION-$PRIVATE_IP
export USERID=`id -u waypal`
export USERGID=`id -g waypal`



