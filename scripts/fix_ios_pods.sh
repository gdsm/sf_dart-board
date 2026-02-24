#!/bin/bash
# Run from project root. Fixes CocoaPods "installed but broken" (Ruby Logger error).

set -e
cd "$(dirname "$0")/.."

# Ruby 3.2+ needs logger loaded before CocoaPods/ActiveSupport
export RUBYOPT="-rlogger"

echo "=== Running pod install (RUBYOPT=-rlogger) ==="
cd ios
pod install
cd ..

echo ""
echo "Done. To run on iOS simulator, use one of:"
echo "  export RUBYOPT=\"-rlogger\" && flutter run"
echo "  or add  export RUBYOPT=\"-rlogger\"  to your ~/.zshrc, then: flutter run"
