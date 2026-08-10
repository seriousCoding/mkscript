class Mkscript < Formula
  desc "Create executable Bash script stubs with optional strict mode"
  homepage "https://github.com/seriousCoding/mkscript"
  url "https://github.com/seriousCoding/mkscript/releases/download/v1.1.0/mkscript-1.1.0.tar.gz"
  sha256 "847de36278b501fec62a5bd8727be060bb8707268ec8e76e99f3f8cfffb8a5a2"
  license "MIT"

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    system bin/"mkscript", "demo"
    assert_equal "#!/usr/bin/env bash\n", (testpath/"demo").read

    system bin/"mkscript", "-s", "strict-demo"
    assert_equal "#!/usr/bin/env bash\nset -euo pipefail\n", (testpath/"strict-demo").read
  end
end
