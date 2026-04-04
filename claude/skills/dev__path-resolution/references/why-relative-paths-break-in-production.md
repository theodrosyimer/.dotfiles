# Why Relative Paths Break in Production — The Working Directory Mental Model

> **Source**: LearnThatStack — [Your File Paths Work by Accident?](https://www.youtube.com/watch?v=LNCrQCyXhbg)
>
> **Key Insight**: Relative paths resolve from the process's current working directory (CWD), not from the script file's location on disk. This causes silent failures when the same code runs in a different execution context — cron, Docker, CI/CD, or even a different terminal directory.

---

## 1. Absolute vs Relative Paths

An absolute path starts from the filesystem root (`/` on Unix, drive letter on Windows) and always points to the same file regardless of where you are. A relative path starts from "somewhere" — and that somewhere is the critical question most developers get wrong.

The shorthand `.` (current directory) and `..` (parent directory) are relative paths too. They follow the same resolution rules: they resolve from the CWD, not from the file that references them.

---

## 2. The Common Misconception

Most developers, especially early in their careers, assume relative paths resolve from the folder the script lives in. LearnThatStack demonstrates this with a Python script that reads `data/config.json` — it works when you `cd` into the project folder and run it, but breaks when you run it from one directory up. No code changed. No files moved. The only difference is which directory the terminal was in when the command executed.

This happens because every running process has a **current working directory** (CWD). When you open a terminal, the CWD starts at your home folder. When you `cd` somewhere, you change it. When your code opens `data/config.json`, the operating system appends that relative path to the CWD — not to the script's location.

```
PATH RESOLUTION — How Relative Paths Actually Work

  Scenario A (works):
    CWD = /project/
    Relative path = data/config.json
    Resolved = /project/data/config.json  ✅

  Scenario B (breaks):
    CWD = /project/../  (one directory up)
    Relative path = data/config.json
    Resolved = /data/config.json  ❌ (file not found)

  Same code. Same files. Different CWD → different result.
```

This is not language-specific. It is how the operating system resolves paths. Every language — Python, Node.js, Bash, Go — follows the same rule.

---

## 3. Where the Bugs Show Up

The CWD usually matches the project folder during local development because you `cd` there before running. The bugs appear when something else controls the CWD.

### 3.1 Imported Modules

A utility module reads a file using a relative path like `utils/grammar.ext`. The file sits right next to the module, so the path looks correct. But it resolves from the CWD of whatever process imported it. If someone imports the module from a different project or runs the app from a different directory, the path breaks silently.

### 3.2 Cron Jobs

Cron does not start in your project directory. It typically uses the user's home directory as CWD. Every relative path in your script suddenly resolves from `~/` instead of your project root.

### 3.3 Docker Containers

The `WORKDIR` directive in a Dockerfile sets the CWD inside the container. If it does not match what your code expects, relative paths resolve incorrectly. Mounted volumes add another layer — paths inside the container may differ completely from the host machine.

### 3.4 CI/CD Pipelines

GitHub Actions, GitLab CI, and Jenkins clone your repo into an arbitrary directory. If a build step `cd`s into a subdirectory, the next step inherits a different CWD. Relative paths that assumed the repo root break silently.

### 3.5 IDEs

VS Code sets the CWD to the workspace root when you click "Run", not to the directory the file lives in. The same script that works via the IDE run button can break when executed from a terminal in a different directory.

```
PATTERN — "Works Here, Breaks There"

  ❌ ALL of these change the CWD silently:
     cron         → defaults to ~/
     Docker       → depends on WORKDIR directive
     CI/CD        → depends on pipeline step
     IDE "Run"    → workspace root, not file directory
     import       → inherits caller's CWD

  ✅ THE DIAGNOSTIC:
     Print the CWD. The issue becomes obvious immediately.
     Python:  print(os.getcwd())
     Node.js: console.log(process.cwd())
     Bash:    echo "$PWD"
```

---

## 4. The Fix — Anchor Paths to the Script's Location

The most reliable approach is to build absolute paths from the script's own location on disk. Every language provides a way to ask "where is this source file?"

```
PATTERN — Script-Anchored Paths

  Python:
    base = Path(__file__).resolve().parent
    config = base / "data" / "config.json"

  Node.js (CommonJS):
    const config = path.join(__dirname, "data", "config.json")

  Node.js (ES Modules):
    const __dirname = path.dirname(fileURLToPath(import.meta.url))
    const config = path.join(__dirname, "data", "config.json")

  Bash:
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    config="$SCRIPT_DIR/data/config.json"
```

`.resolve()` in Python also follows symlinks, returning the real location rather than the link. This matters when scripts are symlinked from another directory.

---

## 5. Alternative Approaches

### 5.1 Changing CWD at Script Start

You can `os.chdir()` (or equivalent) to the script's directory at startup so all relative paths resolve as expected. This works for simple single-file scripts, but mutates global state for the entire process. If any other part of the code or a subprocess uses relative paths expecting the original CWD, those paths silently resolve to the wrong place.

### 5.2 Environment Variables

Set paths per environment — one value on your dev machine, another in Docker config, another in CI. The code reads the path from the environment without hardcoding any location. This is the right choice when paths change between environments (dev, staging, production).

```
DECISION — Which Path Strategy to Use

OPTION A: __file__ / __dirname (script-anchored)
  ✅ Data files ship alongside code
  ✅ Works in every execution context automatically
  ✅ No global state mutation
  ❌ Doesn't help when paths differ between environments

OPTION B: Environment variables
  ✅ Paths change between environments (dev/staging/prod)
  ✅ Works across OS boundaries
  ❌ Requires configuration per environment
  ❌ Missing env var = silent failure if no default

OPTION C: os.chdir() at startup
  ✅ Simple for one-file scripts
  ❌ Mutates global process state
  ❌ Breaks subprocesses expecting original CWD
  ❌ Unsafe for anything beyond trivial scripts

RULE: Use __file__/__dirname when data ships with code.
      Use env vars when paths differ per environment.
      Use os.chdir() only if you fully control the process.
```

---

## 6. The Mental Model

LearnThatStack summarizes the entire concept in one sentence: **relative paths resolve from the working directory, not from your script file.** The mental model to carry is:

```
MENTAL MODEL — Script vs Process

  FILE ON DISK                    RUNNING PROCESS
  ─────────────                   ──────────────
  /project/app.py     ─ runs ─▶   Process (PID)
                                     │
                                     ├── CWD: set by whatever started it
                                     │         (terminal, cron, Docker, CI, IDE)
                                     │
                                     └── Every relative path resolves from CWD
                                         NOT from /project/app.py

  ✅ Anchor to __file__ → CWD becomes irrelevant
  ❌ Rely on CWD → works by accident, breaks by context
```

---

## 7. Relevance to Our Architecture

The user's stack (TypeScript/Node.js, NestJS, Expo, Turborepo monorepo, Bash scripts, Docker, CI/CD) intersects with nearly every failure scenario described.

```
APPLICATION TO TURBOREPO MONOREPO + NESTJS + EXPO

MONOREPO PATH RESOLUTION:
  ✅ Use path.join(__dirname, ...) in Node.js scripts and NestJS config
  ✅ Use path.dirname(fileURLToPath(import.meta.url)) in ES module packages
  ✅ Use SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)" in Bash scripts
  ❌ Never use bare relative paths like "./config.json" in shared packages
     (each package's CWD depends on which app imports it)

DOCKER / CI ENVIRONMENTS:
  ✅ Use environment variables for paths that differ per environment
     (e.g., DATA_DIR, CONFIG_PATH in Docker Compose and GitHub Actions)
  ✅ Set explicit WORKDIR in Dockerfiles matching code expectations
  ❌ Don't assume CWD matches the project root in CI pipeline steps
     (GitHub Actions steps may cd into subdirectories)

TURBOREPO TASK EXECUTION:
  ✅ Turborepo runs each task with CWD set to the package directory
     (turbo run build in packages/api → CWD = packages/api/)
  ❌ Don't rely on this for cross-package references
     (use tsconfig paths or package.json exports instead)

CLAUDE CODE / DOTFILES SCRIPTS:
  ✅ Bash scripts in .dotfiles should anchor to $0 or $BASH_SOURCE
  ❌ Don't assume scripts run from the dotfiles directory
     (hooks and statusline scripts are invoked from arbitrary CWDs)
```

---

## Summary

Relative paths resolve from the current working directory of the running process, not from the script file's location. This is an operating system behavior, not a language quirk. The CWD is set by whatever starts the process — your terminal, cron, Docker, a CI runner, or an IDE — and most "file not found" bugs in production stem from a CWD mismatch. The fix is straightforward: anchor paths to the script's own location using `__file__`, `__dirname`, or `$0`, and reserve environment variables for paths that genuinely differ between environments. Once you internalize this mental model, path errors become immediately diagnosable rather than mysterious.

[^1]: LearnThatStack — [Your File Paths Work by Accident?](https://www.youtube.com/watch?v=LNCrQCyXhbg)
