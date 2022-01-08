class OpenvpnAws < Formula
  desc "SSL/TLS VPN implementing OSI layer 2 or 3 secure network extension"
  homepage "https://openvpn.net/community/"
  url "https://swupdate.openvpn.org/community/releases/openvpn-2.5.1.tar.xz"
  mirror "https://build.openvpn.net/downloads/releases/openvpn-2.5.1.tar.xz"
  sha256 "40930489c837c05f6153f38e1ebaec244431ef1a034e4846ff732d71d59ff194"
  license "GPL-2.0-only" => { with: "openvpn-openssl-exception" }

  livecheck do
    url "https://openvpn.net/community-downloads/"
    regex(/href=.*?openvpn[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

patch do
  url "https://raw.githubusercontent.com/samm-git/aws-vpn-client/master/openvpn-v2.5.1-aws.patch"
  sha256 "21834d6dcc6e1ebc79426db9754a7f3f179d9eaa2ff04f27f5041d8a1dc23c1a"
end

  depends_on "pkg-config" => :build
  depends_on "lz4"
  depends_on "lzo"

  depends_on "openssl@1.1"
  depends_on "pkcs11-helper"

  on_linux do
    depends_on "linux-pam"
    depends_on "net-tools"
  end

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--with-crypto-library=openssl",
                          "--enable-pkcs11",
                          "--prefix=#{prefix}"
    inreplace "sample/sample-plugins/Makefile" do |s|
      s.gsub! HOMEBREW_LIBRARY/"Homebrew/shims/mac/super/pkg-config",
              Formula["pkg-config"].opt_bin/"pkg-config"
      s.gsub! HOMEBREW_LIBRARY/"Homebrew/shims/mac/super/sed",
              "/usr/bin/sed"
    end
    system "make", "install"

    inreplace "sample/sample-config-files/openvpn-startup.sh",
              "/etc/openvpn", "#{etc}/openvpn"

    (doc/"samples").install Dir["sample/sample-*"]
    (etc/"openvpn").install doc/"samples/sample-config-files/client.conf"
    (etc/"openvpn").install doc/"samples/sample-config-files/server.conf"

    # We don't use mbedtls, so this file is unnecessary & somewhat confusing.
    rm doc/"README.mbedtls"
  end

  def post_install
    (var/"run/openvpn").mkpath
  end

  plist_options startup: true

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd";>
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_sbin}/openvpn</string>
          <string>--config</string>
          <string>#{etc}/openvpn/openvpn.conf</string>
        </array>
        <key>OnDemand</key>
        <false/>
        <key>RunAtLoad</key>
        <true/>
        <key>TimeOut</key>
        <integer>90</integer>
        <key>WatchPaths</key>
        <array>
          <string>#{etc}/openvpn</string>
        </array>
        <key>WorkingDirectory</key>
        <string>#{etc}/openvpn</string>
      </dict>
      </plist>
    EOS
  end

  test do
    system sbin/"openvpn", "--show-ciphers"
  end
end
