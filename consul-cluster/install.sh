#!/bin/bash

source env.sh

envsubst <base-compose.yml> docker-compose.yml

