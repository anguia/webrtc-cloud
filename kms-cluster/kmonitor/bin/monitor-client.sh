#!/bin/sh

app_name="/waypal/bin/waypal-monitor-client-6.6.2-exec.jar"

usage="$(basename "$0") [--help] [start|start-foreground|stop|status] -- Wrapper to start the tensorflow service"


is_kms_monitor_service_running() {
    PID=''
    RUNNING=0
    if [ -f "/waypal/tmp/kms-monitor.pid" ]; then
        PID=$(cat "/waypal/tmp/kms-monitor.pid")
    fi
    if [ -n "${PID}" ] && kill -0 $PID 2>/dev/null ; then
        RUNNING=1
    else
        RUNNING=0
    fi
    return $RUNNING
}

case "$1" in
    --help)
        echo "$usage"
        exit
        ;;
    start)
        is_kms_monitor_service_running
        RUNNING=$?
        if [ $RUNNING -eq 0 ]; then
            echo "kms monitor service is not running... starting service in background mode"
            java -jar $app_name kmsURI=$KMS_URI kmsName=$KMS_NAME graphiteIP=$GRAPHITE_IP graphitePort=$GRAPHITE_PORT  > "/waypal/log/kms-monitor.log" 2>&1 &
            echo $! > "/waypal/tmp/kms-monitor.pid"
        else
            echo "KMS Monitor Service is already running"
        fi
        ;;
    start-foreground)
        is_kms_monitor_service_running
        RUNNING=$?
        if [ $RUNNING -eq 0 ]; then
            echo "kms monitor service is not running... starting service in background mode"
						java -jar $app_name kmsURI=$KMS_URI kmsName=$KMS_NAME graphiteIP=$GRAPHITE_IP graphitePort=$GRAPHITE_PORT  > "/waypal/log/kms-monitor.log"

        else
            echo "KMS Monitor Service is already running"
        fi
        ;;
    stop)
        if [ -f "/waypal/tmp/kms-monitor.pid" ]; then
            echo "Stopping KMS monitor service"
            PID=$(cat "/waypal/tmp/kms-monitor.pid")
            kill -0 $PID > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                kill -INT $PID
            fi
            rm "/waypal/tmp/kms-monitor.pid"
        else
            echo "TensorFlow Serving is not running"
        fi
        ;;
    status)
        is_tensorflow_serving_running
        RUNNING=$?
        if [ $RUNNING -eq 0 ]; then
            echo "TensorFlow Serving is not running"
        else
            echo "TensorFlow Serving is running"
        fi
        ;;
    *)
        echo "echo $usage"
        exit 1
        ;;
esac
