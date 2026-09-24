class BitgarthCli < Formula
  desc "Command-line client for a paired BitGarth server"
  homepage "https://bitgarth.app/"
  license "FSL-1.1-ALv2"

  if OS.mac?
    url "https://github.com/BitGarth/bitgarth/releases/download/v0.4.2/bitgarth-cli-v0.4.2-macos-aarch64.tar.gz"
    sha256 "ebb69e7ad882b1b611e6b2bd772b39f4124aee1d203f3f1efa98e5bce6235f88"
  else
    url "https://github.com/BitGarth/bitgarth/releases/download/v0.4.2/bitgarth-cli-v0.4.2-linux-x86_64-gnu.tar.gz"
    sha256 "8886e2f8e1db00d65a430e1e87e9d86746f83f97d9426461d5f4ddfc524e6433"
  end

  on_macos do
    depends_on arch: :arm64
  end

  on_linux do
    depends_on arch: :x86_64
  end

  resource "license" do
    url "https://raw.githubusercontent.com/BitGarth/bitgarth/v0.4.2/LICENSE.md"
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
