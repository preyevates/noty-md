#!/usr/bin/env bash
# Configure, build and run the full test suite in one step.
# Usage: tools/check.sh [build-dir]   (default: build)
# Exits nonzero if configuration, the build, or any test fails.
set -euo pipefail

source_dir=$(cd "$(dirname "$0")/.." && pwd)
build_dir=${1:-"$source_dir/build"}
jobs=$(bash "$source_dir/tools/safe-build-jobs.sh")

cmake -S "$source_dir" -B "$build_dir" -DCMAKE_BUILD_TYPE=Release
cmake --build "$build_dir" -j"$jobs"
ctest --test-dir "$build_dir" --output-on-failure
