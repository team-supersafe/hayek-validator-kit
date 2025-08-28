# Hayek Validator Kit

**Official Documentation:**  
👉 [docs.hayek.fi/public-goods](https://docs.hayek.fi/public-goods)

This repository contains the open source Hayek Validator Kit. For setup, usage, and general guides, please refer to the official documentation above.

---

## Pre-commit Hooks

We recommend using [pre-commit](https://pre-commit.com/) to automatically check your code for common issues before committing.

### Setup

1. Install pre-commit (requires Python):

   ```sh
   pip install pre-commit
   ```

2. Install the hooks:

   ```sh
   pre-commit install
   ```

3. (Optional) Run all hooks on all files:

   ```sh
   pre-commit run --all-files
   ```

---

## EditorConfig

This repository includes an [.editorconfig](https://editorconfig.org/) file to help maintain consistent coding styles across different editors and IDEs.

---

## Contributing

We welcome contributions!
Please read our [Contributing Guidelines](CONTRIBUTING.md) before opening a pull request.

- For setup and development instructions, see the [official documentation](https://docs.hayek.fi/public-goods).
- Please ensure your code passes all pre-commit hooks and follows the style guide.
- **Keep PRs small and focused** - aim for fewer than 400 lines changed per PR for faster reviews.
- Use our PR size checker: `./scripts/check-pr-size.sh` before submitting.
