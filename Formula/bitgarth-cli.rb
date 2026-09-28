class BitgarthCli < Formula
  desc "Command-line client for a paired BitGarth server"
  homepage "https://bitgarth.app/"
  license "FSL-1.1-ALv2"

  if OS.mac?
    url "https://github.com/BitGarth/bitgarth/releases/download/v0.4.3/bitgarth-cli-v0.4.3-macos-aarch64.tar.gz"
    sha256 "87f4172e9ffc035bdfe6bdfcd0bb7e1b7d6555a68d905bd0a0e11242563b4da6"
  else
    url "https://github.com/BitGarth/bitgarth/releases/download/v0.4.3/bitgarth-cli-v0.4.3-linux-x86_64-gnu.tar.gz"
    sha256 "fedbe9af8e075817a80463365fd3b898dc94f1c813d3e5ecb161e91316ad18b5"
  end

  on_macos do
    depends_on arch: :arm64
  end

  on_linux do
    depends_on arch: :x86_64
  end

  resource "license" do
    url "https://raw.githubusercontent.com/BitGarth/bitgarth/v0.4.3/LICENSE.md"
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
