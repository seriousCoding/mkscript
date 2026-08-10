class Mkscript < Formula
  desc "Create executable Bash script stubs with optional strict mode"
  homepage "https://github.com/seriousCoding/mkscript"
  url "https://github.com/seriousCoding/mkscript/releases/download/v1.1.0/mkscript-1.1.0.tar.gz"
  sha256 "7adfa5765969824b446212356f895f6a4dbce1d366e2f91f9f83abc701616436"
  license "MIT"

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    demo_pattern = %r{\A#!/usr/bin/env bash
# Script: demo
# Description:
# Created: \d{4}-\d{2}-\d{2}
# Creator: .+
\z}x
    strict_demo_pattern = %r{\A#!/usr/bin/env bash
# Script: strict-demo
# Description:
# Created: \d{4}-\d{2}-\d{2}
# Creator: .+
set -euo pipefail
\z}x

    system bin/"mkscript", "demo"
    assert_match(demo_pattern, (testpath/"demo").read)

    system bin/"mkscript", "-s", "strict-demo"
    assert_match(strict_demo_pattern, (testpath/"strict-demo").read)
  end
end
