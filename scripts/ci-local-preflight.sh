#!/usr/bin/env bash
# Local Codemagic / mobile-validate equivalent (must pass before push).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== Resolve pub dependencies =="
mapfile -t dirs < <(find . -name pubspec.yaml -not -path '*/.*' -exec dirname {} \;)
echo "packages: ${#dirs[@]}"
for dir in "${dirs[@]}"; do
  echo "== pub get $dir =="
  (cd "$dir" && flutter pub get)
done

echo "== build_runner where declared =="
for dir in "${dirs[@]}"; do
  if grep -q build_runner "$dir/pubspec.yaml"; then
    echo "== build_runner $dir =="
    (cd "$dir" && dart run build_runner build --delete-conflicting-outputs)
  fi
done

echo "== flutter analyze (am_app) =="
(cd am_app && flutter analyze --no-fatal-infos)

if [ -d am_app/test ]; then
  echo "== flutter test (am_app) =="
  (cd am_app && rm -rf build && mkdir -p build && flutter test)
else
  echo "No am_app/test — skip flutter test"
fi

echo "== flutter build web --release =="
(cd am_app && flutter build web --release \
  --dart-define=AM_DOMAIN=am-preprod.asrax.in \
  --dart-define=AM_ENV=preprod)

echo "== flutter build appbundle --release =="
(cd am_app && flutter build appbundle --release \
  --build-name=2.0.0 \
  --build-number=1 \
  --dart-define=AM_DOMAIN=am.asrax.in \
  --dart-define=AM_ENV=prod)

echo "LOCAL_PREFLIGHT_OK"
