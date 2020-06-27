FROM golang:1.14.4-buster AS build
WORKDIR /fluent-bit-go-s3

ARG PLUGIN_NAME="unknown"
ARG VERSION="unknown"
ARG REVISION="unknown"

ENV GOPROXY=https://proxy.golang.org
COPY go.mod ./
RUN go mod download

COPY *.go ./
RUN GO_EXTLINK_ENABLED=1 CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build \
    -o /go/bin/out_s3.so \
    -buildmode=c-shared \
    -ldflags="-s -X main.name=${PLUGIN_NAME} -X main.version=${VERSION} -X main.revision=${REVISION}" \
    -tags netgo -installsuffix netgo \
    -v github.com/cosmo0920/fluent-bit-go-s3

FROM fluent/fluent-bit:1.4.6 AS final
LABEL Description="Fluent Bit S3" FluentBitVersion="1.4.6"

COPY --from=build /go/bin/out_s3.so /usr/lib/x86_64-linux-gnu/

EXPOSE 2020

# Entry point
CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf", "-e", "/usr/lib/x86_64-linux-gnu/out_s3.so"]
