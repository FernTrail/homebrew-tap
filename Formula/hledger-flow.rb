class HledgerFlow < Formula
  desc "Import bank statements and generate reports with hledger"
  homepage "https://github.com/apauley/hledger-flow"
  license "GPL-3.0-only"

  depends_on "hledger" => :recommended

  tag = "v0.20.1"
  release = "https://github.com/apauley/hledger-flow/releases/download/#{tag}"

  on_macos do
    on_arm do
      url "#{release}/hledger-flow-macos-arm64.tar.gz"
      sha256 "95036152955591c4e7b1e311cab52b8addf3f705eb1cb4a186fe9259d13f7906"

      depends_on macos: :tahoe
    end
    on_intel do
      url "#{release}/hledger-flow-macos-x64.tar.gz"
      sha256 "f199a0d745406c0d65d1cf6e6b0acb534b1b17fa2d5f35fd195fcbbc96965437"

      depends_on macos: :sequoia
    end
  end

  on_linux do
    on_arm do
      url "#{release}/hledger-flow-linux-arm64.tar.gz"
      sha256 "e1e0f9b2248e4d907b5872106f1e87670d5bb6c6f23ae91046fac6348dbe948c"
    end
    on_intel do
      url "#{release}/hledger-flow-linux-x64.tar.gz"
      sha256 "541cdee1528951f2860b5790b689f6ba713b4171ea35972182faca68c8c2ebad"
    end

    depends_on "patchelf" => :build
    depends_on "gmp"
  end

  resource "license" do
    url "https://raw.githubusercontent.com/apauley/hledger-flow/#{tag}/LICENSE"
    sha256 "3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986"
  end

  def install
    if OS.linux?
      odie "The Linux binary requires system glibc 2.34 or newer." if OS::Linux::Glibc.system_version < "2.34"

      system "patchelf", "--set-rpath", formula_opt_lib("gmp"), "hledger-flow"
    end
    bin.install "hledger-flow"
    resource("license").stage { prefix.install "LICENSE" }
  end

  test do
    account = testpath/"import/owner/bank/checking"
    (account/"1-in/2025").mkpath
    (account/"1-in/2025/statement.csv").write "2025-01-01,Bank fee,-5\n"
    (testpath/"import/bank.rules").write <<~RULES
      fields date, description, amount
      account1 assets:checking
      account2 expenses:fees
    RULES

    system bin/"hledger-flow", "import", testpath
    journal = (account/"3-journal/2025/statement.journal").read
    assert_match "Bank fee", journal
    assert_match "expenses:fees", journal
  end
end
