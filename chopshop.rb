require "formula"

class Chopshop < Formula
  version "4.2"
  homepage "https://github.com/MITRECND/chopshop"
  url "https://github.com/MITRECND/chopshop/archive/RELEASE_4.2.tar.gz"
  sha1 "f2dc554e8134380ac869a63dac73683475ac97a4"
  head "https://github.com/MITRECND/chopshop.git", :branch => "devel"

  depends_on :python if MacOS.version <= :snow_leopard
  depends_on "yara"
  depends_on "swig" => :build
  depends_on "libtool" => :build
  depends_on "libpcap" => :build
  depends_on "cmake" => :build
  depends_on "autoconf" => :build
  depends_on "automake" => :build

  resource "yara-python" do
    url "https://github.com/plusvic/yara/archive/v3.0.0.tar.gz"
    sha1 "43e7e0df03043cab1ab8299ef7ebee4d2c5d39dc"
  end

  resource "pynids" do
    url "https://github.com/MITRECND/pynids/archive/0.6.2.tar.gz"
    sha1 "425296c63325b80162bd65a48c13cff0642eb764"
  end

  resource "htpy" do
    url "https://github.com/MITRECND/htpy/archive/RELEASE_0.19.tar.gz"
    sha1 "934560ba144ba786d1a5b812d235389f175790fd"
  end

  resource "yaraprocessor" do
    url "https://github.com/MITRECND/yaraprocessor/archive/master.zip"
    sha1 "f6723c9b9d1f701eb3266388a48dbdd65733e89d"
  end

  resource "libemu" do
    url "http://downloads.sourceforge.net/project/nepenthes/libemu%20development/0.1.0/libemu-0.1.0.tar.gz"
    sha1 "159fd61b38eb93436f43b684102a365473e1f4e4"
  end

  resource "pylibemu" do
    url "https://github.com/buffer/pylibemu/archive/v0.2.5.tar.gz"
    sha1 "4e23a55afab32fe7b5765b57ba9e9b45e2579ed1"
  end

  resource "pymongo" do
    url "https://github.com/mongodb/mongo-python-driver/archive/2.7.2.tar.gz"
    sha1 "b6e3711bca26e677cfa848354650955d4d2cc1a8"
  end

  resource "M2Crypto" do
    url "https://github.com/martinpaljak/M2Crypto/archive/v0.22.3.tar.gz"
    sha1 "b64a2314aa897af55e43f2ca8099185af56d937d"
  end

  resource "pycrypto" do
    url "https://github.com/dlitz/pycrypto/archive/v2.6.1.tar.gz"
    sha1 "9b7fb7fd9c59624f2db7c1d98f62adde1b85f4c5"
  end

  resource "dnslib" do
    url "https://bitbucket.org/paulc/dnslib/get/240a188d070b.zip"
    sha1 "b70cc2078a07b9c37bc26628a0e1e6a648cf2062"
  end

  def install
    ENV["PYTHONPATH"] = lib+"python2.7/site-packages"
    ENV.prepend_create_path "PYTHONPATH", libexec+"lib/python2.7/site-packages"

    resource("libemu").stage do
      ENV.append 'CFLAGS', '-std=gnu89' if ENV.compiler == :clang
      system "autoreconf -v -i"
      system "./configure", "--enable-python-bindings",
                            "--disable-debug", "--disable-dependency-tracking",
                            "--prefix=#{opt_prefix}"
      system "make install"
      # echo "/opt/libemu/lib/" >> /etc/ld.so.conf.d/libemu.conf
      system "ldconfig"
    end

    res = %w(pylibemu pynids htpy yaraprocessor pymongo M2Crypto pycrypto dnslib)

    res.each do |r|
      resource(r).stage do
        ohai "Installing " + r + " ..."
        system "python", "setup.py", "build"
        system "python", "setup.py", "install", "--prefix=#{libexec}"
      end
    end

    resource("yara-python").stage do
      cd ("yara-python") do
        system "python", "setup.py", "build"
        system "python", "setup.py", "install", "--prefix=#{libexec}"
      end
    end

    ohai "Installing ChopShop..."
    ENV["PREFIX"] = prefix
    system "make"
    system "make install"

    bin.env_script_all_files(libexec+"chopshop", :PYTHONPATH => ENV["PYTHONPATH"])
  end

  test do
    system "#{bin}/chopshop", "--version"
  end
end
