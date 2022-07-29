ARG FDB_VERSION=7.1.9
FROM golang:1.13.6-stretch
ARG FDB_VERSION

COPY ./ ./fdb-exporter

RUN wget "https://github.com/apple/foundationdb/releases/download/${FDB_VERSION}/foundationdb-clients_${FDB_VERSION}-1_amd64.deb"
RUN dpkg -i foundationdb-clients_${FDB_VERSION}-1_amd64.deb
WORKDIR ./fdb-exporter/src
RUN go env -w GO111MODULE=on && \
	go env -w GOPROXY=https://goproxy.cn,direct && \
	GOOS=linux GOARCH=amd64 && \
	go build

CMD ["./fdb-prometheus-exporter"]