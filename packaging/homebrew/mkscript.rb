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
    system bin/"mkscript", "demo"
    assert_match(/\A#!\/usr\/bin\/env bash\n# Script: demo\n# Description:\n# Created: \d{4}-\d{2}-\d{2}\n# Creator: .+\n\z/, (testpath/"demo").read)

    system bin/"mkscript", "-s", "strict-demo"
    assert_match(/\A#!\/usr\/bin\/env bash\n# Script: strict-demo\n# Description:\n# Created: \d{4}-\d{2}-\d{2}\n# Creator: .+\nset -euo pipefail\n\z/, (testpath/"strict-demo").read)
  end
end
