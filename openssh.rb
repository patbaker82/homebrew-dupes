require 'formula'

class Openssh < Formula
  homepage 'http://www.openssh.com/'
  url 'http://ftp5.usa.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-6.4p1.tar.gz'
  version '6.4p1.1'
  sha1 'cf5fe0eb118d7e4f9296fbc5d6884965885fc55d'

  option 'with-brewed-openssl', 'Build with Homebrew OpenSSL instead of the system version'
  option 'with-keychain-support', 'Add native OS X Keychain and Launch Daemon support to ssh-agent'

  depends_on 'openssl' if build.with? 'brewed-openssl'
  depends_on 'ldns' => :optional
  depends_on 'pkg-config' => :build if build.with? "ldns"

  def patches
    p = []
    # KeyChain support for OSX
    p << 'https://gist.github.com/patbaker82/8486469/raw/3e6d15bb8f7aa0c24c28733e5cfbfedaec4a8a69/openssh-6.4p1.patch' if build.with? 'keychain-support'
    p
  end

  def install
    if build.include? "with-keychain-support"
        ENV.append "CPPFLAGS", "-D__APPLE_LAUNCHD__ -D__APPLE_KEYCHAIN__"
        ENV.append "LDFLAGS", "-framework CoreFoundation -framework SecurityFoundation -framework Security"
    end

    args = %W[
      --with-libedit
      --with-kerberos5
      --prefix=#{prefix}
      --sysconfdir=#{etc}/ssh
    ]

    args << "--with-ssl-dir=#{Formula.factory('openssl').opt_prefix}" if build.with? 'brewed-openssl'
    args << "--with-ldns" if build.with? "ldns"

    # Sometimes when Apple ships security update, the libraries get
    # updated while the headers don't. Disable header/library version
    # check when using system openssl to cope with this situation.
    args << "--without-openssl-header-check" if not build.with? 'brewed-openssl'

    system "./configure", *args
    system "make"
    system "make install"
  end

  def caveats
    if build.include? "with-keychain-support"
      <<-EOS.undent
        For complete functionality, please modify:
          /System/Library/LaunchAgents/org.openbsd.ssh-agent.plist

        and change ProgramArugments from
          /usr/bin/ssh-agent
        to
          #{HOMEBREW_PREFIX}/bin/ssh-agent

        After that, you can start storing private key passwords in
        your OS X Keychain.
      EOS
    end
  end
end