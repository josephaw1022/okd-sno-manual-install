#!/bin/bash
# Deny kubectl/oc delete commands unless they explicitly disable interactive mode.

input=$(cat)
command=$(echo "$input" | jq -r '.command // empty')

allow() {
  echo '{ "permission": "allow" }'
  exit 0
}

deny() {
  cat <<'EOF'
{
  "permission": "deny",
  "user_message": "kubectl/oc delete blocked: include -i false or --interactive false to confirm non-interactive deletion.",
  "agent_message": "This kubectl/oc delete command was blocked by a safety hook. Re-run with -i false or --interactive false (or --interactive=false)."
}
EOF
  exit 0
}

[[ -z "$command" ]] && allow

has_noninteractive_flag() {
  local segment="$1"
  [[ "$segment" =~ (^|[[:space:]])-i([[:space:]]|=)false([[:space:]]|$) ]] && return 0
  [[ "$segment" =~ (^|[[:space:]])--interactive([[:space:]]|=)false([[:space:]]|$) ]] && return 0
  return 1
}

is_kubectl_oc_delete() {
  local segment="$1"
  local rest=""

  if [[ ! "$segment" =~ (^|[[:space:]])(kubectl|oc)([[:space:]]|$) ]]; then
    return 1
  fi

  if [[ "$segment" =~ (^|[[:space:]])(kubectl|oc)([[:space:]]+.*)$ ]]; then
    rest="${BASH_REMATCH[3]}"
  else
    return 1
  fi

  local token skip_next=0
  for token in $rest; do
    if (( skip_next )); then
      skip_next=0
      continue
    fi

    if [[ "$token" == -* ]]; then
      if [[ "$token" == --*=* ]]; then
        continue
      fi
      case "$token" in
        -n|--namespace|-c|--context|--kubeconfig|--server|--token|--user|--cluster|--as|--as-group|--field-selector|--label-selector|-l|--selector|--grace-period|--timeout|--wait|--force|--output|-o)
          skip_next=1
          ;;
      esac
      continue
    fi

    [[ "$token" == "delete" ]] && return 0
    return 1
  done

  return 1
}

while IFS= read -r segment; do
  segment="${segment#"${segment%%[![:space:]]*}"}"
  segment="${segment%"${segment##*[![:space:]]}"}"
  [[ -z "$segment" ]] && continue

  # Ignore env assignments at the start (e.g. KUBECONFIG=... kubectl delete ...)
  while [[ "$segment" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; do
    segment="${segment#*=}"
    segment="${segment#"${segment%%[![:space:]]*}"}"
  done

  # Only inspect the first command in a pipeline.
  segment="${segment%%|*}"

  if is_kubectl_oc_delete "$segment"; then
    if has_noninteractive_flag "$segment"; then
      continue
    fi
    deny
  fi
done < <(printf '%s\n' "$command" | sed 's/&&/\n/g; s/||/\n/g; s/;/\n/g')

allow
