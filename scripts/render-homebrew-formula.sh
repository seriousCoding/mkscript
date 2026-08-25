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
  desc "Create Bash, Docker, Kubernetes, Terraform, and Ansible starter files safely"
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
    assert_includes demo_lines, "main \"\$@\"\n"

    system bin/"mkscript", "-s", "strict-demo"
    strict_demo_lines = (testpath/"strict-demo").read.lines
    assert_equal "#!/usr/bin/env bash\\n", strict_demo_lines[0]
    assert_equal "# Script: strict-demo\\n", strict_demo_lines[1]
    assert_equal "# Description:\\n", strict_demo_lines[2]
    assert_match(/^# Created: \\d{4}-\\d{2}-\\d{2}\\n$/, strict_demo_lines[3])
    assert_match(/^# Creator: .+\\n$/, strict_demo_lines[4])
    assert_equal "set -euo pipefail\\n", strict_demo_lines[5]
    assert_includes strict_demo_lines, "main \"\$@\"\n"

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
    assert_equal "  gather_facts: true\\n", ansible_lines[8]
    assert_includes ansible_lines, "  handlers: []\\n"

    system bin/"mkscript", "--template", "dockerfile", "Dockerfile"
    dockerfile_lines = (testpath/"Dockerfile").read.lines
    assert_equal "# File: Dockerfile\\n", dockerfile_lines[0]
    assert_equal "# Description:\\n", dockerfile_lines[1]
    assert_match(/^# Created: \\d{4}-\\d{2}-\\d{2}\\n$/, dockerfile_lines[2])
    assert_match(/^# Creator: .+\\n$/, dockerfile_lines[3])
    assert_equal "\\n", dockerfile_lines[4]
    assert_equal "FROM alpine:3.22\\n", dockerfile_lines[5]
    assert_includes dockerfile_lines, "HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1:8080/ || exit 1\\n"

    system bin/"mkscript", "--template", "k8s-deployment", "deployment.yaml"
    deployment_lines = (testpath/"deployment.yaml").read.lines
    assert_equal "# File: deployment.yaml\\n", deployment_lines[0]
    assert_equal "# Description:\\n", deployment_lines[1]
    assert_match(/^# Created: \\d{4}-\\d{2}-\\d{2}\\n$/, deployment_lines[2])
    assert_match(/^# Creator: .+\\n$/, deployment_lines[3])
    assert_equal "\\n", deployment_lines[4]
    assert_equal "apiVersion: apps/v1\\n", deployment_lines[5]
    assert_equal "kind: Deployment\\n", deployment_lines[6]
  end
end
EOF

printf 'Rendered Homebrew formula: %s\n' "$output"
