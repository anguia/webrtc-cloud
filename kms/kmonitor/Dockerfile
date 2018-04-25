FROM java:8u40-b09-jre

RUN mkdir -p /waypal/bin && \
	mkdir -p /waypal/tmp && \
	mkdir -p /waypal/log

COPY ./rootfs/ /
COPY ./bin /waypal/bin/

ENV KMS_URI="ws://localhost:8888/kurento" \
  KMS_Name="kms01" \
	GRAPHITE_IP="172.17.101.170" \
	GRAPHITE_PORT="12003" \
	PATH="/waypal/bin:$PATH"

WORKDIR /waypal

CMD ["/run.sh"]
