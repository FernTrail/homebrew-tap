class HledgerFlow < Formula
  desc "Import bank statements and generate reports with hledger"
  homepage "https://github.com/apauley/hledger-flow"
  license "GPL-3.0-only"

  depends_on "hledger" => :recommended

  tag = "v0.20.0"
  release = "https://github.com/apauley/hledger-flow/releases/download/#{tag}"

  on_macos do
    on_arm do
      url "#{release}/hledger-flow-macos-arm64.tar.gz"
      sha256 "fda2bb8e44d7f34d44e719546f5f76d43a5e4ad27fb70a6cfcc6e6ead3412d49"

      depends_on macos: :tahoe
    end
    on_intel do
      url "#{release}/hledger-flow-macos-x64.tar.gz"
      sha256 "7617ff4b5a8a7f91676fea1045f614f7e412c2f1ffd529430da14230933fed65"

      depends_on macos: :sequoia
    end
  end

  on_linux do
    on_arm do
      url "#{release}/hledger-flow-linux-arm64.tar.gz"
      sha256 "27b7f77f05f4aa19038fa483625abda35be84d732e8bbe9ea5e23d40e330dca5"
    end
    on_intel do
      url "#{release}/hledger-flow-linux-x64.tar.gz"
      sha256 "245f706abb2053632004c900bfa982ba1000ef6f0eea2b7be22cc2a60be7c452"
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
