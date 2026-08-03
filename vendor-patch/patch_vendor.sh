#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PATCH_DIR="$ROOT/vendor-patch"
EXPECTED_SHA256="609385bbd8cc20b079f8a606039be171da84e7bf6e1a67752298e45c00e944b1"
INPUT="${1:-}"
OUTPUT="${2:-$PATCH_DIR/output/vendor-a50-multidisabled.img}"
RAW="$PATCH_DIR/source/vendor.ext"

if [[ -z "$INPUT" ]]; then
    echo "Usage: $0 <stock-vendor.img> [output-vendor.img]" >&2
    exit 1
fi

for tool in 7z debugfs e2fsck sha256sum; do
    command -v "$tool" >/dev/null || {
        echo "Missing required tool: $tool" >&2
        exit 1
    }
done

[[ -f "$INPUT" ]] || {
    echo "Input image not found: $INPUT" >&2
    exit 1
}

ACTUAL_SHA256="$(sha256sum "$INPUT" | awk '{print $1}')"
[[ "$ACTUAL_SHA256" == "$EXPECTED_SHA256" ]] || {
    echo "Unsupported vendor image." >&2
    echo "Expected SHA-256: $EXPECTED_SHA256" >&2
    echo "Actual SHA-256:   $ACTUAL_SHA256" >&2
    exit 1
}

mkdir -p "$PATCH_DIR/source" "$(dirname "$OUTPUT")"
rm -f "$RAW" "$OUTPUT"

7z x -y -tSparse "$INPUT" "-o$PATCH_DIR/source" >/dev/null
[[ -f "$RAW" ]] || {
    echo "Sparse vendor extraction failed." >&2
    exit 1
}

cp --reflink=auto "$RAW" "$OUTPUT"
cd "$ROOT"
debugfs -w -f vendor-patch/debugfs.cmd "$OUTPUT" >/dev/null
e2fsck -fy "$OUTPUT" >/dev/null

debugfs -R 'cat /build.prop' "$OUTPUT" 2>/dev/null \
    | grep -q '^ro.product.vendor.device=a50$' || {
        echo "Output device verification failed." >&2
        exit 1
    }

debugfs -R 'cat /etc/fstab.exynos9610' "$OUTPUT" 2>/dev/null \
    | grep -q 'wait,check,encryptable,quota' || {
        echo "FBE patch verification failed." >&2
        exit 1
    }

echo "Patched vendor created: $OUTPUT"
echo "SHA-256: $(sha256sum "$OUTPUT" | awk '{print $1}')"
echo "Format: raw ext4 image, 800 MiB"
