class HledgerFlow < Formula
  desc "Import bank statements and generate reports with hledger"
  homepage "https://github.com/apauley/hledger-flow"
  license "GPL-3.0-only"

  depends_on "hledger" => :recommended

  tag = "v0.19.0"
  release = "https://github.com/apauley/hledger-flow/releases/download/#{tag}"

  on_macos do
    on_arm do
      url "#{release}/hledger-flow-macos-arm64.tar.gz"
      sha256 "ed0d3c3af9eb4651859af126427981feabe2eeb8988055ef0c95a2209095ccd8"

      depends_on macos: :tahoe
    end
    on_intel do
      url "#{release}/hledger-flow-macos-x64.tar.gz"
      sha256 "28f235c09a9e7a7a17bd2270eedcb23044fc6e00f6f417d21b2f1f008b56d655"

      depends_on macos: :sequoia
    end
  end

  on_linux do
    on_arm do
      url "#{release}/hledger-flow-linux-arm64.tar.gz"
      sha256 "2cafcd6459d10154e3d1120b5650ea86e0e01ee32bdbc41a798a96fa562a484a"
    end
    on_intel do
      url "#{release}/hledger-flow-linux-x64.tar.gz"
      sha256 "3db7afd1bc71641a4b2e38365a76e3a8e6879fa0da48616d4ec91e28fcc884e3"
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
