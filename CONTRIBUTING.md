# Contributing Guidelines

Thank you for your interest in contributing to the Hayek Validator Kit! We welcome all contributions—code, documentation, and ideas.

## Code of Conduct

Please be respectful and considerate of others when contributing. We follow the [Solana Code of Conduct](https://solana.com/code-of-conduct).

## Getting Started

- **Read the [official documentation](https://docs.hayek.fi/public-goods)** for setup, usage, and development instructions.
- **Fork** this repository and clone your fork locally.
- **Create a branch** for your feature or fix (e.g., `feature/add-monitoring` or `fix/playbook-error`).

## Code Standards

- Follow the existing code style and patterns.
- Include comments for complex logic.
- Write tests for new features.
- Keep documentation up-to-date with code changes.

## Pre-commit Hooks

We use [pre-commit](https://pre-commit.com/) to help maintain code quality. Please install and run the hooks before committing:

```sh
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

## PR Size Checker

We provide a helpful script to check if your PR is appropriately sized before submission:

```sh
./scripts/check-pr-size.sh
```

This script will:
- Analyze the number of lines and files changed
- Provide recommendations for breaking down large PRs
- Suggest best practices for submission

**Usage examples:**
```sh
# Check against main branch (default)
./scripts/check-pr-size.sh

# Check against a different target branch
./scripts/check-pr-size.sh --target develop

# Get help
./scripts/check-pr-size.sh --help
```

## Making a Pull Request

### PR Size Guidelines

To ensure fast and effective reviews, please follow these guidelines:

**Recommended PR Size:**
- **Fewer than 200 lines changed** (excluding generated files, documentation)
- **Single logical change** per PR
- **Reviewable in under 30 minutes**

**Breaking Down Large Changes:**
- Split new features into multiple PRs (setup → core logic → tests → documentation)
- Separate refactoring from functional changes
- Create preparatory PRs for large features (dependencies, utilities, etc.)
- Use feature flags for incremental rollouts

**Examples of Well-Sized PRs:**
- ✅ Add new Ansible role for specific service
- ✅ Fix bug in existing playbook
- ✅ Update documentation for specific feature
- ✅ Refactor single role without functional changes
- ❌ Add new feature + refactor existing code + update multiple roles
- ❌ Large-scale architectural changes affecting multiple components

### PR Submission Process

1. **Before Opening a PR:**
   - Run `pre-commit run --all-files` to catch issues early
   - Test your changes in isolation
   - Ensure your PR follows the size guidelines above

2. **Opening the PR:**
   - Push your branch to your fork
   - Open a pull request (PR) to the main repository
   - Use the provided PR template to describe your changes
   - Include a clear description and reference any related issues
   - Add appropriate labels (if you have permission)

3. **After Opening:**
   - Ensure your code passes all pre-commit hooks and tests
   - Update the README or documentation if your changes affect usage or setup
   - Respond promptly to reviewer feedback
   - Keep the PR up to date with the main branch if needed

### PR Title Convention

Use clear, descriptive titles:
- `Add monitoring role for Solana validators`
- `Fix SSH key validation in server setup`
- `Update Jito installation documentation`
- `Refactor common utilities in shared role`

### Need More Guidance?

For detailed guidance on creating effective PRs, see our [PR Best Practices Guide](docs/PR_BEST_PRACTICES.md).

## Reporting Issues

If you find a bug or have a feature request, please open an issue and include:

- A clear description of the problem or request
- Steps to reproduce (if applicable)
- Expected and actual behavior
- Environment details (OS, Solana version, etc.)
- Any relevant logs or error messages

## Questions?

If you have questions, open an issue or contact the maintainers directly.

Thank you for helping improve the Hayek Solana Kit!
