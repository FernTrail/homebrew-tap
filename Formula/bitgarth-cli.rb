class BitgarthCli < Formula
  desc "Command-line client for a paired BitGarth server"
  homepage "https://bitgarth.app/"
  license "FSL-1.1-ALv2"

  if OS.mac?
    url "https://github.com/BitGarth/bitgarth/releases/download/v0.4.0/bitgarth-cli-v0.4.0-macos-aarch64.tar.gz"
    sha256 "eff29c0e1431abc32c277c64ab19269b32807eee8c35ce0cc87263fb1a4154ec"
  else
    url "https://github.com/BitGarth/bitgarth/releases/download/v0.4.0/bitgarth-cli-v0.4.0-linux-x86_64-gnu.tar.gz"
    sha256 "9650e6e870cdb098b8e2264e0ac2e59b6f9606a6df591c0c01278d08a13ebf38"
  end

  on_macos do
    depends_on arch: :arm64
    depends_on macos: :big_sur
  end

  on_linux do
    depends_on arch: :x86_64
  end

  resource "license" do
    url "https://raw.githubusercontent.com/BitGarth/bitgarth/v0.4.0/LICENSE.md"
    sha256 "161272734def5be60c44b744fe5a57f27cc1743a87c707042a3d83184d847a39"
  end

  def install
    if OS.linux? && OS::Linux::Glibc.system_version < "2.39"
      odie "The prebuilt Linux binary requires system glibc 2.39 or newer."
    end

    libexec.install "bitgarth"
    (bin/"bitgarth").write_env_script libexec/"bitgarth", BITGARTH_CHANNEL: "homebrew"
    resource("license").stage { prefix.install "LICENSE.md" }
  end

  def caveats
    <<~EOS
      This package installs the client only. It pairs with an existing BitGarth
      server on this computer or another machine.

      You can install a server using Homebrew (bitgarth-web), Umbrel, Docker,
      or other methods listed at https://bitgarth.app/#install

      Pair with your BitGarth server:
        bitgarth pair https://your-bitgarth.example.com/
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bitgarth --version")
    assert_match "pair", shell_output("#{bin}/bitgarth --help")
  end
end
