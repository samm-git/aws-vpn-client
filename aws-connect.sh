#!/usr/bin/env bash

set -e

# replace with your hostname
VPN_HOST="cvpn-endpoint-<id>.prod.clientvpn.us-east-1.amazonaws.com"
# path to the patched openvpn
OVPN_BIN="./openvpn"
# path to the configuration file
OVPN_CONF="vpn.conf"
PORT=1194
PROTO=udp

wait_file() {
  local file="$1"; shift
  local wait_seconds="${1:-10}"; shift # 10 seconds as default timeout
  until test $((wait_seconds--)) -eq 0 -o -f "$file" ; do sleep 1; done
  ((++wait_seconds))
}

# create random hostname prefix for the vpn gw
RAND=$(openssl rand -hex 12)

# resolv manually hostname to IP, as we have to keep persistent ip address
SRV=$(dig a +short "${RAND}.${VPN_HOST}"|head -n1)

# cleanup
rm -f saml-response.txt

echo "Getting SAML redirect URL from the AUTH_FAILED response (host: ${SRV}:${PORT})"
OVPN_OUT=$($OVPN_BIN --config "${OVPN_CONF}" --verb 3 \
     --proto "$PROTO" --remote "${SRV}" "${PORT}" \
     --auth-user-pass <( printf "%s\n%s\n" "N/A" "ACS::35001" ) \
    2>&1 | grep AUTH_FAILED,CRV1)

echo "Opening browser and wait for the response file..."
URL=$(echo "$OVPN_OUT" | grep -Eo 'https://.+')

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     xdg-open "$URL";;
    Darwin*)    open "$URL";;
    *)          echo "Could not determine 'open' command for this OS"; exit 1;;
esac

wait_file "saml-response.txt" 30 || {
  echo "SAML Authentication time out"
  exit 1
}

# get SID from the reply
VPN_SID=$(echo "$OVPN_OUT" | awk -F : '{print $7}')

echo "Running OpenVPN with sudo. Enter password if requested"

# Finally OpenVPN with a SAML response we got
sudo bash -c "$OVPN_BIN --config "${OVPN_CONF}" \
    --verb 3 --auth-nocache --inactive 3600 \
    --proto "$PROTO" --remote $SRV $PORT \
    --script-security 2 \
    --route-up 'route-up.sh' \
    --auth-user-pass <( printf \"%s\n%s\n\" \"N/A\" \"CRV1::${VPN_SID}::$(cat saml-response.txt)\" )"
