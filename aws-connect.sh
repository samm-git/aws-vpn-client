#!/usr/bin/env bash

set -e

print_help() {
    cat << EOF
Usage: aws-connect [options]

OPTIONS
  -h, --host                     AWS VPN Endpoint host
  -p, --port                     AWS VPN Endpoint port
  -c, --config-path              OpenVPN config path
  -b, --openvpn-binary-path      OpenVPN patched binary path
EOF
}

if [[ $# -eq 0 ]]; then
    echo "Please supply arguments."
    print_help
    exit
fi

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    arg="$1"

    case $arg in
        -h|--host)
            VPN_HOST="$2"
            shift # past argument
            shift # past value
            ;;
        -p|--port)
            PORT="$2"
            shift
            shift
            ;;
        -c|--config-path)
            OVPN_CONF="$2"
            shift
            shift
            ;;
        -b|--openvpn-binary-path)
            OVPN_BIN="$2"
            shift
            shift
            ;;
        *) # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift
            ;;
    esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

OPTIONS=("$VPN_HOST" "$PORT" "$OVPN_CONF" "$OVPN_BIN")

for arg_value in "${OPTIONS[@]}"; do
    if test -z "${arg_value}"; then
        print_help
        exit
    fi
done

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

# start the saml response server and background it
go run server.go >> /tmp/aws-connect-saml-server.log 2>&1 &

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
# Delete saml-response.txt after connect
sudo bash -c "$OVPN_BIN --config "${OVPN_CONF}" \
    --verb 3 --auth-nocache --inactive 3600 \
    --proto "$PROTO" --remote $SRV $PORT \
    --script-security 2 \
    --route-up '/usr/bin/env rm saml-response.txt' \
    --auth-user-pass <( printf \"%s\n%s\n\" \"N/A\" \"CRV1::${VPN_SID}::$(cat saml-response.txt)\" )"
