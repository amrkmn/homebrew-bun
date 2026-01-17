class Bun < Formula
  desc "Incredibly fast JavaScript runtime, bundler, and package manager"
  homepage "https://bun.sh/"
  url "https://registry.npmjs.org/bun/-/bun-1.3.6.tgz"
  sha256 "f795359a2fc367c5972c19045c60e8d4e4746848a8c24f07a93b5e626bf970ac"
  license "MIT"

  bottle do
    root_url "https://ghcr.io/v2/amrkmn/bun"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "80f658268aa57159bd2edb2a0a06ede3d3f54517c16a9cdd3d654cab791a92e3"
  end

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
