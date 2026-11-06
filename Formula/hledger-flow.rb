class HledgerFlow < Formula
  desc "Import bank statements and generate reports with hledger"
  homepage "https://github.com/apauley/hledger-flow"
  license "GPL-3.0-only"

  depends_on "hledger" => :recommended

  tag = "v0.18.0"
  release = "https://github.com/apauley/hledger-flow/releases/download/#{tag}"

  on_macos do
    on_arm do
      url "#{release}/hledger-flow-macos-arm64.tar.gz"
      sha256 "4b555cc7e1739f56001bb483bc1e060ae5ddab917e6212aa85d5710722101d02"

      depends_on macos: :tahoe
    end
    on_intel do
      url "#{release}/hledger-flow-macos-x64.tar.gz"
      sha256 "87f116de9590d8c59a0776b72f7211e67e4b167b53ecfac9e584df6b2f73ccab"

      depends_on macos: :sequoia
    end
  end

  on_linux do
    on_arm do
      url "#{release}/hledger-flow-linux-arm64.tar.gz"
      sha256 "9a9e65b508ea4795c2a0b73ccf59ea81919606b6c54b8a259c3409f4ef653686"
    end
    on_intel do
      url "#{release}/hledger-flow-linux-x64.tar.gz"
      sha256 "bc7317bc8afe74cab4601724411bf74ba6d8688bfcb0fc86e0d754baa5a3fb2d"
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
