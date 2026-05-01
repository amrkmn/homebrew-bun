class BunAT138 < Formula
  desc "Incredibly fast JavaScript runtime, bundler, and package manager"
  homepage "https://bun.sh/"
  url "https://registry.npmjs.org/bun/-/bun-1.3.8.tgz"
  sha256 "75d8ebd230aae5619ad07c3fb25bfc5e3bb7e92dbaa1f8de5b34e3fefca6be1d"
  license "MIT"
  revision 2

  bottle do
    root_url "https://ghcr.io/v2/amrkmn/bun"
    sha256 cellar: :any_skip_relocation, arm64_linux:  "2c9f525967eeb046586d3a05705aec19fce1a3c27d00d2d7d2565e53edb43df9"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "e95d559fa6c7886d2ee699be197345c0a977ba6e5d67cdaeacbd3a21299846ae"
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
