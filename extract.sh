#!/usr/bin/env bash

# Set the version variable to the openvpn version you want to extract paches from
# and run this script in an empty directory.

set -eu

version=2.6.12

mkdir "patches"
curl -Of "https://amazon-source-code-downloads.s3.amazonaws.com/aws/clientvpn/openvpn-${version}-aws-1.tar.gz"
mkdir "openvpn-$version-aws-1"
tar xvzf "openvpn-$version-aws-1.tar.gz" -C "openvpn-$version-aws-1"
git clone --depth 1 -b "v$version" "https://github.com/OpenVPN/openvpn" "openvpn-${version}"
openssl_version="$( (source "openvpn-$version-aws-1/openssl/VERSION.dat" && echo "$MAJOR.$MINOR.$PATCH" ) )"
for openssl_patch in "openvpn-$version-aws-1/openvpn/openssl-patches/"*; do
	cp "$openssl_patch" "patches/openssl-v${openssl_version}-aws-$(basename "$openssl_patch")"
done
pushd "openvpn-$version"
cp -r "../openvpn-$version-aws-1/openvpn/src" ./
git diff --output="../patches/openvpn-v$version-aws.patch"
popd
echo "Patches extracted to patches/"
