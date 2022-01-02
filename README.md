# aws-vpn-client

This is PoC to connect to the AWS Client VPN with OSS OpenVPN using SAML
authentication. Tested on macOS and Linux, should also work on other POSIX OS with a minor changes.

See [my blog post](https://smallhacks.wordpress.com/2020/07/08/aws-client-vpn-internals/) for the implementation details.

P.S. Recently [AWS released Linux desktop client](https://aws.amazon.com/about-aws/whats-new/2021/06/aws-client-vpn-launches-desktop-client-for-linux/), however, it is currently available only for Ubuntu, using Mono and is closed source. 

## Content of the repository

- [openvpn-v2.4.9-aws.patch](openvpn-v2.4.9-aws.patch) - patch required to build
AWS compatible OpenVPN v2.4.9, based on the
[AWS source code](https://amazon-source-code-downloads.s3.amazonaws.com/aws/clientvpn/osx-v1.2.5/openvpn-2.4.5-aws-2.tar.gz) (thanks to @heprotecbuthealsoattac) for the link.

## How to use

1. Build patched openvpn version and put it to the folder with a script
2. Build aws-vpn-client wrapper `go build .`
3. `cp ./awsvpnclient.yml.example ./awsvpnclient.yml` and update the necsery paths.
4. Finally run `./aws-vpn-client serve --config myconfig.openvpn` to connect to the AWS.

## Todo

* Unit tests
* General Code Cleanup
* Better integrate SAML HTTP server with a script or rewrite everything on golang
