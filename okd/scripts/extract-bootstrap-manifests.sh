#!/usr/bin/env bash
set -euo pipefail

IGN="sno/bootstrap-in-place-for-live-iso.ign"
OUT="./_extracted"
MAN="$OUT/manifests"
OCP="$OUT/openshift"

[ -f "$IGN" ] || { echo "Missing $IGN"; exit 1; }

mkdir -p "$MAN" "$OCP"

# jq selects files under /opt/openshift/{manifests,openshift}
jq -r '.storage.files[]
  | select(.path | startswith("/opt/openshift/manifests/") or startswith("/opt/openshift/openshift/"))
  | [.path, .contents.source] | @tsv' "$IGN" | while IFS=$'\t' read -r path source; do
  # data URLs look like: data:text/plain;charset=utf-8;base64,<blob>
  b64="${source#data:text/plain;charset=utf-8;base64,}"
  b64="${b64#data:;base64,}"

  rel="${path#/opt/openshift/}"
  out="$OUT/$rel"
  outdir="$(dirname "$out")"
  mkdir -p "$outdir"

  # Try gunzip (most payloads are gzipped), fall back to raw base64 if not gzipped
  if echo "$b64" | base64 -d 2>/dev/null | gzip -t 2>/dev/null; then
    echo "$b64" | base64 -d | gunzip > "$out"
  else
    echo "$b64" | base64 -d > "$out"
  fi

  # If the result is a tarball or archive (rare), just leave it; most are YAMLs.
  echo "Wrote $out"
done

echo
echo "Done. Inspect:"
echo "  $MAN"
echo "  $OCP"
