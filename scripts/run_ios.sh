#!/bin/bash
# Run the app on iOS (simulator or device). Fixes CocoaPods Ruby Logger issue.
cd "$(dirname "$0")/.."
export RUBYOPT="-rlogger"
flutter run "$@"
