# aws-vpn-client

This is PoC to connect to the AWS Client VPN with OSS OpenVPN using SAML
authentication.

## Content of the repository

- [openvpn-master.diff](openvpn-master.diff) - patch required to build AWS compatible OpenVPN
- [server.go](server.go) - Go server to listed on http://127.0.0.1:35001 and save
SAML Post data to the file
- [aws-connect.sh] - bash wrapper to run OpenVPN. It runs OpenVPN first time to get SAML Redirect and open browser and second time with actual SAML response

## How to use

TODO
