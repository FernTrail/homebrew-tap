class BitgarthWeb < Formula
  desc "Self-hosted BitGarth portfolio tracker with a browser interface"
  homepage "https://bitgarth.app/"
  license "FSL-1.1-ALv2"

  if OS.mac?
    url "https://github.com/BitGarth/bitgarth/releases/download/v0.4.2/bitgarth-web-v0.4.2-macos-aarch64.tar.gz"
    sha256 "ac498f4b1972af545adc0f877650e6879aee7e8edabd124ae8e75057dda7161d"
  else
    url "https://github.com/BitGarth/bitgarth/releases/download/v0.4.2/bitgarth-web-v0.4.2-linux-x86_64-gnu.tar.gz"
    sha256 "d11de30b5942b986f98a5460bc794e3602752ae40ba6fd44c55ff8086ced3b5f"
  end

  on_macos do
    depends_on arch: :arm64
  end

  on_linux do
    depends_on arch: :x86_64
    depends_on "openssl@3"
  end

  resource "license" do
    url "https://raw.githubusercontent.com/BitGarth/bitgarth/v0.4.2/LICENSE.md"
    sha256 "161272734def5be60c44b744fe5a57f27cc1743a87c707042a3d83184d847a39"
  end

  def install
    if OS.linux? && OS::Linux::Glibc.system_version < "2.39"
      odie "The prebuilt Linux binary requires system glibc 2.39 or newer."
    end

    libexec.install "bitgarth-web", "public", "assets"
    resource("license").stage { prefix.install "LICENSE.md" }
    linux_env = if OS.linux?
      "export LD_LIBRARY_PATH=\"#{formula_opt_lib("openssl@3")}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\""
    end
    (bin/"bitgarth-web").write <<~SH
      #!/bin/sh
      export BITGARTH_CHANNEL=homebrew
      export BITGARTH_PROJECT_DIR="${BITGARTH_PROJECT_DIR-#{var}/bitgarth}"
      export IP="${IP-127.0.0.1}"
      #{linux_env}
      umask 077
      cd "#{libexec}" || exit 1
      exec "#{libexec}/bitgarth-web" "$@"
    SH
    (bin/"bitgarth-web").chmod 0555
  end

  def caveats
    <<~EOS
      Open http://127.0.0.1:8080 after starting the server.
      Data is stored in #{var}/bitgarth and is preserved across upgrades.
      BITGARTH_PROJECT_DIR (absolute path), IP and PORT can override the defaults
      when running bitgarth-web directly.

      By default, the server listens on localhost and is only accessible from
      this computer. To listen on all IPv4 network interfaces, run:
        IP=0.0.0.0 bitgarth-web
      Other devices can then connect to http://<server-ip>:8080, subject to
      your firewall rules.

      Stop the server and back up the entire data directory before upgrading.
      Homebrew services do not automatically inherit your shell's environment.
      See https://github.com/FernTrail/homebrew-tap#server-configuration for
      background-service configuration and access from another computer.
    EOS
  end

  service do
    run [opt_bin/"bitgarth-web"]
    keep_alive true
    log_path var/"log/bitgarth-web.log"
    error_log_path var/"log/bitgarth-web.log"
  end

  test do
    port = free_port
    data = testpath/"data with spaces"
    pid = fork do
      ENV["BITGARTH_CHANNEL"] = "docker"
      ENV["BITGARTH_PROJECT_DIR"] = data.to_s
      ENV["PORT"] = port.to_s
      ENV["RUST_LOG"] = "warn"
      ENV.delete("IP")
      exec bin/"bitgarth-web"
    end
    begin
      require "net/http"
      http = Net::HTTP.new("127.0.0.1", port, nil)
      http.open_timeout = 1
      http.read_timeout = 2
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30
      loop do
        begin
          break if http.get("/health").code == "200"
        rescue SystemCallError, IOError, Timeout::Error
          # The server may still be starting.
        end
        assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC), :<, deadline, "Server failed to start"
        sleep 0.2
      end
      assert_match "<script", http.get("/").body
      wasm = Dir[libexec/"public/**/*.wasm"].first
      assert wasm, "Missing browser WASM"
      path = Pathname(wasm).relative_path_from(libexec/"public")
      response = http.get("/#{path}")
      assert_equal "200", response.code
      assert_equal Digest::SHA256.file(wasm).hexdigest, Digest::SHA256.hexdigest(response.body)
      assert_path_exists data/"app/data"
      environment = shell_output("ps eww -p #{pid}")
      assert_equal "homebrew", environment[/\bBITGARTH_CHANNEL=(\S+)/, 1]
      assert_equal "127.0.0.1", environment[/\bIP=(\S+)/, 1]
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
