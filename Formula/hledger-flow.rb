class HledgerFlow < Formula
  desc "Import bank statements and generate reports with hledger"
  homepage "https://github.com/apauley/hledger-flow"
  license "GPL-3.0-only"

  depends_on "hledger" => :recommended

  tag = "v0.17.0"
  release = "https://github.com/apauley/hledger-flow/releases/download/#{tag}"

  on_macos do
    on_arm do
      url "#{release}/hledger-flow-macos-arm64.tar.gz"
      sha256 "5c64a6a378759f8f208013198991a2b60170e3ae485b56f81ced9769f97a5578"

      depends_on macos: :tahoe
    end
    on_intel do
      url "#{release}/hledger-flow-macos-x64.tar.gz"
      sha256 "3132bcbd8e346dc3f95583c960a9015e54804ef7bdefa8f6880768229059b176"

      depends_on macos: :sequoia
    end
  end

  on_linux do
    on_arm do
      url "#{release}/hledger-flow-linux-arm64.tar.gz"
      sha256 "01349ed66bf4564ce50327ac5aec168e788476d71a0bb554a327532ab2630e53"
    end
    on_intel do
      url "#{release}/hledger-flow-linux-x64.tar.gz"
      sha256 "45da95a03261192717de1889f9073ddc7f1bb3845a1eb9fa492cb05e0fc1261e"
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
