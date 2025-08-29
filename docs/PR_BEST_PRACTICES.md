# PR Best Practices Guide

This document provides detailed guidance on creating effective pull requests that are easy to review and reduce cognitive load on maintainers.

## Why Small PRs Matter

**For Reviewers:**
- Faster review times (under 30 minutes vs. hours)
- Better focus and attention to detail
- Reduced risk of missing issues
- Less mental fatigue

**For Contributors:**
- Faster feedback cycles
- Easier to address review comments
- Reduced risk of merge conflicts
- Better chance of acceptance

## PR Size Guidelines

### Recommended Limits

- **Lines of code**: < 200 lines changed
- **Files changed**: < 10 files
- **Review time**: < 30 minutes
- **Single logical change**: One feature/fix per PR

### When to Split PRs

**Split into separate PRs when you have:**
- Multiple unrelated bug fixes
- New feature + refactoring existing code
- Large architectural changes
- Multiple components affected
- Documentation + code changes (can be separate)

## Breaking Down Large Changes

### Strategy 1: Layered Approach

For a new feature that affects multiple components:

1. **PR 1**: Add dependencies and utilities
2. **PR 2**: Core implementation
3. **PR 3**: Integration with existing code
4. **PR 4**: Tests and documentation
5. **PR 5**: Configuration and deployment

### Strategy 2: Component-Based

For changes affecting multiple Ansible roles:

1. **PR 1**: Update role A
2. **PR 2**: Update role B  
3. **PR 3**: Update shared playbooks
4. **PR 4**: Update inventory files

### Strategy 3: Preparatory PRs

Before large features:

1. **PR 1**: Refactor existing code (no functional changes)
2. **PR 2**: Add shared utilities
3. **PR 3**: Implement new feature

## PR Types and Patterns

### ✅ Good PR Examples

**Bug Fix PR:**
```
Title: Fix SSH key validation in server setup role
Files: 1-3 files
Lines: 10-50 lines
Focus: Single bug, clear fix
```

**Feature Addition PR:**
```
Title: Add Jito MEV support to validator role
Files: 3-8 files  
Lines: 100-200 lines
Focus: One new capability
```

**Refactoring PR:**
```
Title: Extract common utilities from validator roles
Files: 5-10 files
Lines: 50-150 lines
Focus: Code structure only, no behavior change
```

### ❌ Problematic PR Examples

**Too Large:**
```
Title: Add monitoring + fix bugs + refactor + update docs
Files: 20+ files
Lines: 500+ lines
Issues: Multiple concerns, hard to review
```

**Mixed Concerns:**
```
Title: Update Solana version and improve error handling
Files: 15+ files
Lines: 300+ lines  
Issues: Two separate changes that should be split
```

## Using the PR Size Checker

Before submitting a PR, run our size checker:

```bash
# Check your current branch
./scripts/check-pr-size.sh

# Check against a different base
./scripts/check-pr-size.sh --target develop
```

The tool will tell you:
- Total lines changed
- Files affected
- Recommendations for improvement

## PR Template Guidelines

When filling out the PR template:

### Summary Section
- Keep it to 1-2 sentences
- Focus on the "what" and "why"

### Type of Change
- Select only one primary type
- If you need multiple types, consider splitting

### Scope & Complexity
- Be honest about the checklist items
- If you can't check all boxes, explain why

### Changes Made
- List specific changes, not general goals
- Use bullet points for clarity

### Testing
- Describe what you tested
- Include any manual verification steps

## Review Process Optimization

### For Authors

**Before Submitting:**
1. Self-review your own PR first
2. Run the size checker tool
3. Ensure pre-commit hooks pass
4. Test changes in isolation

**During Review:**
1. Respond to feedback quickly
2. Ask clarifying questions
3. Make small, focused updates
4. Keep the PR up to date with main branch

### For Reviewers

**Review Guidelines:**
- Focus on logic, security, and maintainability
- Don't nitpick minor style issues (use automated tools)
- Provide constructive feedback with examples
- Approve quickly if changes are good

## Common Pitfalls to Avoid

### Anti-Patterns

1. **Kitchen Sink PRs**: "While I'm here, let me also fix..."
2. **Perfectionism**: Trying to fix everything in one PR
3. **Feature Creep**: Adding "just one more small thing"
4. **Mixing Concerns**: Bug fixes + new features together

### Red Flags

- PR description says "various fixes"
- More than 20 files changed
- Mix of .yml, .md, and .sh files without clear relation
- Reviewer says "this is too much to review"

## Tools and Automation

### Available Tools

1. **PR Size Checker**: `./scripts/check-pr-size.sh`
2. **Pre-commit Hooks**: Automatic formatting and linting
3. **PR Template**: Guides you through best practices

### Recommended Workflow

```bash
# 1. Create feature branch
git checkout -b feature/add-monitoring

# 2. Make focused changes
# ... edit files ...

# 3. Check size before committing
./scripts/check-pr-size.sh

# 4. If too large, split into multiple commits/PRs
# 5. Run pre-commit hooks
pre-commit run --all-files

# 6. Submit PR using template
```

## Examples from This Repository

### Good PR Structure

Look at these types of changes as examples of well-sized PRs:

- Adding a single Ansible role
- Fixing a specific bug in one playbook
- Updating documentation for one feature
- Refactoring one role without functional changes

### When to Make Exceptions

Large PRs might be acceptable for:

- Initial project setup
- Large-scale dependency updates
- Generated code or configuration
- Emergency security fixes

Even then, consider if they can be broken down.

## Getting Help

If you're unsure about how to structure your PR:

1. Open an issue to discuss the approach
2. Ask in PR comments for guidance on splitting
3. Use the PR size checker for objective feedback
4. Look at recent small PRs for examples

Remember: Multiple small PRs are better than one large PR!