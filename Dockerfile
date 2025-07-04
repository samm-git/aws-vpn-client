FROM alpine:3.20.3 AS ovpn-builder

ARG OPENVPN_VERSION="2.6.12"

WORKDIR /opt/openvpn

RUN apk add --no-cache curl tar libcap-ng-dev linux-headers linux-pam-dev lz4-dev lzo-dev \
        openssl-dev iproute2-minimal build-base pkgconfig libnl3-dev patch

RUN curl --fail -L -o openvpn.tar.gz "https://github.com/OpenVPN/openvpn/releases/download/v$OPENVPN_VERSION/openvpn-$OPENVPN_VERSION.tar.gz" \
    && tar xzf openvpn.tar.gz \
    && cd "openvpn-$OPENVPN_VERSION" \
    && curl --fail -o openvpn-aws.patch "https://raw.githubusercontent.com/botify-labs/aws-vpn-client/refs/heads/master/patches/openvpn-v$OPENVPN_VERSION-aws.patch" \
    && patch -p1 < "openvpn-aws.patch" \
    && ./configure --with-crypto-library=openssl \
    && make -j8 \
    && cp "/opt/openvpn/openvpn-$OPENVPN_VERSION/src/openvpn/openvpn" /opt/openvpn/openvpn-bin

FROM golang:1.23.1-alpine3.20 AS server-builder

WORKDIR /opt/go-server

COPY server.go ./

# Build go server
RUN go mod init server \
    && go build

FROM alpine:3.20.3 AS container

WORKDIR /opt/openvpn

RUN apk add --no-cache busybox-binsh iproute2-minimal libcap-ng libcrypto3 libssl3 lz4-libs lzo musl libnl3 openssl bind-tools

COPY --from=ovpn-builder /opt/openvpn/openvpn-bin .
COPY --from=server-builder /opt/go-server/server ./go_server
COPY profile.ovpn .
COPY entrypoint.sh .

ENTRYPOINT ["ash", "./entrypoint.sh"]
