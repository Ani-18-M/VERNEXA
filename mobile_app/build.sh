#!/bin/bash
set -e

echo "=== VERNEXA Build: mobile_app ==="

if command -v flutter &> /dev/null; then
  echo "Using installed Flutter: $(flutter --version | head -n 1)"
elif [ -d "$HOME/flutter/bin" ]; then
  echo "Using existing Flutter in $HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
else
  echo "Installing Flutter SDK (stable channel)..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
  flutter config --no-analytics
fi

flutter pub get
flutter build web --release --no-wasm-dry-run

echo "=== Build finished: build/web ready ==="
