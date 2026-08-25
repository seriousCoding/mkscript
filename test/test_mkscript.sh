#!/usr/bin/env bash
set -euo pipefail

: "${MKSCRIPT_UNDER_TEST:?MKSCRIPT_UNDER_TEST is required}"
: "${VERSION:?VERSION is required}"

tests_run=0
START_DIR=$(pwd)
CURRENT_OS=$(uname -s)

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_equals() {
  local expected=$1
  local actual=$2
  local message=$3

  if [ "$expected" != "$actual" ]; then
    printf 'FAIL: %s\nExpected: %s\nActual: %s\n' "$message" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_contains() {
  local haystack=$1
  local needle=$2
  local message=$3

  case $haystack in
    *"$needle"*)
      ;;
    *)
      printf 'FAIL: %s\nMissing: %s\nContent: %s\n' "$message" "$needle" "$haystack" >&2
      exit 1
      ;;
  esac
}

assert_matches() {
  local content=$1
  local pattern=$2
  local message=$3

  if ! printf '%s\n' "$content" | grep -Eq -- "$pattern"; then
    printf 'FAIL: %s\nPattern: %s\nContent: %s\n' "$message" "$pattern" "$content" >&2
    exit 1
  fi
}

assert_grep_count() {
  local expected=$1
  local content=$2
  local pattern=$3
  local message=$4
  local actual

  actual=$(printf '%s\n' "$content" | grep -Ec -- "$pattern" || true)
  if [ "$actual" -ne "$expected" ]; then
    printf 'FAIL: %s\nExpected matches: %s\nActual matches: %s\nPattern: %s\nContent: %s\n' \
      "$message" "$expected" "$actual" "$pattern" "$content" >&2
    exit 1
  fi
}

assert_status() {
  local expected=$1
  local actual=$2
  local message=$3

  if [ "$expected" -ne "$actual" ]; then
    printf 'FAIL: %s\nExpected status: %s\nActual status: %s\n' "$message" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_file_equals() {
  local file=$1
  local expected_content=$2
  local message=$3
  local expected_file

  expected_file=$(mktemp)
  printf '%s' "$expected_content" > "$expected_file"

  if ! cmp -s "$file" "$expected_file"; then
    printf 'FAIL: %s\n' "$message" >&2
    printf 'Expected file contents:\n' >&2
    cat "$expected_file" >&2
    printf 'Actual file contents:\n' >&2
    cat "$file" >&2
    rm -f "$expected_file"
    exit 1
  fi

  rm -f "$expected_file"
}

assert_executable() {
  local file=$1
  local message=$2

  if [ ! -x "$file" ]; then
    fail "$message"
  fi
}

assert_not_executable() {
  local file=$1
  local message=$2

  if [ -x "$file" ]; then
    fail "$message"
  fi
}

assert_not_exists() {
  local path=$1
  local message=$2

  if [ -e "$path" ] || [ -L "$path" ]; then
    fail "$message"
  fi
}

assert_symlink_target() {
  local path=$1
  local expected_target=$2
  local message=$3
  local actual_target

  if [ ! -L "$path" ]; then
    fail "$message"
  fi

  actual_target=$(readlink "$path")
  assert_equals "$expected_target" "$actual_target" "$message"
}

file_mode() {
  local file=$1
  local mode

  if mode=$(stat -c '%a' "$file" 2>/dev/null); then
    printf '%s\n' "$mode"
    return 0
  fi

  if mode=$(stat -f '%Lp' "$file" 2>/dev/null); then
    printf '%s\n' "$mode"
    return 0
  fi

  fail "failed to determine file mode for $file"
}

parent_dir() {
  local path=$1
  local parent

  case $path in
    */*)
      parent=${path%/*}
      if [ -z "$parent" ]; then
        printf '/\n'
      else
        printf '%s\n' "$parent"
      fi
      ;;
    *)
      printf '.\n'
      ;;
  esac
}

path_has_entry() {
  local needle=$1
  local path_value=${2-}
  local path_entry
  local old_ifs=$IFS

  IFS=:
  for path_entry in $path_value; do
    if [ "$path_entry" = "$needle" ]; then
      IFS=$old_ifs
      return 0
    fi
  done
  IFS=$old_ifs

  return 1
}

expected_global_dir() {
  local home_dir=$1
  local path_value=$2
  local path_entry
  local parent_name
  local old_ifs=$IFS

  if [ "$CURRENT_OS" = 'Darwin' ]; then
    if path_has_entry "$home_dir/.local/bin" "$path_value"; then
      printf '%s/.local/bin\n' "$home_dir"
      return 0
    fi

    if path_has_entry "$home_dir/bin" "$path_value"; then
      printf '%s/bin\n' "$home_dir"
      return 0
    fi

    IFS=:
    for path_entry in $path_value; do
      case $path_entry in
        "$home_dir"/*/bin)
          parent_name=${path_entry%/bin}
          parent_name=${parent_name##*/}
          case $parent_name in
            *local*)
              IFS=$old_ifs
              printf '%s\n' "$path_entry"
              return 0
              ;;
          esac
          ;;
      esac
    done
    IFS=$old_ifs
  fi

  printf '%s/.local/bin\n' "$home_dir"
}

expected_global_link_path() {
  local home_dir=$1
  local path_value=$2
  local target_name=$3

  printf '%s/%s\n' "$(expected_global_dir "$home_dir" "$path_value")" "$target_name"
}

default_global_test_path() {
  local home_dir=$1

  printf '%s/.new_local/bin:/usr/bin:/bin\n' "$home_dir"
}

RUN_STATUS=0
RUN_STDOUT=''
RUN_STDERR=''

current_creator_name() {
  local creator

  creator=$(id -un 2>/dev/null || true)
  if [ -z "$creator" ]; then
    creator=${LOGNAME:-${USER:-}}
  fi
  if [ -z "$creator" ]; then
    fail 'failed to determine creator name for test expectations'
  fi

  printf '%s\n' "$creator"
}

current_created_date() {
  local created_date

  created_date=$(date '+%Y-%m-%d' 2>/dev/null || true)
  if [ -z "$created_date" ]; then
    fail 'failed to determine current date for test expectations'
  fi

  printf '%s\n' "$created_date"
}

expected_bash_content() {
  local target_name=$1
  local strict_enabled=$2

  printf '#!/usr/bin/env bash\n'
  printf '# Script: %s\n' "$target_name"
  printf '# Description:\n'
  printf '# Created: %s\n' "$(current_created_date)"
  printf '# Creator: %s\n' "$(current_creator_name)"
  if [ "$strict_enabled" -eq 1 ]; then
    printf 'set -euo pipefail\n'
  fi
  printf '\nusage() {\n'
  # shellcheck disable=SC2016
  printf '%s\n' '  printf '\''Usage: %s [options]\n'\'' "${0##*/}"'
  printf '}\n\nlog() {\n  printf "%%s\\n" "$*" >&2\n}\n\nmain() {\n  # Add application logic here.\n  log "running %s"\n}\n\nmain "$@"\n' "$target_name"
}

expected_terraform_content() {
  local target_name=$1

  printf '# File: %s\n' "$target_name"
  printf '# Description:\n'
  printf '# Created: %s\n' "$(current_created_date)"
  printf '# Creator: %s\n' "$(current_creator_name)"
  printf '\n'
  printf 'terraform {\n'
  printf '  required_version = ">= 1.0.0"\n'
  printf '  required_providers {\n'
  printf '    # Add providers required by this configuration.\n'
  printf '  }\n'
  printf '}\n'
  printf '\nvariable "name" {\n  description = "Name used by resources in this configuration."\n  type        = string\n}\n'
  printf '\nlocals {\n  common_tags = {\n    managed_by = "terraform"\n  }\n}\n'
  printf '\noutput "name" {\n  description = "Configured resource name."\n  value       = var.name\n}\n'
}

expected_ansible_content() {
  local target_name=$1

  printf '# File: %s\n' "$target_name"
  printf '# Description:\n'
  printf '# Created: %s\n' "$(current_created_date)"
  printf '# Creator: %s\n' "$(current_creator_name)"
  printf '\n'
  printf -- '---\n'
  printf -- '- name: %s\n' "$target_name"
  printf '  hosts: all\n'
  printf '  gather_facts: true\n'
  printf '  vars: {}\n'
  printf '  pre_tasks:\n    - name: Validate managed hosts\n      ansible.builtin.assert:\n        that: ansible_facts.os_family is defined\n'
  printf '  tasks:\n    - name: Add application tasks\n      ansible.builtin.debug:\n        msg: "Replace this task with application configuration."\n      changed_when: false\n'
  printf '  handlers: []\n  post_tasks: []\n'
}

template_stem_name_for_test() {
  local target_name=$1

  case $target_name in
    *.*)
      printf '%s\n' "${target_name%.*}"
      ;;
    *)
      printf '%s\n' "$target_name"
      ;;
  esac
}

normalize_manifest_name_for_test() {
  local target_name=$1
  local normalized

  normalized=$(
    printf '%s' "$(template_stem_name_for_test "$target_name")" |
      tr '[:upper:]' '[:lower:]' |
      sed \
        -e 's/[[:space:]_][[:space:]_]*/-/g' \
        -e 's/[^a-z0-9.-]/-/g' \
        -e 's/-\{2,\}/-/g' \
        -e 's/\.\{2,\}/./g' \
        -e 's/^[^a-z0-9]*//' \
        -e 's/[^a-z0-9]*$//'
  )

  if [ -z "$normalized" ]; then
    fail "failed to derive normalized manifest name in test for $target_name"
  fi

  printf '%s\n' "$normalized"
}

manifest_storage_class_name_for_test() {
  printf '%s-storage\n' "$(normalize_manifest_name_for_test "$1")"
}

expected_dockerfile_content() {
  local target_name=$1

  printf '# File: %s\n' "$target_name"
  printf '# Description:\n'
  printf '# Created: %s\n' "$(current_created_date)"
  printf '# Creator: %s\n' "$(current_creator_name)"
  printf '\n'
  printf 'FROM alpine:3.22\n'
  printf 'RUN addgroup -S app && adduser -S app -G app\n'
  printf 'WORKDIR /app\n'
  printf 'COPY --chown=app:app . .\n'
  printf 'USER app\nEXPOSE 8080\n'
  printf 'HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1:8080/ || exit 1\n'
  printf 'CMD ["sh", "-c", "echo Replace this command with your application; sleep infinity"]\n'
}

expected_docker_compose_content() {
  local target_name=$1
  local service_name

  service_name=$(normalize_manifest_name_for_test "$target_name")

  printf '# File: %s\n' "$target_name"
  printf '# Description:\n'
  printf '# Created: %s\n' "$(current_created_date)"
  printf '# Creator: %s\n' "$(current_creator_name)"
  printf '\n'
  printf 'services:\n'
  printf '  %s:\n' "$service_name"
  printf '    image: nginx:1.29-alpine\n'
  printf '    restart: unless-stopped\n'
  printf '    ports:\n'
  printf '      - "8080:80"\n'
  printf '    environment:\n      NGINX_ENTRYPOINT_QUIET_LOGS: "1"\n'
  printf '    volumes:\n      - %s-data:/usr/share/nginx/html\n' "$service_name"
  printf '    networks:\n      - %s-network\n' "$service_name"
  printf '    healthcheck:\n      test: ["CMD-SHELL", "wget -qO- http://localhost/ || exit 1"]\n      interval: 30s\n      timeout: 5s\n      retries: 3\n'
  printf '    deploy:\n      resources:\n        limits:\n          cpus: "0.50"\n          memory: 256M\n'
  printf 'networks:\n  %s-network:\n    driver: bridge\nvolumes:\n  %s-data:\n' "$service_name" "$service_name"
}

expected_k8s_template_content() {
  local template=$1
  local target_name=$2
  local resource_name
  local storage_class_name
  local role_name
  local binding_name
  local cluster_role_name
  local cluster_binding_name

  resource_name=$(normalize_manifest_name_for_test "$target_name")
  storage_class_name=$(manifest_storage_class_name_for_test "$target_name")
  role_name="${resource_name}-role"
  binding_name="${resource_name}-binding"
  cluster_role_name="${resource_name}-clusterrole"
  cluster_binding_name="${resource_name}-clusterrolebinding"

  printf '# File: %s\n' "$target_name"
  printf '# Description:\n'
  printf '# Created: %s\n' "$(current_created_date)"
  printf '# Creator: %s\n' "$(current_creator_name)"
  printf '\n'

  case $template in
    k8s-namespace)
      printf 'apiVersion: v1\n'
      printf 'kind: Namespace\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$resource_name"
      ;;
    k8s-pod)
      printf 'apiVersion: v1\n'
      printf 'kind: Pod\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$resource_name"
      printf '  labels:\n'
      printf '    app: %s\n' "$resource_name"
      printf 'spec:\n'
      printf '  containers:\n'
      printf '    - name: %s\n' "$resource_name"
      printf '      image: registry.k8s.io/pause:3.10\n'
      ;;
    k8s-deployment)
      printf 'apiVersion: apps/v1\n'
      printf 'kind: Deployment\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$resource_name"
      printf 'spec:\n'
      printf '  replicas: 1\n'
      printf '  selector:\n'
      printf '    matchLabels:\n'
      printf '      app: %s\n' "$resource_name"
      printf '  template:\n'
      printf '    metadata:\n'
      printf '      labels:\n'
      printf '        app: %s\n' "$resource_name"
      printf '    spec:\n'
      printf '      containers:\n'
      printf '        - name: %s\n' "$resource_name"
      printf '          image: registry.k8s.io/pause:3.10\n'
      ;;
    k8s-service)
      printf 'apiVersion: v1\n'
      printf 'kind: Service\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$resource_name"
      printf 'spec:\n'
      printf '  selector:\n'
      printf '    app: %s\n' "$resource_name"
      printf '  ports:\n'
      printf '    - port: 80\n'
      printf '      targetPort: 80\n'
      ;;
    k8s-configmap)
      printf 'apiVersion: v1\n'
      printf 'kind: ConfigMap\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$resource_name"
      printf 'data: {}\n'
      ;;
    k8s-secret)
      printf 'apiVersion: v1\n'
      printf 'kind: Secret\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$resource_name"
      printf 'type: Opaque\n'
      printf 'stringData: {}\n'
      ;;
    k8s-ingress)
      printf 'apiVersion: networking.k8s.io/v1\n'
      printf 'kind: Ingress\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$resource_name"
      printf 'spec:\n'
      printf '  rules:\n'
      printf '    - host: %s.example.com\n' "$resource_name"
      printf '      http:\n'
      printf '        paths:\n'
      printf '          - path: /\n'
      printf '            pathType: Prefix\n'
      printf '            backend:\n'
      printf '              service:\n'
      printf '                name: %s\n' "$resource_name"
      printf '                port:\n'
      printf '                  number: 80\n'
      ;;
    k8s-networkpolicy)
      printf 'apiVersion: networking.k8s.io/v1\n'
      printf 'kind: NetworkPolicy\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$resource_name"
      printf 'spec:\n'
      printf '  podSelector:\n'
      printf '    matchLabels:\n'
      printf '      app: %s\n' "$resource_name"
      printf '  policyTypes:\n'
      printf '    - Ingress\n'
      printf '  ingress: []\n'
      ;;
    k8s-serviceaccount)
      printf 'apiVersion: v1\n'
      printf 'kind: ServiceAccount\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$resource_name"
      ;;
    k8s-role)
      printf 'apiVersion: rbac.authorization.k8s.io/v1\n'
      printf 'kind: Role\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$role_name"
      printf '  namespace: %s\n' "$resource_name"
      printf 'rules: []\n'
      ;;
    k8s-rolebinding)
      printf 'apiVersion: rbac.authorization.k8s.io/v1\n'
      printf 'kind: RoleBinding\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$binding_name"
      printf '  namespace: %s\n' "$resource_name"
      printf 'subjects:\n'
      printf '  - kind: ServiceAccount\n'
      printf '    name: %s\n' "$resource_name"
      printf '    namespace: %s\n' "$resource_name"
      printf 'roleRef:\n'
      printf '  apiGroup: rbac.authorization.k8s.io\n'
      printf '  kind: Role\n'
      printf '  name: %s\n' "$role_name"
      ;;
    k8s-clusterrole)
      printf 'apiVersion: rbac.authorization.k8s.io/v1\n'
      printf 'kind: ClusterRole\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$cluster_role_name"
      printf 'rules: []\n'
      ;;
    k8s-clusterrolebinding)
      printf 'apiVersion: rbac.authorization.k8s.io/v1\n'
      printf 'kind: ClusterRoleBinding\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$cluster_binding_name"
      printf 'subjects:\n'
      printf '  - kind: ServiceAccount\n'
      printf '    name: %s\n' "$resource_name"
      printf '    namespace: %s\n' "$resource_name"
      printf 'roleRef:\n'
      printf '  apiGroup: rbac.authorization.k8s.io\n'
      printf '  kind: ClusterRole\n'
      printf '  name: %s\n' "$cluster_role_name"
      ;;
    k8s-persistentvolume)
      printf 'apiVersion: v1\n'
      printf 'kind: PersistentVolume\n'
      printf 'metadata:\n'
      printf '  name: %s-pv\n' "$resource_name"
      printf 'spec:\n'
      printf '  capacity:\n'
      printf '    storage: 10Gi\n'
      printf '  accessModes:\n'
      printf '    - ReadWriteOnce\n'
      printf '  storageClassName: %s\n' "$storage_class_name"
      printf '  hostPath:\n'
      printf '    path: /mnt/data/%s\n' "$resource_name"
      ;;
    k8s-persistentvolumeclaim)
      printf 'apiVersion: v1\n'
      printf 'kind: PersistentVolumeClaim\n'
      printf 'metadata:\n'
      printf '  name: %s-pvc\n' "$resource_name"
      printf 'spec:\n'
      printf '  accessModes:\n'
      printf '    - ReadWriteOnce\n'
      printf '  resources:\n'
      printf '    requests:\n'
      printf '      storage: 10Gi\n'
      printf '  storageClassName: %s\n' "$storage_class_name"
      ;;
    k8s-storageclass)
      printf 'apiVersion: storage.k8s.io/v1\n'
      printf 'kind: StorageClass\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$storage_class_name"
      printf 'provisioner: kubernetes.io/no-provisioner\n'
      printf 'volumeBindingMode: WaitForFirstConsumer\n'
      ;;
    k8s-statefulset)
      printf 'apiVersion: apps/v1\n'
      printf 'kind: StatefulSet\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$resource_name"
      printf 'spec:\n'
      printf '  serviceName: %s\n' "$resource_name"
      printf '  replicas: 1\n'
      printf '  selector:\n'
      printf '    matchLabels:\n'
      printf '      app: %s\n' "$resource_name"
      printf '  template:\n'
      printf '    metadata:\n'
      printf '      labels:\n'
      printf '        app: %s\n' "$resource_name"
      printf '    spec:\n'
      printf '      containers:\n'
      printf '        - name: %s\n' "$resource_name"
      printf '          image: registry.k8s.io/pause:3.10\n'
      ;;
    k8s-daemonset)
      printf 'apiVersion: apps/v1\n'
      printf 'kind: DaemonSet\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$resource_name"
      printf 'spec:\n'
      printf '  selector:\n'
      printf '    matchLabels:\n'
      printf '      app: %s\n' "$resource_name"
      printf '  template:\n'
      printf '    metadata:\n'
      printf '      labels:\n'
      printf '        app: %s\n' "$resource_name"
      printf '    spec:\n'
      printf '      containers:\n'
      printf '        - name: %s\n' "$resource_name"
      printf '          image: registry.k8s.io/pause:3.10\n'
      ;;
    k8s-job)
      printf 'apiVersion: batch/v1\n'
      printf 'kind: Job\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$resource_name"
      printf 'spec:\n'
      printf '  template:\n'
      printf '    spec:\n'
      printf '      restartPolicy: Never\n'
      printf '      containers:\n'
      printf '        - name: %s\n' "$resource_name"
      printf '          image: busybox:1.36\n'
      printf '          command: ["sh", "-c", "echo job complete"]\n'
      ;;
    k8s-cronjob)
      printf 'apiVersion: batch/v1\n'
      printf 'kind: CronJob\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$resource_name"
      printf 'spec:\n'
      printf '  schedule: "0 * * * *"\n'
      printf '  jobTemplate:\n'
      printf '    spec:\n'
      printf '      template:\n'
      printf '        spec:\n'
      printf '          restartPolicy: OnFailure\n'
      printf '          containers:\n'
      printf '            - name: %s\n' "$resource_name"
      printf '              image: busybox:1.36\n'
      printf '              command: ["sh", "-c", "echo cronjob complete"]\n'
      ;;
    k8s-horizontalpodautoscaler)
      printf 'apiVersion: autoscaling/v2\n'
      printf 'kind: HorizontalPodAutoscaler\n'
      printf 'metadata:\n'
      printf '  name: %s\n' "$resource_name"
      printf 'spec:\n'
      printf '  scaleTargetRef:\n'
      printf '    apiVersion: apps/v1\n'
      printf '    kind: Deployment\n'
      printf '    name: %s\n' "$resource_name"
      printf '  minReplicas: 1\n'
      printf '  maxReplicas: 3\n'
      printf '  metrics:\n'
      printf '    - type: Resource\n'
      printf '      resource:\n'
      printf '        name: cpu\n'
      printf '        target:\n'
      printf '          type: Utilization\n'
      printf '          averageUtilization: 80\n'
      ;;
    *)
      fail "unknown k8s template in test expectation: $template"
      ;;
  esac
}

assert_template_file_equals() {
  local file=$1
  local template=$2
  local target_name=$3
  local strict_enabled=$4
  local message=$5
  local expected_file

  expected_file=$(mktemp)

  case $template in
    bash)
      expected_bash_content "$target_name" "$strict_enabled" > "$expected_file"
      ;;
    terraform)
      expected_terraform_content "$target_name" > "$expected_file"
      ;;
    ansible)
      expected_ansible_content "$target_name" > "$expected_file"
      ;;
    dockerfile)
      expected_dockerfile_content "$target_name" > "$expected_file"
      ;;
    docker-compose)
      expected_docker_compose_content "$target_name" > "$expected_file"
      ;;
    k8s-*)
      expected_k8s_template_content "$template" "$target_name" > "$expected_file"
      ;;
    *)
      rm -f "$expected_file"
      fail "unknown template in test expectation: $template"
      ;;
  esac

  if ! cmp -s "$file" "$expected_file"; then
    printf 'FAIL: %s\n' "$message" >&2
    printf 'Expected file contents:\n' >&2
    cat "$expected_file" >&2
    printf 'Actual file contents:\n' >&2
    cat "$file" >&2
    rm -f "$expected_file"
    exit 1
  fi

  rm -f "$expected_file"
}

run_capture() {
  local stdout_file
  local stderr_file

  stdout_file=$(mktemp)
  stderr_file=$(mktemp)

  if "$@" >"$stdout_file" 2>"$stderr_file"; then
    RUN_STATUS=0
  else
    RUN_STATUS=$?
  fi

  RUN_STDOUT=$(cat "$stdout_file")
  RUN_STDERR=$(cat "$stderr_file")

  rm -f "$stdout_file" "$stderr_file"
}

run_capture_with_input() {
  local input=$1
  local stdin_file
  local stdout_file
  local stderr_file

  shift

  stdin_file=$(mktemp)
  stdout_file=$(mktemp)
  stderr_file=$(mktemp)

  printf '%s' "$input" > "$stdin_file"

  if "$@" <"$stdin_file" >"$stdout_file" 2>"$stderr_file"; then
    RUN_STATUS=0
  else
    RUN_STATUS=$?
  fi

  RUN_STDOUT=$(cat "$stdout_file")
  RUN_STDERR=$(cat "$stderr_file")

  rm -f "$stdin_file" "$stdout_file" "$stderr_file"
}

target_path_for_template() {
  case $1 in
    dockerfile)
      printf 'Dockerfile\n'
      ;;
    docker-compose)
      printf 'compose.yaml\n'
      ;;
    k8s-namespace)
      printf 'namespace.yaml\n'
      ;;
    k8s-pod)
      printf 'pod.yaml\n'
      ;;
    k8s-deployment)
      printf 'deployment.yaml\n'
      ;;
    k8s-service)
      printf 'service.yaml\n'
      ;;
    k8s-configmap)
      printf 'configmap.yaml\n'
      ;;
    k8s-secret)
      printf 'secret.yaml\n'
      ;;
    k8s-ingress)
      printf 'ingress.yaml\n'
      ;;
    k8s-networkpolicy)
      printf 'networkpolicy.yaml\n'
      ;;
    k8s-serviceaccount)
      printf 'serviceaccount.yaml\n'
      ;;
    k8s-role)
      printf 'role.yaml\n'
      ;;
    k8s-rolebinding)
      printf 'rolebinding.yaml\n'
      ;;
    k8s-clusterrole)
      printf 'clusterrole.yaml\n'
      ;;
    k8s-clusterrolebinding)
      printf 'clusterrolebinding.yaml\n'
      ;;
    k8s-persistentvolume)
      printf 'persistentvolume.yaml\n'
      ;;
    k8s-persistentvolumeclaim)
      printf 'persistentvolumeclaim.yaml\n'
      ;;
    k8s-storageclass)
      printf 'storageclass.yaml\n'
      ;;
    k8s-statefulset)
      printf 'statefulset.yaml\n'
      ;;
    k8s-daemonset)
      printf 'daemonset.yaml\n'
      ;;
    k8s-job)
      printf 'job.yaml\n'
      ;;
    k8s-cronjob)
      printf 'cronjob.yaml\n'
      ;;
    k8s-horizontalpodautoscaler)
      printf 'horizontalpodautoscaler.yaml\n'
      ;;
    *)
      fail "unknown template target request: $1"
      ;;
  esac
}

all_new_templates() {
  cat <<'EOF'
dockerfile
docker-compose
k8s-namespace
k8s-pod
k8s-deployment
k8s-service
k8s-configmap
k8s-secret
k8s-ingress
k8s-networkpolicy
k8s-serviceaccount
k8s-role
k8s-rolebinding
k8s-clusterrole
k8s-clusterrolebinding
k8s-persistentvolume
k8s-persistentvolumeclaim
k8s-storageclass
k8s-statefulset
k8s-daemonset
k8s-job
k8s-cronjob
k8s-horizontalpodautoscaler
EOF
}

test_plain_script_creation() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" hello-world
  assert_status 0 "$RUN_STATUS" 'plain script creation should succeed'
  assert_contains "$RUN_STDOUT" 'Created script: hello-world' 'success output should mention the target path'
  assert_template_file_equals hello-world bash hello-world 0 'plain script should include the default header'
  assert_executable hello-world 'plain script should be executable'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_template_target_defaults_and_helm() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture_with_input $'y\n' "$MKSCRIPT_UNDER_TEST" -t docker
  assert_status 0 "$RUN_STATUS" 'docker default target should be confirmed and created'
  assert_contains "$RUN_STDOUT" 'To provide a filename, use: mkscript -t docker Dockerfile' 'docker default confirmation should preserve the alias'
  assert_contains "$(cat Dockerfile)" 'HEALTHCHECK' 'Dockerfile should include an operational health check'
  run_capture "$MKSCRIPT_UNDER_TEST" -t docker-compose app
  assert_status 0 "$RUN_STATUS" 'docker-compose should add a missing extension'
  assert_contains "$(cat app.yml)" 'networks:' 'Compose should include a network declaration'
  assert_contains "$(cat app.yml)" 'volumes:' 'Compose should include a volume declaration'
  run_capture_with_input $'n\n' "$MKSCRIPT_UNDER_TEST" -t helm
  assert_status 73 "$RUN_STATUS" 'declined Helm default should fail without creating a chart'
  assert_not_exists chart 'declined Helm default should not create a chart directory'
  run_capture "$MKSCRIPT_UNDER_TEST" -t helm service-chart
  assert_status 0 "$RUN_STATUS" 'Helm chart creation should succeed'
  assert_contains "$(cat service-chart/Chart.yaml)" 'apiVersion: v2' 'Helm Chart.yaml should use v2'
  assert_contains "$(cat service-chart/values.yaml)" 'autoscaling:' 'Helm values should contain operational options'
  assert_not_exists service-chart/missing 'chart assertion should not create extra paths'
  if command -v helm >/dev/null 2>&1; then
    helm lint service-chart >/dev/null
    helm template service-chart service-chart >/dev/null
  fi
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_short_strict_mode() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -s strict-short
  assert_status 0 "$RUN_STATUS" 'short strict flag should succeed'
  assert_template_file_equals strict-short bash strict-short 1 'short strict flag should add strict mode after the default header'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_long_strict_mode_with_absolute_path() {
  local sandbox
  local target

  sandbox=$(mktemp -d)
  target="$sandbox/path with spaces.sh"
  run_capture "$MKSCRIPT_UNDER_TEST" --strict "$target"
  assert_status 0 "$RUN_STATUS" 'long strict flag should succeed with an absolute path'
  assert_template_file_equals "$target" bash 'path with spaces.sh' 1 'long strict flag should add strict mode after the default header'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_terraform_template_creation() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" --template terraform main.tf
  assert_status 0 "$RUN_STATUS" 'terraform template creation should succeed'
  assert_contains "$RUN_STDOUT" 'Created file: main.tf' 'terraform template creation should report the created file'
  assert_template_file_equals main.tf terraform main.tf 0 'terraform template should match the expected starter content'
  assert_not_executable main.tf 'terraform template should not be executable'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_terraform_template_creation_with_trailing_flag() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" main.tf -t terraform
  assert_status 0 "$RUN_STATUS" 'terraform template should allow the template flag after the path'
  assert_template_file_equals main.tf terraform main.tf 0 'trailing terraform template flag should create the expected starter content'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_ansible_template_creation() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -t ansible site.yml
  assert_status 0 "$RUN_STATUS" 'ansible template creation should succeed'
  assert_contains "$RUN_STDOUT" 'Created file: site.yml' 'ansible template creation should report the created file'
  assert_template_file_equals site.yml ansible site.yml 0 'ansible template should match the expected starter content'
  assert_not_executable site.yml 'ansible template should not be executable'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_ansible_template_creation_with_trailing_flag() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" site.yml --template ansible
  assert_status 0 "$RUN_STATUS" 'ansible template should allow the template flag after the path'
  assert_template_file_equals site.yml ansible site.yml 0 'trailing ansible template flag should create the expected starter content'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_additional_template_creation() {
  local sandbox
  local template
  local target

  sandbox=$(mktemp -d)
  cd "$sandbox"
  while IFS= read -r template; do
    target=$(target_path_for_template "$template")
    run_capture "$MKSCRIPT_UNDER_TEST" --template "$template" "$target"
    assert_status 0 "$RUN_STATUS" "$template creation should succeed"
    assert_contains "$RUN_STDOUT" "Created file: $target" "$template creation should report the created file"
    assert_template_file_equals "$target" "$template" "$target" 0 "$template should match the expected starter content"
    assert_not_executable "$target" "$template should not be executable"
  done < <(all_new_templates)
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_additional_template_creation_with_trailing_flag() {
  local sandbox
  local template
  local target

  sandbox=$(mktemp -d)
  cd "$sandbox"
  while IFS= read -r template; do
    target=$(target_path_for_template "$template")
    run_capture "$MKSCRIPT_UNDER_TEST" "$target" -t "$template"
    assert_status 0 "$RUN_STATUS" "$template should allow the template flag after the path"
    assert_template_file_equals "$target" "$template" "$target" 0 "trailing $template template flag should create the expected starter content"
  done < <(all_new_templates)
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_terraform_template_rejects_strict_flag() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" --template terraform -s main.tf
  assert_status 64 "$RUN_STATUS" 'terraform template should reject strict mode'
  assert_contains "$RUN_STDERR" '--strict is only supported with the bash template' 'terraform strict mode rejection should be explained'
  assert_not_exists main.tf 'rejected terraform strict mode should not create a file'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_ansible_template_rejects_strict_flag() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" site.yml --template ansible --strict
  assert_status 64 "$RUN_STATUS" 'ansible template should reject strict mode'
  assert_contains "$RUN_STDERR" '--strict is only supported with the bash template' 'ansible strict mode rejection should be explained'
  assert_not_exists site.yml 'rejected ansible strict mode should not create a file'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_terraform_template_rejects_global_flag() {
  local sandbox
  local home_dir
  local path_value

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -t terraform main.tf -g
  assert_status 64 "$RUN_STATUS" 'terraform template should reject global mode'
  assert_contains "$RUN_STDERR" '--global is only supported with the bash template' 'terraform global mode rejection should be explained'
  assert_not_exists main.tf 'rejected terraform global mode should not create a file'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_ansible_template_rejects_global_flag() {
  local sandbox
  local home_dir
  local path_value

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" site.yml -g -t ansible
  assert_status 64 "$RUN_STATUS" 'ansible template should reject global mode'
  assert_contains "$RUN_STDERR" '--global is only supported with the bash template' 'ansible global mode rejection should be explained'
  assert_not_exists site.yml 'rejected ansible global mode should not create a file'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_additional_templates_reject_strict_flag() {
  local sandbox
  local template
  local target

  sandbox=$(mktemp -d)
  cd "$sandbox"
  while IFS= read -r template; do
    target=$(target_path_for_template "$template")
    run_capture "$MKSCRIPT_UNDER_TEST" --template "$template" --strict "$target"
    assert_status 64 "$RUN_STATUS" "$template should reject strict mode"
    assert_contains "$RUN_STDERR" '--strict is only supported with the bash template' "$template strict mode rejection should be explained"
    assert_not_exists "$target" "rejected $template strict mode should not create a file"
  done < <(all_new_templates)
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_additional_templates_reject_global_flag() {
  local sandbox
  local home_dir
  local path_value
  local template
  local target

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  mkdir -p "$home_dir"
  cd "$sandbox"
  while IFS= read -r template; do
    target=$(target_path_for_template "$template")
    run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" --template "$template" -g "$target"
    assert_status 64 "$RUN_STATUS" "$template should reject global mode"
    assert_contains "$RUN_STDERR" '--global is only supported with the bash template' "$template global mode rejection should be explained"
    assert_not_exists "$target" "rejected $template global mode should not create a file"
  done < <(all_new_templates)
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_invalid_template_value() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" --template yaml hello.yml
  assert_status 64 "$RUN_STATUS" 'unknown template names should be a usage error'
  assert_contains "$RUN_STDERR" 'unsupported template: yaml' 'unknown template names should be explained'
  assert_not_exists hello.yml 'unknown template names should not create a file'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_help_output() {
  run_capture "$MKSCRIPT_UNDER_TEST" --help
  assert_status 0 "$RUN_STATUS" 'help should exit successfully'
  assert_contains "$RUN_STDOUT" 'Usage:' 'help should show the usage header'
  assert_contains "$RUN_STDOUT" 'mkscript [OPTION]... PATH' 'help should show the create-path usage form'
  assert_contains "$RUN_STDOUT" 'mkscript -f|--files [DEPTH]' 'help should show the file-listing usage form'
  assert_contains "$RUN_STDOUT" 'mkscript -f|--files NAME [NAME ...]' 'help should show the file lookup usage form'
  assert_contains "$RUN_STDOUT" '-t, --template TEMPLATE' 'help should document template selection'
  assert_contains "$RUN_STDOUT" '-f, --files' 'help should document file listing mode'
  assert_contains "$RUN_STDOUT" 'DEPTH 0-9 limits subfolder scanning; 0 means current folder only' 'help should explain file listing depth'
  assert_contains "$RUN_STDOUT" 'NAME arguments, or piped newline-separated names, perform lookup mode' 'help should explain file lookup mode'
  assert_contains "$RUN_STDOUT" "quoted shell-style glob patterns like 'install-wifi*' are supported" 'help should document quoted glob lookup support'
  assert_contains "$RUN_STDOUT" 'quote patterns so your shell does not expand them first' 'help should explain why glob queries should be quoted'
  assert_contains "$RUN_STDOUT" '-mv' 'help should document move mode'
  assert_contains "$RUN_STDOUT" 'use bash, terraform, ansible, dockerfile (or docker), docker-compose, helm,' 'help should list the expanded template families'
  assert_contains "$RUN_STDOUT" 'k8s-namespace, k8s-pod, k8s-deployment, k8s-service,' 'help should list Kubernetes starter templates'
  assert_contains "$RUN_STDOUT" '-s, --strict' 'help should document strict mode'
  assert_contains "$RUN_STDOUT" '-g, --global' 'help should document global mode'
  assert_contains "$RUN_STDOUT" 'create a global symlink for a new or existing Bash file only' 'help should explain dual-purpose global mode'
  assert_contains "$RUN_STDOUT" '-c' 'help should document link-check mode'
  assert_contains "$RUN_STDOUT" '-r' 'help should document link-removal mode'
}

test_version_output() {
  run_capture "$MKSCRIPT_UNDER_TEST" --version
  assert_status 0 "$RUN_STATUS" 'version should exit successfully'
  assert_equals "mkscript $VERSION" "$RUN_STDOUT" 'version output should match VERSION'
}

test_overwrite_refusal() {
  local sandbox

  sandbox=$(mktemp -d)
  printf 'keep me\n' > "$sandbox/existing"
  run_capture "$MKSCRIPT_UNDER_TEST" "$sandbox/existing"
  assert_status 73 "$RUN_STATUS" 'existing files should not be overwritten'
  assert_contains "$RUN_STDERR" 'refusing to overwrite existing path' 'existing file refusal should explain the problem'
  assert_file_equals "$sandbox/existing" $'keep me\n' 'existing file should remain unchanged'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_missing_output_path() {
  run_capture "$MKSCRIPT_UNDER_TEST"
  assert_status 73 "$RUN_STATUS" 'unconfirmed default output should stop creation'
  assert_contains "$RUN_STDOUT" "No output filename was supplied. Create 'script.sh'?" 'default output should be explained'
  assert_contains "$RUN_STDERR" 'creation cancelled' 'unconfirmed default output should be cancelled'
}

test_invalid_option() {
  run_capture "$MKSCRIPT_UNDER_TEST" --bogus
  assert_status 64 "$RUN_STATUS" 'unknown options should be a usage error'
  assert_contains "$RUN_STDERR" 'unknown option: --bogus' 'unknown options should be explained'
}

test_removed_link_option_is_rejected() {
  run_capture "$MKSCRIPT_UNDER_TEST" -l test
  assert_status 64 "$RUN_STATUS" 'the removed link option should now be a usage error'
  assert_contains "$RUN_STDERR" 'unknown option: -l' 'the removed link option should be reported as unknown'
}

test_missing_parent_directory() {
  local sandbox

  sandbox=$(mktemp -d)
  run_capture "$MKSCRIPT_UNDER_TEST" "$sandbox/missing-parent/new-script"
  assert_status 73 "$RUN_STATUS" 'missing parent directory should be a create error'
  assert_contains "$RUN_STDERR" 'parent directory does not exist' 'missing parent directory should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_directory_target_refusal() {
  local sandbox

  sandbox=$(mktemp -d)
  run_capture "$MKSCRIPT_UNDER_TEST" "$sandbox"
  assert_status 73 "$RUN_STATUS" 'directories should not be overwritten'
  assert_contains "$RUN_STDERR" 'refusing to overwrite existing directory' 'directory targets should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_global_mode_with_trailing_strict_flag() {
  local sandbox
  local home_dir
  local expected_target
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  expected_target=$(cd "$sandbox" && pwd -P)/test
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -g test -s
  assert_status 0 "$RUN_STATUS" 'global mode should allow strict mode after the script name'
  assert_template_file_equals test bash test 1 'global strict script should include the default header and strict mode'
  assert_symlink_target "$expected_link" "$expected_target" 'global link should point to the created script'
  assert_contains "$RUN_STDOUT" 'Created global link:' 'global mode should report the created link'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_global_mode_with_trailing_global_flag() {
  local sandbox
  local home_dir
  local expected_target
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  expected_target=$(cd "$sandbox" && pwd -P)/test
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" test -g
  assert_status 0 "$RUN_STATUS" 'global mode should allow the global flag after the script name'
  assert_template_file_equals test bash test 0 'global mode without strict should still include the default header'
  assert_symlink_target "$expected_link" "$expected_target" 'trailing global flag should create the expected symlink'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_global_mode_refuses_existing_global_path() {
  local sandbox
  local home_dir
  local path_value
  local expected_link
  local expected_dir

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  expected_dir=$(parent_dir "$expected_link")
  mkdir -p "$expected_dir"
  printf 'busy\n' > "$expected_link"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" test -g
  assert_status 73 "$RUN_STATUS" 'global mode should refuse to overwrite an existing global path'
  assert_contains "$RUN_STDERR" 'refusing to overwrite existing global path' 'global path conflicts should be explained'
  assert_not_exists "$sandbox/test" 'global path conflicts should not create a local script'
  assert_file_equals "$expected_link" $'busy\n' 'existing global paths should remain unchanged'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_global_mode_falls_back_to_local_bin() {
  local sandbox
  local home_dir
  local expected_target
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  expected_target=$(cd "$sandbox" && pwd -P)/fallback
  path_value='/usr/bin:/bin'
  expected_link="$home_dir/.local/bin/fallback"
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" fallback -g
  assert_status 0 "$RUN_STATUS" 'global mode should fall back to ~/.local/bin when no preferred path is present'
  assert_symlink_target "$expected_link" "$expected_target" 'fallback global path should point to the created script'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_lists_matching_tree_files() {
  local sandbox
  local home_dir
  local path_value
  local global_dir

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  global_dir=$(expected_global_dir "$home_dir" "$path_value")
  mkdir -p "$home_dir" "$sandbox/bin" "$global_dir"

  printf '#!/usr/bin/env bash\n' > "$sandbox/alpha.sh"
  chmod 644 "$sandbox/alpha.sh"

  printf '#!/usr/bin/env bash\n' > "$sandbox/bin/tool"
  chmod 755 "$sandbox/bin/tool"

  printf '#!/usr/bin/env bash\n' > "$sandbox/deploy.sh"
  chmod 755 "$sandbox/deploy.sh"

  printf 'notes\n' > "$sandbox/notes.txt"
  chmod 644 "$sandbox/notes.txt"

  ln -s "$sandbox/deploy.sh" "$global_dir/deploy.sh"
  ln -s "$sandbox/notes.txt" "$global_dir/notes.txt"

  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -f
  assert_status 0 "$RUN_STATUS" 'files mode should list matching files successfully'
  assert_matches "$RUN_STDOUT" '^PATH +KIND +EXEC +GLOBAL *$' 'files mode should print a readable table header'
  assert_matches "$RUN_STDOUT" '^\./alpha\.sh +sh +no +no *$' 'files mode should include non-executable shell files'
  assert_matches "$RUN_STDOUT" '^\./bin/tool +exec +yes +no *$' 'files mode should include executable non-shell files'
  assert_matches "$RUN_STDOUT" '^\./deploy\.sh +sh\+exec +yes +yes *$' 'files mode should include globally linked executable shell files'
  assert_matches "$RUN_STDOUT" '^\./notes\.txt +file +no +yes *$' 'files mode should include global-only local files'
  assert_grep_count 1 "$RUN_STDOUT" '^\./deploy\.sh +sh\+exec +yes +yes *$' 'files mode should not duplicate files that match multiple rules'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_reports_no_matches() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  printf 'plain text\n' > README
  run_capture "$MKSCRIPT_UNDER_TEST" --files
  assert_status 0 "$RUN_STATUS" 'files mode should succeed when no matches are present'
  assert_equals "No matching script files found under '.'" "$RUN_STDOUT" 'files mode should print a clean no-match message'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_respects_depth_zero() {
  local sandbox

  sandbox=$(mktemp -d)
  mkdir -p "$sandbox/nested/deeper"
  printf '#!/usr/bin/env bash\n' > "$sandbox/root.sh"
  printf '#!/usr/bin/env bash\n' > "$sandbox/nested/child.sh"
  printf '#!/usr/bin/env bash\n' > "$sandbox/nested/deeper/grandchild.sh"

  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -f 0
  assert_status 0 "$RUN_STATUS" 'files mode should accept depth 0'
  assert_matches "$RUN_STDOUT" '^\./root\.sh +sh +no +no *$' 'depth 0 should include matching files from the current directory'
  assert_grep_count 0 "$RUN_STDOUT" '^\./nested/' 'depth 0 should exclude files from subdirectories'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_respects_depth_one() {
  local sandbox

  sandbox=$(mktemp -d)
  mkdir -p "$sandbox/nested/deeper"
  printf '#!/usr/bin/env bash\n' > "$sandbox/root.sh"
  printf '#!/usr/bin/env bash\n' > "$sandbox/nested/child.sh"
  printf '#!/usr/bin/env bash\n' > "$sandbox/nested/deeper/grandchild.sh"

  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" --files 1
  assert_status 0 "$RUN_STATUS" 'files mode should accept depth 1'
  assert_matches "$RUN_STDOUT" '^\./root\.sh +sh +no +no *$' 'depth 1 should include matching files from the current directory'
  assert_matches "$RUN_STDOUT" '^\./nested/child\.sh +sh +no +no *$' 'depth 1 should include matching files one subfolder deep'
  assert_grep_count 0 "$RUN_STDOUT" '^\./nested/deeper/' 'depth 1 should exclude files deeper than one subfolder'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_skips_unreadable_directories_quietly() {
  local sandbox
  local running_as_root=0

  sandbox=$(mktemp -d)
  mkdir -p "$sandbox/locked"
  printf '#!/usr/bin/env bash\n' > "$sandbox/root.sh"
  printf '#!/usr/bin/env bash\n' > "$sandbox/locked/hidden.sh"
  chmod 000 "$sandbox/locked"

  if [ "$(id -u)" -eq 0 ]; then
    running_as_root=1
  fi

  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -f
  chmod 700 "$sandbox/locked"

  assert_status 0 "$RUN_STATUS" 'files mode should still succeed when a subdirectory is unreadable'
  assert_grep_count 0 "$RUN_STDERR" 'Operation not permitted|Permission denied' 'files mode should suppress unreadable-directory noise'
  assert_matches "$RUN_STDOUT" '^\./root\.sh +sh +no +no *$' 'files mode should still include readable matches'

  if [ "$running_as_root" -eq 0 ]; then
    assert_grep_count 0 "$RUN_STDOUT" 'hidden\.sh' 'files mode should skip matches inside unreadable directories'
  fi

  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_rejects_invalid_depth() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -f 10
  assert_status 64 "$RUN_STATUS" 'files mode should reject invalid depth values'
  assert_contains "$RUN_STDERR" 'file listing depth must be a single digit from 0 to 9' 'files mode should explain invalid depth values'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_looks_up_name_from_arguments() {
  local sandbox
  local expected_path
  local expected_dir

  sandbox=$(mktemp -d)
  mkdir -p "$sandbox/nested"
  printf '#!/usr/bin/env bash\n' > "$sandbox/nested/lookup-target.sh"
  expected_path=$(cd "$sandbox" && pwd -P)/nested/lookup-target.sh
  expected_dir=$(cd "$sandbox" && pwd -P)/nested

  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -f lookup-target.sh
  assert_status 0 "$RUN_STATUS" 'files mode should look up names passed as arguments'
  assert_matches "$RUN_STDOUT" '^QUERY +FOUND +TYPE +LOCATION +DIRECTORY *$' 'lookup mode should print a readable table header'
  assert_contains "$RUN_STDOUT" 'lookup-target.sh' 'lookup mode should include the requested query name'
  assert_contains "$RUN_STDOUT" 'yes' 'lookup mode should mark found entries clearly'
  assert_contains "$RUN_STDOUT" 'file' 'lookup mode should identify current-tree file matches'
  assert_contains "$RUN_STDOUT" "$expected_path" 'lookup mode should print the resolved file location'
  assert_contains "$RUN_STDOUT" "$expected_dir" 'lookup mode should print the resolved parent directory'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_looks_up_name_from_stdin() {
  local sandbox
  local expected_path
  local expected_dir

  sandbox=$(mktemp -d)
  printf '#!/usr/bin/env bash\n' > "$sandbox/stdin-target.sh"
  expected_path=$(cd "$sandbox" && pwd -P)/stdin-target.sh
  expected_dir=$(cd "$sandbox" && pwd -P)

  cd "$sandbox"
  run_capture_with_input $'stdin-target.sh\n' "$MKSCRIPT_UNDER_TEST" -f
  assert_status 0 "$RUN_STATUS" 'files mode should accept lookup names from stdin'
  assert_contains "$RUN_STDOUT" 'stdin-target.sh' 'stdin lookup mode should include the requested query name'
  assert_contains "$RUN_STDOUT" "$expected_path" 'stdin lookup mode should print the resolved file location'
  assert_contains "$RUN_STDOUT" "$expected_dir" 'stdin lookup mode should print the resolved parent directory'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_looks_up_name_via_xargs() {
  local sandbox
  local expected_path
  local expected_dir

  sandbox=$(mktemp -d)
  printf '#!/usr/bin/env bash\n' > "$sandbox/xargs-target.sh"
  expected_path=$(cd "$sandbox" && pwd -P)/xargs-target.sh
  expected_dir=$(cd "$sandbox" && pwd -P)

  cd "$sandbox"
  run_capture env MKSCRIPT_UNDER_TEST="$MKSCRIPT_UNDER_TEST" bash -lc "printf '%s\n' xargs-target.sh | xargs \"\$MKSCRIPT_UNDER_TEST\" -f"
  assert_status 0 "$RUN_STATUS" 'files mode should work with xargs-fed lookup arguments'
  assert_contains "$RUN_STDOUT" 'xargs-target.sh' 'xargs lookup mode should include the requested query name'
  assert_contains "$RUN_STDOUT" "$expected_path" 'xargs lookup mode should print the resolved file location'
  assert_contains "$RUN_STDOUT" "$expected_dir" 'xargs lookup mode should print the resolved parent directory'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_looks_up_glob_name_from_arguments() {
  local sandbox
  local expected_path
  local expected_dir

  sandbox=$(mktemp -d)
  mkdir -p "$sandbox/nested"
  printf '#!/usr/bin/env bash\n' > "$sandbox/nested/install-wifi-helper.sh"
  expected_path=$(cd "$sandbox" && pwd -P)/nested/install-wifi-helper.sh
  expected_dir=$(cd "$sandbox" && pwd -P)/nested

  cd "$sandbox"
  run_capture env PATH='/usr/bin:/bin' "$MKSCRIPT_UNDER_TEST" -f 'install-wifi*'
  assert_status 0 "$RUN_STATUS" 'files mode should allow quoted glob lookup arguments'
  assert_contains "$RUN_STDOUT" 'install-wifi*' 'glob lookup mode should keep the original query text in output'
  assert_contains "$RUN_STDOUT" "$expected_path" 'glob lookup mode should resolve the matching file location'
  assert_contains "$RUN_STDOUT" "$expected_dir" 'glob lookup mode should print the matching parent directory'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_looks_up_globbed_command_from_path() {
  local sandbox
  local expected_path
  local expected_dir

  sandbox=$(mktemp -d)
  mkdir -p "$sandbox/bin"
  printf '#!/usr/bin/env bash\n' > "$sandbox/bin/install-wifi-helper"
  chmod 755 "$sandbox/bin/install-wifi-helper"
  expected_path=$(cd "$sandbox" && pwd -P)/bin/install-wifi-helper
  expected_dir=$(cd "$sandbox" && pwd -P)/bin

  cd "$sandbox"
  run_capture env PATH="$sandbox/bin:/usr/bin:/bin" "$MKSCRIPT_UNDER_TEST" -f 'install-wifi*'
  assert_status 0 "$RUN_STATUS" 'glob lookup mode should match commands on PATH'
  assert_contains "$RUN_STDOUT" 'command' 'glob lookup mode should classify PATH matches as commands'
  assert_contains "$RUN_STDOUT" "$expected_path" 'glob lookup mode should print the matched command path'
  assert_contains "$RUN_STDOUT" "$expected_dir" 'glob lookup mode should print the matched command parent directory'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_glob_lookup_falls_back_past_empty_mdfind() {
  local sandbox
  local tools_dir
  local expected_path
  local expected_dir

  sandbox=$(mktemp -d)
  tools_dir="$sandbox/tools"
  mkdir -p "$sandbox/work" "$sandbox/external" "$tools_dir"
  printf 'notes\n' > "$sandbox/external/install-wifi-notes.txt"
  expected_path=$(cd "$sandbox" && pwd -P)/external/install-wifi-notes.txt
  expected_dir=$(cd "$sandbox" && pwd -P)/external

  cat > "$tools_dir/mdfind" <<EOF
#!/usr/bin/env bash
exit 0
EOF
  cat > "$tools_dir/locate" <<EOF
#!/usr/bin/env bash
printf '%s\n' "$expected_path"
EOF
  chmod 755 "$tools_dir/mdfind" "$tools_dir/locate"

  cd "$sandbox/work"
  run_capture env PATH="$tools_dir:/usr/bin:/bin" "$MKSCRIPT_UNDER_TEST" -f 'install-wifi*'
  assert_status 0 "$RUN_STATUS" 'glob lookup mode should continue past empty mdfind results'
  assert_contains "$RUN_STDOUT" "$expected_path" 'glob lookup mode should still resolve locate fallback results'
  assert_contains "$RUN_STDOUT" "$expected_dir" 'glob lookup mode should print the locate fallback parent directory'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_returns_one_for_missing_lookup_name() {
  local sandbox
  local missing_name

  sandbox=$(mktemp -d)
  missing_name="mkscript-missing-${PPID}-$$"

  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -f "$missing_name"
  assert_status 1 "$RUN_STATUS" 'lookup mode should return 1 when a name is not found'
  assert_matches "$RUN_STDOUT" '^QUERY +FOUND +TYPE +LOCATION +DIRECTORY *$' 'missing lookup mode should keep the readable table header'
  assert_contains "$RUN_STDOUT" "$missing_name" 'missing lookup mode should include the requested query name'
  assert_contains "$RUN_STDOUT" 'missing' 'missing lookup mode should mark missing entries'
  assert_contains "$RUN_STDOUT" '-' 'missing lookup mode should use a placeholder location'
  assert_matches "$RUN_STDOUT" "${missing_name} +no +missing +- +- *$" 'missing lookup mode should use placeholders for both location columns'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_rejects_too_many_lookup_names() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -f one two three four five six seven eight nine ten
  assert_status 64 "$RUN_STATUS" 'lookup mode should reject more than nine names'
  assert_contains "$RUN_STDERR" 'lookup mode accepts at most 9 names' 'lookup mode should explain the name limit'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_rejects_depth_with_stdin_lookup() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture_with_input $'stdin-target.sh\n' "$MKSCRIPT_UNDER_TEST" -f 1
  assert_status 64 "$RUN_STATUS" 'files mode should reject mixing depth with piped lookup input'
  assert_contains "$RUN_STDERR" 'cannot combine file listing depth with lookup input' 'files mode should explain the depth/stdin lookup conflict'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_rejects_global_flag_combination() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -f -g
  assert_status 64 "$RUN_STATUS" 'files mode should reject the global flag combination'
  assert_contains "$RUN_STDERR" 'cannot combine --files with --global' 'the rejected files/global combination should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_rejects_strict_flag_combination() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" --files -s
  assert_status 64 "$RUN_STATUS" 'files mode should reject the strict flag combination'
  assert_contains "$RUN_STDERR" 'cannot combine --files with --strict' 'the rejected files/strict combination should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_rejects_check_flag_combination() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -f -c
  assert_status 64 "$RUN_STATUS" 'files mode should reject the check flag combination'
  assert_contains "$RUN_STDERR" 'cannot combine --files with -c' 'the rejected files/check combination should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_rejects_remove_flag_combination() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" --files -r
  assert_status 64 "$RUN_STATUS" 'files mode should reject the remove flag combination'
  assert_contains "$RUN_STDERR" 'cannot combine --files with -r' 'the rejected files/remove combination should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_rejects_move_flag_combination() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -f -mv source target
  assert_status 64 "$RUN_STATUS" 'files mode should reject the move flag combination'
  assert_contains "$RUN_STDERR" 'cannot combine --files with -mv' 'the rejected files/move combination should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_files_mode_rejects_template_combination() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" --files --template bash
  assert_status 64 "$RUN_STATUS" 'files mode should reject the template combination'
  assert_contains "$RUN_STDERR" 'cannot combine --files with --template' 'the rejected files/template combination should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_move_mode_preserves_permissions_without_link() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" test
  assert_status 0 "$RUN_STATUS" 'setup script creation for move mode should succeed'
  chmod 700 test

  run_capture_with_input $'y\n' "$MKSCRIPT_UNDER_TEST" -mv test deploy
  assert_status 0 "$RUN_STATUS" 'move mode should move an unlinked script successfully'
  assert_contains "$RUN_STDOUT" 'Moved script: test -> deploy' 'move mode should report the source and target paths'
  assert_not_exists test 'move mode should remove the original source path'
  assert_template_file_equals deploy bash test 0 'move mode should preserve file contents'
  assert_equals '700' "$(file_mode deploy)" 'move mode should restore the original permission mode'
  assert_executable deploy 'move mode should keep the target executable when the source was executable'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_move_mode_recreates_link_for_renamed_script() {
  local sandbox
  local home_dir
  local path_value
  local old_link
  local new_link
  local new_target

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" test -g
  assert_status 0 "$RUN_STATUS" 'setup linked script creation should succeed'

  old_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  new_link=$(expected_global_link_path "$home_dir" "$path_value" deploy)
  new_target=$(cd "$sandbox" && pwd -P)/deploy

  run_capture_with_input $'y\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -mv test deploy
  assert_status 0 "$RUN_STATUS" 'move mode should relink a renamed global script'
  assert_contains "$RUN_STDOUT" 'Moved script: test -> deploy' 'move mode should report the renamed move'
  assert_contains "$RUN_STDOUT" "Removed global link: $old_link" 'move mode should report the removed old link'
  assert_contains "$RUN_STDOUT" 'Created global link:' 'move mode should report the recreated link'
  assert_not_exists test 'move mode should remove the original source after relinking'
  assert_not_exists "$old_link" 'move mode should remove the old global link path after rename'
  assert_template_file_equals deploy bash test 0 'move mode should preserve the original script file contents when renaming'
  assert_symlink_target "$new_link" "$new_target" 'move mode should create a new global link for the target name'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_move_mode_updates_link_for_same_basename_in_new_directory() {
  local sandbox
  local home_dir
  local path_value
  local link_path
  local new_target

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  mkdir -p "$home_dir" "$sandbox/scripts"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" test -g
  assert_status 0 "$RUN_STATUS" 'setup linked script creation for same-basename move should succeed'

  link_path=$(expected_global_link_path "$home_dir" "$path_value" test)
  new_target=$(cd "$sandbox" && pwd -P)/scripts/test

  run_capture_with_input $'y\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -mv test scripts/test
  assert_status 0 "$RUN_STATUS" 'move mode should support keeping the same basename in a new directory'
  assert_contains "$RUN_STDOUT" "Removed global link: $link_path" 'same-basename move should report the removed old link'
  assert_symlink_target "$link_path" "$new_target" 'same-basename move should recreate the same global link path against the new file location'
  assert_not_exists test 'same-basename move should remove the original source path'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_move_mode_creates_new_link_with_global_flag() {
  local sandbox
  local home_dir
  local path_value
  local new_link
  local new_target

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" test
  assert_status 0 "$RUN_STATUS" 'setup unlinked script creation should succeed'

  new_link=$(expected_global_link_path "$home_dir" "$path_value" deploy)
  new_target=$(cd "$sandbox" && pwd -P)/deploy

  run_capture_with_input $'y\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -mv test deploy -g
  assert_status 0 "$RUN_STATUS" 'move mode should allow -g to create a new global link'
  assert_symlink_target "$new_link" "$new_target" 'move mode with -g should create the expected new global link'
  assert_executable deploy 'move mode with -g should make the target executable'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_move_mode_moves_into_directory_with_global_flag() {
  local sandbox
  local home_dir
  local path_value
  local link_path
  local source
  local target

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  mkdir -p "$home_dir" "$sandbox/myscripts"
  cd "$sandbox"
  printf '#!/usr/bin/env bash\n' > myfile
  chmod 644 myfile
  link_path=$(expected_global_link_path "$home_dir" "$path_value" myfile)
  source=$(cd "$sandbox" && pwd -P)/myfile
  target=$(cd "$sandbox" && pwd -P)/myscripts/myfile

  run_capture_with_input $'yes\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -mv -g myfile myscripts
  assert_status 0 "$RUN_STATUS" 'move mode should allow an existing directory target'
  assert_contains "$RUN_STDOUT" "Are you sure you want to move '$source' to '$target'?" 'move confirmation should show fully resolved paths'
  assert_not_exists myfile 'directory-target move should remove the source path'
  assert_file_equals myscripts/myfile $'#!/usr/bin/env bash\n' 'directory-target move should retain the source basename and contents'
  assert_executable myscripts/myfile 'directory-target move with -g should make the target executable'
  assert_symlink_target "$link_path" "$target" 'directory-target move should create a global link for the retained basename'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_move_mode_refuses_conflicting_directory_target() {
  local sandbox

  sandbox=$(mktemp -d)
  mkdir -p "$sandbox/myscripts"
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" myfile
  assert_status 0 "$RUN_STATUS" 'setup script creation for directory-target conflict should succeed'
  printf 'busy\n' > myscripts/myfile

  run_capture "$MKSCRIPT_UNDER_TEST" -mv myfile myscripts
  assert_status 73 "$RUN_STATUS" 'move mode should reject an existing resolved directory target'
  assert_contains "$RUN_STDERR" 'refusing to overwrite existing path: myscripts/myfile' 'directory-target conflicts should name the resolved target'
  assert_template_file_equals myfile bash myfile 0 'directory-target conflicts should leave the source unchanged'
  assert_file_equals myscripts/myfile $'busy\n' 'directory-target conflicts should not overwrite the destination'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_move_mode_cancellation_leaves_paths_unchanged() {
  local sandbox
  local source

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" myfile
  assert_status 0 "$RUN_STATUS" 'setup script creation for move cancellation should succeed'
  source=$(cd "$sandbox" && pwd -P)/myfile

  run_capture_with_input $'n\n' "$MKSCRIPT_UNDER_TEST" -mv myfile deploy
  assert_status 73 "$RUN_STATUS" 'move mode should stop when confirmation is denied'
  assert_contains "$RUN_STDERR" "move cancelled: $source" 'denied move confirmation should be explained'
  assert_template_file_equals myfile bash myfile 0 'denied move confirmation should leave the source unchanged'
  assert_not_exists deploy 'denied move confirmation should not create the target'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_move_mode_rejects_missing_source() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -mv missing deploy
  assert_status 73 "$RUN_STATUS" 'move mode should reject missing source paths'
  assert_contains "$RUN_STDERR" 'cannot move missing path' 'missing move sources should be explained'
  assert_not_exists deploy 'missing move sources should not create a target file'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_move_mode_rejects_directory_source() {
  local sandbox

  sandbox=$(mktemp -d)
  mkdir -p "$sandbox/testdir"
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -mv testdir deploy
  assert_status 73 "$RUN_STATUS" 'move mode should reject directory sources'
  assert_contains "$RUN_STDERR" 'cannot move a directory' 'directory move sources should be explained'
  assert_not_exists deploy 'directory move sources should not create a target file'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_move_mode_rejects_existing_target() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" test
  assert_status 0 "$RUN_STATUS" 'setup script creation for target-conflict move test should succeed'
  printf 'busy\n' > deploy

  run_capture "$MKSCRIPT_UNDER_TEST" -mv test deploy
  assert_status 73 "$RUN_STATUS" 'move mode should reject existing target paths'
  assert_contains "$RUN_STDERR" 'refusing to overwrite existing path' 'existing move targets should be explained'
  assert_not_exists "$sandbox/deploy.tmp" 'move mode should not create any extra file while target validation fails'
  assert_executable test 'existing target conflicts should leave the source script untouched'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_move_mode_rejects_existing_target_global_path() {
  local sandbox
  local home_dir
  local path_value
  local old_link
  local conflicting_link
  local conflicting_dir
  local original_target

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" test -g
  assert_status 0 "$RUN_STATUS" 'setup linked script creation for target-link conflict should succeed'

  old_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  conflicting_link=$(expected_global_link_path "$home_dir" "$path_value" deploy)
  conflicting_dir=$(parent_dir "$conflicting_link")
  original_target=$(cd "$sandbox" && pwd -P)/test
  mkdir -p "$conflicting_dir"
  printf 'busy\n' > "$conflicting_link"

  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -mv test deploy
  assert_status 73 "$RUN_STATUS" 'move mode should reject existing target global paths'
  assert_contains "$RUN_STDERR" 'refusing to overwrite existing global path' 'target global link conflicts should be explained'
  if [ ! -f test ]; then
    fail 'target global link conflicts should leave the source file in place'
  fi
  assert_symlink_target "$old_link" "$original_target" 'target global link conflicts should leave the old global link untouched'
  assert_file_equals "$conflicting_link" $'busy\n' 'target global link conflicts should not overwrite the conflicting global path'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_move_mode_rejects_strict_flag_combination() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -mv test deploy -s
  assert_status 64 "$RUN_STATUS" 'move mode should reject the strict flag combination'
  assert_contains "$RUN_STDERR" 'cannot combine -mv with --strict' 'the rejected move/strict combination should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_move_mode_rejects_check_flag_combination() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -mv test deploy -c
  assert_status 64 "$RUN_STATUS" 'move mode should reject the check flag combination'
  assert_contains "$RUN_STDERR" 'cannot combine -mv with -c' 'the rejected move/check combination should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_move_mode_rejects_remove_flag_combination() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -mv test deploy -r
  assert_status 64 "$RUN_STATUS" 'move mode should reject the remove flag combination'
  assert_contains "$RUN_STDERR" 'cannot combine -mv with -r' 'the rejected move/remove combination should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_move_mode_rejects_terraform_template() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -mv test deploy --template terraform
  assert_status 64 "$RUN_STATUS" 'move mode should reject the terraform template'
  assert_contains "$RUN_STDERR" '-mv is only supported with the bash template' 'the rejected move/terraform combination should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_move_mode_rejects_ansible_template() {
  local sandbox

  sandbox=$(mktemp -d)
  cd "$sandbox"
  run_capture "$MKSCRIPT_UNDER_TEST" -mv test deploy --template ansible
  assert_status 64 "$RUN_STATUS" 'move mode should reject the ansible template'
  assert_contains "$RUN_STDERR" '-mv is only supported with the bash template' 'the rejected move/ansible combination should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_global_mode_links_existing_file() {
  local sandbox
  local home_dir
  local expected_target
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  expected_target=$(cd "$sandbox" && pwd -P)/test
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$home_dir"
  printf '#!/usr/bin/env bash\n' > "$sandbox/test"
  chmod 755 "$sandbox/test"
  cd "$sandbox"
  run_capture_with_input $'y\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -g test
  assert_status 0 "$RUN_STATUS" 'global mode should link an existing file after confirmation'
  assert_contains "$RUN_STDOUT" "Are you sure you want to link source path 'test' to '$expected_link'?" 'global mode should prompt before linking an existing file'
  assert_symlink_target "$expected_link" "$expected_target" 'global mode should create the expected symlink for an existing file'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_global_mode_links_existing_file_with_trailing_flag() {
  local sandbox
  local home_dir
  local expected_target
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  expected_target=$(cd "$sandbox" && pwd -P)/test.sh
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test.sh)
  mkdir -p "$home_dir"
  printf '#!/usr/bin/env bash\n' > "$sandbox/test.sh"
  chmod 755 "$sandbox/test.sh"
  cd "$sandbox"
  run_capture_with_input $'yes\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" test.sh -g
  assert_status 0 "$RUN_STATUS" 'global mode should allow the global flag after an existing path'
  assert_contains "$RUN_STDOUT" "Are you sure you want to link source path 'test.sh' to '$expected_link'?" 'trailing global flag should still prompt for confirmation when the path exists'
  assert_symlink_target "$expected_link" "$expected_target" 'trailing global flag should create the expected symlink for an existing file'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_global_mode_refuses_existing_global_path_for_existing_file() {
  local sandbox
  local home_dir
  local path_value
  local expected_link
  local expected_dir

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  expected_dir=$(parent_dir "$expected_link")
  mkdir -p "$expected_dir"
  printf '#!/usr/bin/env bash\n' > "$sandbox/test"
  chmod 755 "$sandbox/test"
  printf 'busy\n' > "$expected_link"
  cd "$sandbox"
  run_capture_with_input $'y\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -g test
  assert_status 73 "$RUN_STATUS" 'global mode should refuse to overwrite an existing global path when linking an existing file'
  assert_contains "$RUN_STDERR" 'refusing to overwrite existing global path' 'existing global paths should be explained for existing-file global mode'
  assert_file_equals "$expected_link" $'busy\n' 'existing global paths should remain unchanged in existing-file global mode'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_global_mode_existing_file_cancellation_refuses_to_link() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$home_dir"
  printf '#!/usr/bin/env bash\n' > "$sandbox/test"
  chmod 755 "$sandbox/test"
  cd "$sandbox"
  run_capture_with_input $'n\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -g test
  assert_status 73 "$RUN_STATUS" 'global mode should stop when existing-file link confirmation is denied'
  assert_contains "$RUN_STDERR" 'link cancelled' 'denied confirmation should be explained'
  assert_not_exists "$expected_link" 'denied confirmation should not create a global link'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_global_mode_rejects_strict_for_existing_file() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$home_dir"
  printf '#!/usr/bin/env bash\n' > "$sandbox/test"
  chmod 755 "$sandbox/test"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" test -g -s
  assert_status 64 "$RUN_STATUS" 'global mode should reject strict mode when linking an existing file'
  assert_contains "$RUN_STDERR" 'cannot combine --strict with --global when linking an existing path' 'existing-file global mode should explain the strict-mode rejection'
  assert_not_exists "$expected_link" 'invalid strict/existing-file global combinations should not create a global link'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_check_mode_reports_existing_link() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$(parent_dir "$expected_link")"
  ln -s "$sandbox/test" "$expected_link"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -c test
  assert_status 0 "$RUN_STATUS" 'check mode should succeed when the global link exists'
  assert_contains "$RUN_STDOUT" "$expected_link" 'check mode should print the global link path when it exists'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_check_mode_reports_missing_link_with_trailing_flag() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" test -c
  assert_status 1 "$RUN_STATUS" 'check mode should return 1 when the global link is missing'
  assert_contains "$RUN_STDOUT" "$expected_link" 'check mode should report the checked path when the link is missing'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_check_mode_refuses_non_symlink_global_path() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$(parent_dir "$expected_link")"
  printf 'busy\n' > "$expected_link"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -c test
  assert_status 73 "$RUN_STATUS" 'check mode should refuse non-symlink global paths'
  assert_contains "$RUN_STDERR" 'global path exists but is not a symlink' 'check mode should explain conflicting non-symlink global paths'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_check_mode_rejects_global_flag_combination() {
  local sandbox
  local home_dir
  local path_value

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -c test -g
  assert_status 64 "$RUN_STATUS" 'check mode should reject the global flag combination'
  assert_contains "$RUN_STDERR" 'cannot combine -c with --global' 'the rejected check/global combination should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_remove_mode_removes_existing_link() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$(parent_dir "$expected_link")"
  ln -s "$sandbox/test" "$expected_link"
  cd "$sandbox"
  run_capture_with_input $'y\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -r test
  assert_status 0 "$RUN_STATUS" 'remove mode should remove an existing global link after confirmation'
  assert_contains "$RUN_STDOUT" "Are you sure you want to remove link for 'test' from '$expected_link'?" 'remove mode should prompt before deleting a link'
  assert_contains "$RUN_STDOUT" "Removed link for 'test' from '$expected_link'" 'remove mode should report the removed link path'
  assert_not_exists "$expected_link" 'remove mode should delete the symlink after confirmation'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_remove_mode_removes_existing_link_with_trailing_flag() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$(parent_dir "$expected_link")"
  ln -s "$sandbox/test" "$expected_link"
  cd "$sandbox"
  run_capture_with_input $'yes\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" test -r
  assert_status 0 "$RUN_STATUS" 'remove mode should allow the remove flag after the target'
  assert_not_exists "$expected_link" 'trailing remove flag should delete the symlink'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_remove_mode_reports_missing_link() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -r test
  assert_status 1 "$RUN_STATUS" 'remove mode should return 1 when no global link exists'
  assert_contains "$RUN_STDOUT" "$expected_link" 'remove mode should report the missing link path'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_remove_mode_refuses_non_symlink_global_path() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$(parent_dir "$expected_link")"
  printf 'busy\n' > "$expected_link"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -r test
  assert_status 73 "$RUN_STATUS" 'remove mode should refuse non-symlink global paths'
  assert_contains "$RUN_STDERR" 'global path exists but is not a symlink' 'remove mode should explain conflicting non-symlink global paths'
  assert_file_equals "$expected_link" $'busy\n' 'remove mode should leave regular files untouched'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_remove_mode_cancellation_refuses_to_delete() {
  local sandbox
  local home_dir
  local path_value
  local expected_link

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  expected_link=$(expected_global_link_path "$home_dir" "$path_value" test)
  mkdir -p "$(parent_dir "$expected_link")"
  ln -s "$sandbox/test" "$expected_link"
  cd "$sandbox"
  run_capture_with_input $'n\n' env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -r test
  assert_status 73 "$RUN_STATUS" 'remove mode should stop when confirmation is denied'
  assert_contains "$RUN_STDERR" 'link removal cancelled' 'denied confirmation should be explained for remove mode'
  if [ ! -L "$expected_link" ]; then
    fail 'denied confirmation should leave the symlink in place'
  fi
  cd "$START_DIR"
  rm -rf "$sandbox"
}

test_remove_mode_rejects_strict_flag_combination() {
  local sandbox
  local home_dir
  local path_value

  sandbox=$(mktemp -d)
  home_dir="$sandbox/home"
  path_value=$(default_global_test_path "$home_dir")
  mkdir -p "$home_dir"
  cd "$sandbox"
  run_capture env HOME="$home_dir" PATH="$path_value" "$MKSCRIPT_UNDER_TEST" -r test -s
  assert_status 64 "$RUN_STATUS" 'remove mode should reject the strict flag combination'
  assert_contains "$RUN_STDERR" 'cannot combine -r with --strict' 'the rejected remove/strict combination should be explained'
  cd "$START_DIR"
  rm -rf "$sandbox"
}

run_test() {
  local name=$1

  tests_run=$((tests_run + 1))
  "$name"
  printf 'PASS: %s\n' "$name"
}

run_test test_plain_script_creation
run_test test_template_target_defaults_and_helm
run_test test_short_strict_mode
run_test test_long_strict_mode_with_absolute_path
run_test test_terraform_template_creation
run_test test_terraform_template_creation_with_trailing_flag
run_test test_ansible_template_creation
run_test test_ansible_template_creation_with_trailing_flag
run_test test_additional_template_creation
run_test test_additional_template_creation_with_trailing_flag
run_test test_terraform_template_rejects_strict_flag
run_test test_ansible_template_rejects_strict_flag
run_test test_additional_templates_reject_strict_flag
run_test test_terraform_template_rejects_global_flag
run_test test_ansible_template_rejects_global_flag
run_test test_additional_templates_reject_global_flag
run_test test_invalid_template_value
run_test test_help_output
run_test test_version_output
run_test test_overwrite_refusal
run_test test_missing_output_path
run_test test_invalid_option
run_test test_removed_link_option_is_rejected
run_test test_missing_parent_directory
run_test test_directory_target_refusal
run_test test_global_mode_with_trailing_strict_flag
run_test test_global_mode_with_trailing_global_flag
run_test test_global_mode_refuses_existing_global_path
run_test test_global_mode_falls_back_to_local_bin
run_test test_files_mode_lists_matching_tree_files
run_test test_files_mode_reports_no_matches
run_test test_files_mode_respects_depth_zero
run_test test_files_mode_respects_depth_one
run_test test_files_mode_skips_unreadable_directories_quietly
run_test test_files_mode_rejects_invalid_depth
run_test test_files_mode_looks_up_name_from_arguments
run_test test_files_mode_looks_up_name_from_stdin
run_test test_files_mode_looks_up_name_via_xargs
run_test test_files_mode_looks_up_glob_name_from_arguments
run_test test_files_mode_looks_up_globbed_command_from_path
run_test test_files_mode_glob_lookup_falls_back_past_empty_mdfind
run_test test_files_mode_returns_one_for_missing_lookup_name
run_test test_files_mode_rejects_too_many_lookup_names
run_test test_files_mode_rejects_depth_with_stdin_lookup
run_test test_files_mode_rejects_global_flag_combination
run_test test_files_mode_rejects_strict_flag_combination
run_test test_files_mode_rejects_check_flag_combination
run_test test_files_mode_rejects_remove_flag_combination
run_test test_files_mode_rejects_move_flag_combination
run_test test_files_mode_rejects_template_combination
run_test test_move_mode_preserves_permissions_without_link
run_test test_move_mode_recreates_link_for_renamed_script
run_test test_move_mode_updates_link_for_same_basename_in_new_directory
run_test test_move_mode_creates_new_link_with_global_flag
run_test test_move_mode_moves_into_directory_with_global_flag
run_test test_move_mode_refuses_conflicting_directory_target
run_test test_move_mode_cancellation_leaves_paths_unchanged
run_test test_move_mode_rejects_missing_source
run_test test_move_mode_rejects_directory_source
run_test test_move_mode_rejects_existing_target
run_test test_move_mode_rejects_existing_target_global_path
run_test test_move_mode_rejects_strict_flag_combination
run_test test_move_mode_rejects_check_flag_combination
run_test test_move_mode_rejects_remove_flag_combination
run_test test_move_mode_rejects_terraform_template
run_test test_move_mode_rejects_ansible_template
run_test test_global_mode_links_existing_file
run_test test_global_mode_links_existing_file_with_trailing_flag
run_test test_global_mode_refuses_existing_global_path_for_existing_file
run_test test_global_mode_existing_file_cancellation_refuses_to_link
run_test test_global_mode_rejects_strict_for_existing_file
run_test test_check_mode_reports_existing_link
run_test test_check_mode_reports_missing_link_with_trailing_flag
run_test test_check_mode_refuses_non_symlink_global_path
run_test test_check_mode_rejects_global_flag_combination
run_test test_remove_mode_removes_existing_link
run_test test_remove_mode_removes_existing_link_with_trailing_flag
run_test test_remove_mode_reports_missing_link
run_test test_remove_mode_refuses_non_symlink_global_path
run_test test_remove_mode_cancellation_refuses_to_delete
run_test test_remove_mode_rejects_strict_flag_combination

printf 'All %s tests passed.\n' "$tests_run"
