#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/kanji-unit-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT

# Keep preconditions enabled: LearningTests uses them as assertions.
xcrun swiftc -Onone \
  Shared/*.swift \
  KanjiBuildUp/Models/*.swift \
  KanjiBuildUp/Services/*.swift \
  KanjiBuildUp/Stores/*.swift \
  Tests/LearningTests.swift \
  -o "$test_dir/learning-tests"
"$test_dir/learning-tests"
