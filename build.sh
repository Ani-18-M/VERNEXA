#!/bin/bash
set -e

echo "=== VERNEXA Root Build Pipeline ==="

# 1. Ensure Flutter SDK is available
if command -v flutter &> /dev/null; then
  echo "Using existing Flutter SDK: $(flutter --version | head -n 1)"
elif [ -d "$HOME/flutter/bin" ]; then
  echo "Found cached Flutter SDK in $HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
else
  echo "Downloading Flutter SDK stable branch..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
  flutter config --no-analytics
fi

# 2. Enter mobile_app directory
cd mobile_app

# 3. Install dependencies and compile
echo "Running flutter pub get..."
flutter pub get

echo "Running flutter build web..."
flutter build web --release --no-wasm-dry-run

echo "=== Build Successful: mobile_app/build/web is ready for deployment ==="
