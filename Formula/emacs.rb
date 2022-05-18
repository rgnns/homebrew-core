# coding: utf-8

class Emacs < Formula

  desc "GNU Emacs text editor for macOS"
  homepage "https://www.gnu.org/software/emacs/"
  revision 1

  url "https://github.com/emacs-mirror/emacs.git",
      :revision => "b1620a44ff201966c9900a116a640597093e6030"
  head "https://github.com/emacs-mirror/emacs.git"
  version "29.0.50"

  depends_on "autoconf" => :build
  depends_on "gnu-sed" => :build
  depends_on "pkg-config" => :build
  depends_on "texinfo" => :build

  depends_on "gnutls"
  depends_on "librsvg"
  depends_on "libxml2"
  depends_on "jansson"

  depends_on "imagemagick@7" => :recommended
  depends_on "harfbuzz" => :recommended

  resource "modern-icon-sexy-v2" do
    url "http://raw.githubusercontent.com/rgnns/homebrew-core/main/Assets/modern-icon-sexy-v2.icns"
    sha256 "ecdc902435a8852d47e2c682810146e81f5ad72ee3d0c373c936eb4c1e0966e6"
  end

  def install
    args = %W[
      --enable-locallisppath=#{HOMEBREW_PREFIX}/share/emacs/site-lisp
      --infodir=#{info}/emacs
      --prefix=#{prefix}
      --without-x
      --without-dbus
      --with-imagemagick
      --with-json
      --with-modules
      --with-gnutls
      --with-rsvg
      --with-xml2
      --with-harfbuzz
      --with-ns
      --disable-ns-self-contained
    ]
    imagemagick_lib_path = Formula["imagemagick@7"].opt_lib/"pkgconfig"
    ohai "ImageMagick PKG_CONFIG_PATH: ", imagemagick_lib_path
    ENV.prepend_path "PKG_CONFIG_PATH", imagemagick_lib_path

    ENV.prepend_path "PATH", Formula["gnu-sed"].opt_libexec/"gnubin"
    system "./autogen.sh"

    system "./configure", *args
    system "make"
    system "make", "install"

    icons_dir = buildpath/"nextstep/Emacs.app/Contents/Resources"

    rm "#{icons_dir}/Emacs.icns"
    resource("modern-icon-sexy-v2").stage do
      icons_dir.install Dir["*.icns*"].first => "Emacs.icns"
      ohai "Installing modern_icon_sexy_v2 icon."
    end

    prefix.install "nextstep/Emacs.app"
    (bin/"emacs").unlink
    (bin/"emacs").write <<~EOS
      #!/bin/bash
      exec #{prefix}/Emacs.app/Contents/MacOS/Emacs "$@"
    EOS
  end

  def caveats
    <<~EOS
      Emacs.app was installed to:
        #{prefix}
      To link the application:
        ln -s #{prefix}/Emacs.app /Applications
    EOS
  end

  plist_options :manual => "emacs"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>KeepAlive</key>
      <true/>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_bin}/emacs</string>
        <string>--daemon</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
    </dict>
    </plist>
  EOS
  end

  test do
    assert_equal "4", shell_output("#{bin}/emacs --batch --eval=\"(print (+ 2 2))\"").strip
  end
end
