class BitgarthCli < Formula
  desc "Command-line client for a paired BitGarth server"
  homepage "https://bitgarth.app/"
  license "AGPL-3.0-only"

  if OS.mac?
    url "https://github.com/BitGarth/bitgarth/releases/download/v0.5.0/bitgarth-cli-v0.5.0-macos-aarch64.tar.gz"
    sha256 "db61893b4bd136dd6a5f63bf32c37e39131947531e5d09fe65e2b20faa9c68f5"
  else
    url "https://github.com/BitGarth/bitgarth/releases/download/v0.5.0/bitgarth-cli-v0.5.0-linux-x86_64-gnu.tar.gz"
    sha256 "d8097feb9ba318844a61fe15c87d91cf043a8d1458792e183d45a83152550bf4"
  end

  on_macos do
    depends_on arch: :arm64
  end

  on_linux do
    depends_on arch: :x86_64
  end

  resource "license" do
    url "https://raw.githubusercontent.com/BitGarth/bitgarth/v0.5.0/LICENSE.md"
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
        bitgarth auth login https://your-bitgarth.example.com/
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bitgarth --version")
    assert_match "bitgarth auth login", shell_output("#{bin}/bitgarth auth login --help")
  end
end
