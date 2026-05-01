class BunAT1312 < Formula
  desc "Incredibly fast JavaScript runtime, bundler, and package manager"
  homepage "https://bun.sh/"
  url "https://registry.npmjs.org/bun/-/bun-1.3.12.tgz"
  sha256 "579cb7e77ae569377caa12ef071d0052c33ab179717258eb119c406982b43191"
  license "MIT"
  revision 2

  bottle do
    root_url "https://ghcr.io/v2/amrkmn/bun"
    sha256 cellar: :any_skip_relocation, arm64_linux:  "a8c0d5be6bc0cc553ae67cbf573373ce15b832d36cdb9690fe13affa32609d9c"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "1882203ae1db3a3279c4936d406592bfb6f543adafe45d4ed5be2b48a5a4904e"
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
