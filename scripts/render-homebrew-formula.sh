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
  desc "Create Bash, Terraform, and Ansible starter files safely"
  homepage "https://github.com/seriousCoding/mkscript"
  url "$url"
  sha256 "$sha256"
  license "MIT"

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    system bin/"mkscript", "demo"
    demo_lines = (testpath/"demo").read.lines
    assert_equal "#!/usr/bin/env bash\\n", demo_lines[0]
    assert_equal "# Script: demo\\n", demo_lines[1]
    assert_equal "# Description:\\n", demo_lines[2]
    assert_match(/^# Created: \\d{4}-\\d{2}-\\d{2}\\n$/, demo_lines[3])
    assert_match(/^# Creator: .+\\n$/, demo_lines[4])
    assert_equal 5, demo_lines.length

    system bin/"mkscript", "-s", "strict-demo"
    strict_demo_lines = (testpath/"strict-demo").read.lines
    assert_equal "#!/usr/bin/env bash\\n", strict_demo_lines[0]
    assert_equal "# Script: strict-demo\\n", strict_demo_lines[1]
    assert_equal "# Description:\\n", strict_demo_lines[2]
    assert_match(/^# Created: \\d{4}-\\d{2}-\\d{2}\\n$/, strict_demo_lines[3])
    assert_match(/^# Creator: .+\\n$/, strict_demo_lines[4])
    assert_equal "set -euo pipefail\\n", strict_demo_lines[5]
    assert_equal 6, strict_demo_lines.length

    system bin/"mkscript", "--template", "terraform", "main.tf"
    terraform_lines = (testpath/"main.tf").read.lines
    assert_equal "# File: main.tf\\n", terraform_lines[0]
    assert_equal "# Description:\\n", terraform_lines[1]
    assert_match(/^# Created: \\d{4}-\\d{2}-\\d{2}\\n$/, terraform_lines[2])
    assert_match(/^# Creator: .+\\n$/, terraform_lines[3])
    assert_equal "\\n", terraform_lines[4]
    assert_equal "terraform {\\n", terraform_lines[5]
    assert_equal "  required_version = \\">= 1.0.0\\"\\n", terraform_lines[6]
    assert_equal "}\\n", terraform_lines[7]

    system bin/"mkscript", "site.yml", "--template", "ansible"
    ansible_lines = (testpath/"site.yml").read.lines
    assert_equal "# File: site.yml\\n", ansible_lines[0]
    assert_equal "# Description:\\n", ansible_lines[1]
    assert_match(/^# Created: \\d{4}-\\d{2}-\\d{2}\\n$/, ansible_lines[2])
    assert_match(/^# Creator: .+\\n$/, ansible_lines[3])
    assert_equal "\\n", ansible_lines[4]
    assert_equal "---\\n", ansible_lines[5]
    assert_equal "- name: site.yml\\n", ansible_lines[6]
    assert_equal "  hosts: all\\n", ansible_lines[7]
    assert_equal "  gather_facts: false\\n", ansible_lines[8]
    assert_equal "  tasks: []\\n", ansible_lines[9]
  end
end
EOF

printf 'Rendered Homebrew formula: %s\n' "$output"
