#!/bin/bash

source env.sh

envsubst <base-compose.yml> docker-compose.yml

if [ ! -d "$KMS_VOLUME" ]; then
        echo "$KMS_VOLUME" is not exit
        mkdir -p $KMS_VOLUME/etc/kurento/modules/kurento
        cp kms/kurento/*.ini $KMS_VOLUME/etc/kurento/modules/kurento/
        cp kms/kurento/SdpEndpoint.conf.json $KMS_VOLUME/etc/kurento/modules/kurento/
        cp kms/kurento/kurento.conf.json $KMS_VOLUME/etc/kurento/

fi

if [ ! -d "$TELEGRAF_VOLUME" ]; then
        echo "$TELEGRAF_VOLUME" is not exit
        mkdir -p $TELEGRAF_VOLUME/etc/telegraf
        cp telegraf/conf/telegraf.conf $TELEGRAF_VOLUME/etc/telegraf/
fi

