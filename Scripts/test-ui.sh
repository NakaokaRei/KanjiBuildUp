#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p build/test-results
# A unique bundle path also allows repeated local runs without deleting results.
result_dir=$(mktemp -d "$PWD/build/test-results/ui.XXXXXX")

xcodebuild test \
  -project KanjiBuildUp.xcodeproj \
  -scheme KanjiBuildUp \
  -configuration Debug \
  -destination "${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=latest}" \
  -destination-timeout 180 \
  -derivedDataPath build/DerivedData \
  -resultBundlePath "$result_dir/UITests.xcresult" \
  -parallel-testing-enabled NO \
  -collect-test-diagnostics never \
  -testLanguage ja \
  -testRegion JP \
  CODE_SIGNING_ALLOWED=NO \
  "$@" 2>&1 | tee "$result_dir/xcodebuild.log"
