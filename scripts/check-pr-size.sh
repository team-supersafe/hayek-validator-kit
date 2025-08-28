#!/bin/bash

# PR Complexity Checker
# Helps contributors assess if their PR is appropriately sized for review

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
TARGET_BRANCH="main"
CURRENT_BRANCH=$(git branch --show-current)

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --target|-t)
      TARGET_BRANCH="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [--target|-t TARGET_BRANCH]"
      echo "Analyzes the current branch against target branch for PR complexity"
      echo ""
      echo "Options:"
      echo "  --target, -t    Target branch to compare against (default: main)"
      echo "  --help, -h      Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help to see available options"
      exit 1
      ;;
  esac
done

echo "🔍 Analyzing PR complexity for branch: $CURRENT_BRANCH"
echo "📊 Comparing against target branch: $TARGET_BRANCH"
echo "=================================="

# Check if target branch exists
if ! git rev-parse --verify "$TARGET_BRANCH" >/dev/null 2>&1; then
  echo -e "${RED}❌ Target branch '$TARGET_BRANCH' not found${NC}"
  exit 1
fi

# Get diff stats
DIFF_STATS=$(git diff --numstat "$TARGET_BRANCH"..."$CURRENT_BRANCH")

if [ -z "$DIFF_STATS" ]; then
  echo -e "${YELLOW}⚠️  No changes detected between branches${NC}"
  exit 0
fi

# Calculate totals
TOTAL_ADDED=0
TOTAL_REMOVED=0
FILE_COUNT=0
LARGE_FILES=()

while IFS=$'\t' read -r added removed file; do
  # Skip binary files (marked with -)
  if [[ "$added" == "-" || "$removed" == "-" ]]; then
    continue
  fi
  
  TOTAL_ADDED=$((TOTAL_ADDED + added))
  TOTAL_REMOVED=$((TOTAL_REMOVED + removed))
  FILE_COUNT=$((FILE_COUNT + 1))
  
  # Check for large file changes
  TOTAL_CHANGES=$((added + removed))
  if [ $TOTAL_CHANGES -gt 100 ]; then
    LARGE_FILES+=("$file ($TOTAL_CHANGES lines)")
  fi
done <<< "$DIFF_STATS"

TOTAL_CHANGES=$((TOTAL_ADDED + TOTAL_REMOVED))

# Display statistics
echo "📈 Change Statistics:"
echo "   Files changed: $FILE_COUNT"
echo "   Lines added: $TOTAL_ADDED"
echo "   Lines removed: $TOTAL_REMOVED"
echo "   Total lines changed: $TOTAL_CHANGES"
echo ""

# Assess complexity
echo "🎯 PR Size Assessment:"

# Check total lines changed
if [ $TOTAL_CHANGES -le 400 ]; then
  echo -e "   ${GREEN}✅ Good size: $TOTAL_CHANGES lines changed (≤ 400)${NC}"
elif [ $TOTAL_CHANGES -le 500 ]; then
  echo -e "   ${YELLOW}⚠️  Large: $TOTAL_CHANGES lines changed (consider splitting)${NC}"
else
  echo -e "   ${RED}❌ Too large: $TOTAL_CHANGES lines changed (please split into smaller PRs)${NC}"
fi

# Check file count
if [ $FILE_COUNT -le 10 ]; then
  echo -e "   ${GREEN}✅ File count reasonable: $FILE_COUNT files${NC}"
elif [ $FILE_COUNT -le 20 ]; then
  echo -e "   ${YELLOW}⚠️  Many files: $FILE_COUNT files (consider grouping related changes)${NC}"
else
  echo -e "   ${RED}❌ Too many files: $FILE_COUNT files (please split by component)${NC}"
fi

# Check for large individual files
if [ ${#LARGE_FILES[@]} -gt 0 ]; then
  echo -e "   ${YELLOW}⚠️  Large file changes detected:${NC}"
  for file in "${LARGE_FILES[@]}"; do
    echo "      - $file"
  done
fi

echo ""

# Provide recommendations
echo "💡 Recommendations:"

if [ $TOTAL_CHANGES -gt 400 ] || [ $FILE_COUNT -gt 10 ]; then
  echo "   📝 Consider breaking this PR into smaller, focused changes:"
  echo "   • Separate preparatory work (dependencies, utilities)"
  echo "   • Split by component or feature area"
  echo "   • Separate refactoring from functional changes"
  echo "   • Use multiple PRs for complex features"
fi

if [ ${#LARGE_FILES[@]} -gt 0 ]; then
  echo "   📄 Large file changes detected - ensure they're necessary:"
  echo "   • Avoid mixing generated files with source changes"
  echo "   • Consider if large changes can be split logically"
fi

echo "   🔍 Before submitting:"
echo "   • Run: pre-commit run --all-files"
echo "   • Test changes in isolation"
echo "   • Update documentation if needed"
echo "   • Use the PR template to describe changes clearly"

echo ""
echo "🚀 Ready to submit? Use the GitHub PR template for best results!"