#!/bin/bash
# Common Tests Runner
# Individual scenario runner for CI/CD
set -euo pipefail

SCENARIO="common_tests"

echo "🎯 Running $SCENARIO tests..."
echo "▶️  Command: molecule test -s $SCENARIO"

exec molecule test -s "$SCENARIO"
