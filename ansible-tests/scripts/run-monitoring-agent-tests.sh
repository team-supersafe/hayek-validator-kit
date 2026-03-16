#!/bin/bash
# Monitoring Agent Tests Runner
set -euo pipefail

SCENARIO="monitoring_agent_tests"

echo "🎯 Running $SCENARIO tests..."
echo "▶️  Command: molecule test -s $SCENARIO"

exec molecule test -s "$SCENARIO"
