# Path Resolution — Decision Matrix

> Derived from: LearnThatStack — [Your File Paths Work by Accident?](https://www.youtube.com/watch?v=LNCrQCyXhbg)

## Core Rule

Relative paths resolve from the **process's current working directory (CWD)**, not from the script file's location. The CWD is set by whatever starts the process — terminal, cron, Docker, CI, IDE — and is frequently not what you expect.

## Decision Matrix

```
DECISION — Which Path Strategy to Use

OPTION A: Script-anchored (__file__ / __dirname / $0)
  ✅ Data files ship alongside code
  ✅ Works in every execution context automatically
  ✅ No global state mutation
  ❌ Doesn't help when paths differ between environments

OPTION B: Environment variables
  ✅ Paths change between environments (dev/staging/prod)
  ✅ Works across OS boundaries
  ❌ Requires configuration per environment
  ❌ Missing env var = silent failure if no default

OPTION C: os.chdir() / cd at startup
  ✅ Simple for one-file scripts
  ❌ Mutates global process state
  ❌ Breaks subprocesses expecting original CWD
  ❌ Unsafe for anything beyond trivial scripts

RULE: Use __file__/__dirname when data ships with code.
      Use env vars when paths differ per environment.
      Use os.chdir() only if you fully control the process.
```

## Language Patterns

### Python

```python
from pathlib import Path

base = Path(__file__).resolve().parent
config = base / "data" / "config.json"
```

`.resolve()` follows symlinks — returns the real location, not the link.

### Node.js (CommonJS)

```javascript
const path = require("path");
const config = path.join(__dirname, "data", "config.json");
```

### Node.js (ES Modules)

```javascript
import { fileURLToPath } from "url";
import path from "path";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const config = path.join(__dirname, "data", "config.json");
```

### Bash

```bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
config="$SCRIPT_DIR/data/config.json"
```

For sourced scripts, use `$BASH_SOURCE` instead of `$0`.

## Failure Scenarios

These contexts silently change the CWD — bare relative paths will break:

```
CONTEXT           CWD SET TO
─────────         ──────────
cron              user's home directory (~/)
Docker            WORKDIR directive in Dockerfile
CI/CD             pipeline step's working directory (varies)
IDE "Run"         workspace root, not file directory
import/require    caller's CWD, not module's location
Turborepo tasks   package directory (not monorepo root)
```

## Monorepo-Specific Rules

```
MONOREPO PATH RESOLUTION:

  ✅ Use path.join(__dirname, ...) in Node.js scripts and config
  ✅ Use path.dirname(fileURLToPath(import.meta.url)) in ES module packages
  ✅ Use SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)" in Bash scripts
  ❌ Never use bare relative paths in shared packages
     (each package's CWD depends on which app imports it)
  ❌ Don't rely on Turborepo CWD for cross-package references
     (use tsconfig paths or package.json exports instead)
```

## Diagnostic

When a "file not found" error occurs in a different environment, print the CWD first:

```
Python:   print(os.getcwd())
Node.js:  console.log(process.cwd())
Bash:     echo "$PWD"
```

The issue becomes obvious immediately — the CWD is somewhere unexpected.
