#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  printf 'Usage: %s URL SHA256 OUTPUT\n' "$(basename "$0")" >&2
  exit 64
fi

url=$1
sha256=$2
output=$3

mkdir -p "$(dirname "$output")"

cat > "$output" <<EOF
class Mkscript < Formula
  desc "Create executable Bash script stubs with optional strict mode"
  homepage "https://github.com/seriousCoding/mkscript"
  url "$url"
  sha256 "$sha256"
  license "MIT"

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    system bin/"mkscript", "demo"
    assert_equal "#!/usr/bin/env bash\\n", (testpath/"demo").read

    system bin/"mkscript", "-s", "strict-demo"
    assert_equal "#!/usr/bin/env bash\\nset -euo pipefail\\n", (testpath/"strict-demo").read
  end
end
EOF

printf 'Rendered Homebrew formula: %s\n' "$output"
