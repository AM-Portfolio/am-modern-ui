#!/usr/bin/env bash
# Codemagic / CI: run build_runner with skip-on-cache-hit.
# Pair with codemagic.yaml cache.cache_paths → $CM_BUILD_DIR/.cm_codegen_cache
# and ~/.pub-cache so pub + incremental graph stay warm.
set -euo pipefail

ROOT="${CM_BUILD_DIR:-$(pwd)}"
cd "$ROOT"
CACHE_DIR="${ROOT}/.cm_codegen_cache"
mkdir -p "$CACHE_DIR"

# Packages that declare build_runner (keep in sync with monorepo)
PKG_DIRS=(
  am_trade_ui
  am_market/ui
  am_portfolio_ui
  am_dashboard_ui
  am_market/common
  am_design_system
  am_common
  am_auth_ui
  am_subscription_ui
  am_doc_intelligence_ui
  am_analysis/common
  am_auth_ui/live
)

fingerprint() {
  # Inputs that affect codegen — exclude generated outputs (fast path hashes)
  {
    for d in "${PKG_DIRS[@]}"; do
      [ -f "$d/pubspec.yaml" ] && shasum -a 256 "$d/pubspec.yaml"
      [ -f "$d/pubspec.lock" ] && shasum -a 256 "$d/pubspec.lock"
      if [ -d "$d" ]; then
        find "$d" -type f -name '*.dart' \
          ! -name '*.freezed.dart' \
          ! -name '*.g.dart' \
          ! -name '*.config.dart' \
          ! -path '*/.dart_tool/*' \
          ! -path '*/build/*' \
          -print0 2>/dev/null | sort -z | xargs -0 shasum -a 256 2>/dev/null
      fi
    done
  } | shasum -a 256 | awk '{print $1}'
}

restore_outputs() {
  if [ -f "$CACHE_DIR/generated.tar.gz" ]; then
    echo "Restoring generated sources from Codemagic cache..."
    tar -xzf "$CACHE_DIR/generated.tar.gz" -C "$ROOT"
  fi
}

save_outputs() {
  echo "Saving generated sources into Codemagic cache..."
  # shellcheck disable=SC2046
  tar -czf "$CACHE_DIR/generated.tar.gz" \
    $(find "${PKG_DIRS[@]}" -type f \( -name '*.freezed.dart' -o -name '*.g.dart' -o -name '*.config.dart' \) 2>/dev/null | sort) \
    2>/dev/null || true
  fingerprint > "$CACHE_DIR/fingerprint"
  echo "Cache fingerprint=$(cat "$CACHE_DIR/fingerprint")"
}

verify_critical() {
  test -f am_portfolio_ui/lib/features/basket/domain/models/basket_detail.freezed.dart
  grep -q "coversEtfSymbol" am_portfolio_ui/lib/features/basket/domain/models/basket_detail.freezed.dart
  echo "Freezed BasketLineDetail getters OK"
}

FP_NOW="$(fingerprint)"
echo "codegen fingerprint=$FP_NOW"

restore_outputs

if [ -f "$CACHE_DIR/fingerprint" ] && [ "$(cat "$CACHE_DIR/fingerprint")" = "$FP_NOW" ]; then
  if test -f am_portfolio_ui/lib/features/basket/domain/models/basket_detail.freezed.dart \
    && grep -q "coversEtfSymbol" am_portfolio_ui/lib/features/basket/domain/models/basket_detail.freezed.dart; then
    echo "CODEGEN CACHE HIT — skipping build_runner"
    verify_critical
    exit 0
  fi
  echo "Cache fingerprint matched but critical outputs missing — regenerating"
fi

echo "CODEGEN CACHE MISS — running build_runner"
for dir in "${PKG_DIRS[@]}"; do
  if [ -f "$dir/pubspec.yaml" ] && grep -q "build_runner" "$dir/pubspec.yaml"; then
    echo "Running build_runner in $dir..."
    (cd "$dir" && dart run build_runner build --delete-conflicting-outputs)
  fi
done

verify_critical
save_outputs
