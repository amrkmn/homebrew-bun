class BunAT1310 < Formula
  desc "Incredibly fast JavaScript runtime, bundler, and package manager"
  homepage "https://bun.sh/"
  url "https://registry.npmjs.org/bun/-/bun-1.3.10.tgz"
  sha256 "17058cb121cdb8c3665a70ce3b666dabd29e855ff2bb9f48aac6fba016915237"
  license "MIT"
  revision 4

  bottle do
    root_url "https://ghcr.io/v2/amrkmn/bun"
    sha256 cellar: :any_skip_relocation, arm64_linux:  "23e6e1ce2058455da5e55bf92c27ac37eabae271ea8c5f8bbd38a7f6740982bb"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "411d5e61de9953f377dcbcf5270658dd1ab048f25d8ab4c3676150632202209f"
  end

  keg_only :versioned_formula

  depends_on "node" => :build

  def install
    # Install npm package, postinstall downloads platform-specific binaries
    system "npm", "install", *std_npm_args(ignore_scripts: false)

    # The postinstall script creates bin/bun.exe and bin/bunx.exe
    # Install them as bun and bunx (without .exe extension)
    bin.install libexec/"lib/node_modules/bun/bin/bun.exe" => "bun"
    bin.install libexec/"lib/node_modules/bun/bin/bunx.exe" => "bunx"

    # Clean up unused platform binaries to save space
    arch = Hardware::CPU.arm? ? "aarch64" : "x64"
    os = OS.linux? ? "linux" : "darwin"

    (libexec/"lib/node_modules/bun/node_modules/@oven").children.each do |d|
      next unless d.directory?

      rm_r d if d.basename.to_s != "bun-#{os}-#{arch}"
    end
  end

  test do
    system bin/"bun", "--version"
    assert_match version.to_s, shell_output("#{bin}/bun --version")
  end
end
