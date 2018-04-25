#!/bin/bash
set -e

if [ $NAT = "true" -a -z "$EXTERNAL_IP" ]; then

  # Try to get public IP
  PUBLIC_IP=$(curl http://icanhazip.com) || exit 1

  # Try to get private IP
  PRIVATE_IP=$(cat /etc/hosts |grep `hostname` |awk '{print $1}') || exit 1
  export EXTERNAL_IP="$PUBLIC_IP/$PRIVATE_IP"
  echo "Starting turn server with external IP: $EXTERNAL_IP"
fi


echo 'min-port=40000' > /etc/turnserver.conf
echo 'max-port=45000' >> /etc/turnserver.conf
echo 'fingerprint' >> /etc/turnserver.conf
echo 'lt-cred-mech' >> /etc/turnserver.conf
echo "realm=$REALM" >> /etc/turnserver.conf
echo "relay-threads=50" >> /etc/turnserver.conf
#echo "max-bps=640000" >> /etc/turnserver.conf
#echo "bps-capacity=640000" >> /etc/turnserver.conf
echo 'log-file stdout' >> /etc/turnserver.conf
echo "user=$TURN_USERNAME:$TURN_PASSWORD" >> /etc/turnserver.conf
[ $NAT = "true" ] && echo "external-ip=$EXTERNAL_IP" >> /etc/turnserver.conf

exec /usr/bin/turnserver "$@"
