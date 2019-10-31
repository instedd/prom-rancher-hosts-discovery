FROM alpine:edge AS build
RUN apk add crystal shards alpine-sdk zlib-dev openssl-dev
ADD . /src
WORKDIR /src
RUN shards build

FROM alpine:edge
RUN apk add --no-cache pcre libevent libgcc
COPY --from=build /src/bin/prom-rancher-hosts-discovery /
ENTRYPOINT ["/prom-rancher-hosts-discovery"]
