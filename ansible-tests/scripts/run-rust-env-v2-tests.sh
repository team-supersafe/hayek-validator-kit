#!/bin/bash
# Rust Environment v2 Tests Runner
# Individual scenario runner for CI/CD
set -euo pipefail

SCENARIO="rust_env_v2_tests"
PARAMS="-- -e csv_file=iam_setup.csv"

echo "🎯 Running $SCENARIO tests..."
echo "▶️  Command: molecule test -s $SCENARIO $PARAMS"

exec molecule test -s "$SCENARIO" $PARAMS

