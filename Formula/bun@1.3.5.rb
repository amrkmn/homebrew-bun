class BunAT135 < Formula
  desc "Incredibly fast JavaScript runtime, bundler, and package manager"
  homepage "https://bun.sh/"
  url "https://registry.npmjs.org/bun/-/bun-1.3.5.tgz"
  sha256 "af96f357e90847fcb252b69d542e7790cf1c9927f57a6a0162e9acffb7b5f7eb"
  license "MIT"
  revision 3

  bottle do
    root_url "https://ghcr.io/v2/amrkmn/bun"
    sha256 cellar: :any_skip_relocation, arm64_linux:  "0020f16ec51f2161e98f349858ca321a2c76f730b936728ec5d304a6642a2649"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "f6d425dc1dc2dee9b44aa6c2b8de484d769bedbe599a887133fc0d0b671ed2f0"
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
    assert_match "1.3.5", shell_output("#{bin}/bun --version")
  end
end
