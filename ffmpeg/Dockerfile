FROM jrottenberg/ffmpeg:3.4

RUN apt-get install -y  --no-install-recommends python-pyinotify python-pip \
        && pip install --upgrade setuptools pip\
        && pip install apscheduler \
        && mkdir -p /var/log/transocoder \
        && mkdir -p /transcoder \
        && mkdir -p /transcoderdb

COPY ./transcoder/ /transcoder/

WORKDIR /transcoder

VOLUME /records
VOLUME /var/log/transcoder/

ENTRYPOINT ["python", "/transcoder/transcoder.py","/records"]
