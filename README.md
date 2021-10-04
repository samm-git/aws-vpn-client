# aws-vpn-client

This is PoC to connect to the AWS Client VPN with OSS OpenVPN using SAML
authentication. Tested on macOS and Linux, should also work on other POSIX OS with a minor changes.

See [my blog post](https://smallhacks.wordpress.com/2020/07/08/aws-client-vpn-internals/) for the implementation details.

P.S. Recently [AWS released Linux desktop client](https://aws.amazon.com/about-aws/whats-new/2021/06/aws-client-vpn-launches-desktop-client-for-linux/), however, it is currently available only for Ubuntu, using Mono and is closed source. 

## Content of the repository

- [openvpn-v2.4.9-aws.patch](openvpn-v2.4.9-aws.patch) - patch required to build
AWS compatible OpenVPN v2.4.9, based on the
[AWS source code](https://amazon-source-code-downloads.s3.amazonaws.com/aws/clientvpn/osx-v1.2.5/openvpn-2.4.5-aws-2.tar.gz) (thanks to @heprotecbuthealsoattac) for the link.
- [server.go](server.go) - Go server to listed on http://127.0.0.1:35001 and save
SAML Post data to the file
- [aws-connect.sh](aws-connect.sh) - bash wrapper to run OpenVPN. It runs OpenVPN first time to get SAML Redirect and open browser and second time with actual SAML response

## How to use

1. Build patched openvpn version and put it to the folder with a script
1. Start HTTP server with `go run server.go`
1. Set VPN_HOST in the [aws-connect.sh](aws-connect.sh)
1. Replace CA section in the sample [vpn.conf](vpn.conf) with one from your AWS configuration
1. Finally run `aws-connect.sh` to connect to the AWS.

### Additional Steps

Inspect your ovpn config and remove the following lines if present
- `auth-user-pass` (we dont want to show user prompt)
- `auth-federate` (propietary AWS keyword)
- `auth-retry interact` (do not retry on failures)
- `remote` and `remote-random-hostname` (already handled in CLI and can cause conflicts with it)

## Todo

Better integrate SAML HTTP server with a script or rewrite everything on golang
