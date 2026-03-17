---
name: path-resolution
description: "Decision knowledge for choosing the correct file path resolution strategy when writing scripts. Provides a decision matrix for __file__/__dirname (script-anchored) vs environment variables vs os.chdir(), with language-specific patterns for Python, Node.js (CommonJS and ES Modules), and Bash. Inject into any agent that creates or modifies scripts to prevent CWD-dependent path bugs in cron, Docker, CI/CD, and cross-package imports."
user-invocable: false
---

# Path Resolution — Decision Knowledge

This skill provides the decision framework for choosing the correct file path strategy when writing scripts. Read `references/decision-matrix.md` before writing any script that references files by path.

## When This Applies

Consult the decision matrix whenever you are:

- Writing a new script (Bash, Python, Node.js)
- Adding file path references to existing code
- Creating config file loaders or data file readers
- Writing scripts that will run in Docker, CI/CD, or cron
- Building shared modules/packages that other code imports

## Quick Rules

1. **Never use bare relative paths** (`./config.json`, `data/file.txt`) in shared modules or scripts that may run from varying CWDs
2. **Anchor to the script's location** using the language's file-location primitive (`__file__`, `__dirname`, `$0`)
3. **Use environment variables** only when paths genuinely differ between environments (dev/staging/prod)
4. **Never use `os.chdir()`** except in trivial single-file scripts where you fully control the process

## Reference

Read `references/decision-matrix.md` for:
- The full decision matrix with tradeoffs
- Language-specific anchoring patterns (Python, Node.js CommonJS, Node.js ESM, Bash)
- Common failure scenarios (cron, Docker, CI/CD, IDEs, imported modules)
- The mental model: script file vs running process
