#!/bin/bash

OVPN_CONF="profile_rendered.ovpn"
sed -E 's/auth-user-pass|auth-federate|auth-retry interact|remote-random-hostname//g' profile.ovpn > "$OVPN_CONF"

VPN_HOST=$(cat "$OVPN_CONF" | grep 'remote ' | awk '{ print $2}')
PORT=443

RAND=$(openssl rand -hex 12)
SRV=$(dig a +short "${RAND}.${VPN_HOST}" | head -n1)

sed -i -E 's/remote .*//g' "$OVPN_CONF"

echo "Getting SAML redirect URL from the AUTH_FAILED response (host: ${SRV}:${PORT})"
OVPN_OUT=$(./openvpn-bin --config "$OVPN_CONF" --verb 3 \
     --proto udp --remote "$SRV" "$PORT" \
     --auth-user-pass <( printf "%s\n%s\n" "N/A" "ACS::35001" ) | grep AUTH_FAILED,CRV1)

URL=$(echo "$OVPN_OUT" | grep -Eo 'https://.+')

echo
echo
echo "Open the url in browser:"
echo
echo "$URL"
echo
echo

./go_server

# get SID from the reply
VPN_SID=$(echo "$OVPN_OUT" | awk -F : '{print $7}')

# Finally OpenVPN with a SAML response we got
# Delete saml-response.txt after connect
./openvpn-bin --config "$OVPN_CONF" \
    --verb 3 --auth-nocache --inactive 3600 \
    --proto udp --remote "$SRV" "$PORT" \
    --script-security 2 \
    --route-up '/usr/bin/env rm /tmp/saml-response.txt' \
    --auth-user-pass <( printf "%s\n%s\n" "N/A" "CRV1::$VPN_SID::$(cat /tmp/saml-response.txt)" )
