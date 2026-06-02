#!/bin/bash
# amalgame-hal — test runner. Pure-Amalgame interface package; the test
# implements an interface and dispatches through it (needs amc 0.8.72+).
set -u

if [ $# -ge 1 ]; then AMC="$1"
elif [ -n "${AMC:-}" ]; then :
elif command -v amc >/dev/null 2>&1; then AMC="$(command -v amc)"
else echo "ERROR: amc not found." >&2; exit 2; fi
[ -x "$AMC" ] || { echo "ERROR: amc not executable: $AMC" >&2; exit 2; }
AMC="$(cd "$(dirname "$AMC")" && pwd)/$(basename "$AMC")"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
AMC_DIR="$(cd "$(dirname "$AMC")" && pwd)"
if   [ -d "$AMC_DIR/runtime" ]; then AMC_RUNTIME="$AMC_DIR/runtime"
elif [ -d "$AMC_DIR/../share/amalgame/runtime" ]; then AMC_RUNTIME="$(cd "$AMC_DIR/../share/amalgame/runtime" && pwd)"
elif [ -n "${AMC_RUNTIME:-}" ]; then :
else echo "ERROR: amc runtime/ not found." >&2; exit 2; fi
if   [ -f "$AMC_DIR/lib/libamalgame.a" ]; then LIBA="$AMC_DIR/lib/libamalgame.a"
elif [ -f "$AMC_DIR/../share/amalgame/lib/libamalgame.a" ]; then LIBA="$(cd "$AMC_DIR/../share/amalgame/lib" && pwd)/libamalgame.a"
else echo "ERROR: libamalgame.a not found." >&2; exit 2; fi

BUILD="$(mktemp -d)"; trap 'rm -rf "$BUILD"' EXIT
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
echo "amalgame-hal — $("$AMC" --version 2>&1 | head -1)"

# Smoke: the interface facade must compile to C.
"$AMC" --lib --quiet "$PKG_ROOT/facade.am" -o "$BUILD/hal" || { echo "facade compile FAILED"; exit 1; }
echo "  facade compiles"

# Resolve amalgame-hal against itself via a fake cache + lock so the
# test's `import Amalgame.Hal` resolves.
CACHE="$BUILD/cache"; PKG="github.com/amalgame-lang/amalgame-hal"
mkdir -p "$CACHE/$PKG"; ln -s "$PKG_ROOT" "$CACHE/$PKG/v0.1.0_deadbeef"
PROJ="$BUILD/proj"; mkdir -p "$PROJ"
cat > "$PROJ/amalgame.lock" <<EOF
[[package]]
name = "amalgame-hal"
git  = "$PKG"
tag  = "v0.1.0"
rev  = "deadbeefcafebabe0000000000000000000000ab"
EOF
export AMALGAME_PACKAGES_DIR="$CACHE"
cp "$SCRIPT_DIR/stdlib_hal.am" "$PROJ/test.am"
if (cd "$PROJ" && "$AMC" --quiet -o test test.am) \
   && gcc -O2 -I"$AMC_RUNTIME" -w "$PROJ/test.c" "$LIBA" -lgc -lm -lz -ldl -lpthread -o "$PROJ/test"; then
    OUT="$("$PROJ/test" 2>&1)"; echo "  $OUT"
    if echo "$OUT" | grep -q '\[FAIL\]'; then echo -e "${RED}TESTS FAILED${NC}"; exit 1; fi
else
    echo -e "${RED}build FAILED${NC}"; exit 1
fi
echo -e "${GREEN}ALL TESTS PASSED${NC}"
