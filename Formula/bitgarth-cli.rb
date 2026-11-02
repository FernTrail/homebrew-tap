class BitgarthCli < Formula
  desc "Command-line client for a paired BitGarth server"
  homepage "https://bitgarth.app/"
  license "AGPL-3.0-only"

  if OS.mac?
    url "https://github.com/BitGarth/bitgarth/releases/download/v0.4.4/bitgarth-cli-v0.4.4-macos-aarch64.tar.gz"
    sha256 "6a5fd6acfb6a9f6b1718a313cb09d16c7fab2d92f47da87c0d3219dcad7e8746"
  else
    url "https://github.com/BitGarth/bitgarth/releases/download/v0.4.4/bitgarth-cli-v0.4.4-linux-x86_64-gnu.tar.gz"
    sha256 "59e94996d1c4c202f4cb75a291ad0b122bb35500c5560df912984c12f651fef4"
  end

  on_macos do
    depends_on arch: :arm64
  end

  on_linux do
    depends_on arch: :x86_64
  end

  resource "license" do
    url "https://raw.githubusercontent.com/BitGarth/bitgarth/v0.4.4/LICENSE.md"
    sha256 "0d96a4ff68ad6d4b6f1f30f713b18d5184912ba8dd389f86aa7710db079abcb0"
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
