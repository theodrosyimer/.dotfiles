---
name: npm-security
description: >-
  Audit and harden npm/pnpm/bun project security posture against supply chain
  attacks. Use this skill whenever the user asks to audit npm security, check
  dependency security, harden a project's dependencies, review npm security best
  practices, or secure a project's supply chain. Also trigger when the user asks
  about lockfile injection, postinstall script risks, dependency confusion,
  provenance attestations, or npm publishing security. Covers both a full
  security posture audit (reads project config and reports findings with fix
  suggestions) and an actionable reference guide for all 14 npm security best
  practices.
effort: medium
allowed-tools: >-
  Bash(cat:*), Bash(pnpm list:*), Bash(npm list:*), Bash(npx lockfile-lint:*),
  Bash(which:*), Read, Grep, Glob
---

# npm Security Best Practices

Dual-mode skill: **audit** a project's npm security posture, or **reference** best practices when making dependency decisions. Based on [lirantal/npm-security-best-practices](https://github.com/lirantal/npm-security-best-practices).

## Modes

Determine which mode the user needs from their prompt:

- **Audit mode** — user says "audit", "check", "scan", "harden", or asks about their project's security posture. Run the audit checklist (see Audit Workflow below).
- **Reference mode** — user asks about a specific practice, wants guidance on a config option, or is evaluating a dependency. Answer from the cheatsheet sections below.

If unclear, ask: "Do you want me to audit this project's security config, or are you looking for guidance on a specific practice?"

---

## Audit Workflow

Run these checks against the **project root** (not user dotfiles). Report each as pass/fail with a fix suggestion for failures.

### Step 1 — Detect Package Manager

Read `package.json`, check for `pnpm-lock.yaml`, `package-lock.json`, `bun.lock`, or `yarn.lock` to identify the primary package manager.

### Step 2 — Run Checks

Check each item. Report results as a checklist with suggested fixes for failures.

**Install Hardening**

| # | Check | How to verify |
|---|-------|---------------|
| 1 | Postinstall scripts disabled | pnpm: `allowBuilds` in `pnpm-workspace.yaml`. npm: `ignore-scripts=true` in `.npmrc`. bun: default off |
| 2 | Release cooldown configured | pnpm: `minimumReleaseAge` in `pnpm-workspace.yaml`. npm: `min-release-age` in `.npmrc`. bun: `minimumReleaseAge` in `bunfig.toml` |
| 3 | Lockfile integrity | Run `npx lockfile-lint` if installed, or check if it's a devDependency. pnpm: check `blockExoticSubdeps` in workspace config |
| 4 | Deterministic installs | Check CI config for `pnpm install --frozen-lockfile`, `npm ci`, or `bun install --frozen-lockfile` |
| 5 | Lockfile committed | Check git status for lockfile presence |

**Dependency Hygiene**

| # | Check | How to verify |
|---|-------|---------------|
| 6 | No blind upgrade scripts | Check `package.json` scripts for `npm update` or `ncu -u` (non-interactive). Flag if found |
| 7 | Security scanning tool available | Check if `npq` or `sfw` is installed globally (`which npq`, `which sfw`) |
| 8 | Dependency tree size | Run `pnpm list --depth 0` or equivalent — flag if >100 direct dependencies |

**Secrets & Isolation**

| # | Check | How to verify |
|---|-------|---------------|
| 9 | No plaintext secrets in .env | Grep `.env` files for patterns like `sk-`, `password=`, API keys. Flag raw values (not `op://` or `infisical://` references) |
| 10 | Dev container configured | Check for `.devcontainer/devcontainer.json` |

**Publishing Security** (skip if no `publishConfig` or `private: true` in package.json)

| # | Check | How to verify |
|---|-------|---------------|
| 11 | Provenance in CI | Grep CI configs for `--provenance` flag |
| 12 | OIDC publishing | Check CI for `id-token: write` permission (GitHub Actions) |
| 13 | 2FA reminder | Informational — remind maintainers to enable `npm profile enable-2fa auth-and-writes` |

### Step 3 — Report

Present results as a checklist. For each failure, provide the exact config/command to fix it. Example format:

```
## npm Security Audit

### Install Hardening
- [x] Postinstall scripts: allowBuilds configured in pnpm-workspace.yaml
- [ ] Release cooldown: not configured
      Fix: add to pnpm-workspace.yaml:
      minimumReleaseAge: 20160  # 2 weeks in minutes
- [x] Lockfile integrity: lockfile-lint in devDependencies

### Dependency Hygiene
- [x] No blind upgrade scripts found
- [ ] npq not installed globally
      Fix: npm install -g npq
...
```

---

## Reference: 14 npm Security Best Practices

### 1. Disable Postinstall Scripts

Postinstall scripts enable arbitrary code execution during install. Shai-Hulud, Nx, and event-stream all exploited this vector.

**pnpm 10.26+** (`pnpm-workspace.yaml`):
```yaml
allowBuilds:
  esbuild: true
  fsevents: true
  core-js: false
strictDepBuilds: true  # fail CI on unapproved scripts
```

**npm** (`.npmrc`):
```ini
ignore-scripts=true
allow-git=none
```

**bun**: disabled by default. Use `trustedDependencies` in `package.json` for exceptions.

For granular control across any manager: `@lavamoat/allow-scripts` creates allowlists for specific positions in the dependency graph.

**pnpm trust policy** (10.21+): `trustPolicy: no-downgrade` detects when package trust levels decrease (Trusted Publisher > Provenance > Signatures > No evidence).

### 2. Install with Cooldown

Delay installations so the community can discover vulnerabilities in new releases before you adopt them.

**pnpm 10.16+** (`pnpm-workspace.yaml`):
```yaml
minimumReleaseAge: 20160  # 2 weeks in minutes
minimumReleaseAgeExclude:
  - '@types/react'
  - typescript
```

**npm** (`.npmrc`):
```ini
min-release-age=3
```

**bun** (`bunfig.toml`):
```toml
[install]
minimumReleaseAge = 259200  # seconds (3 days)
```

**yarn 4.10+** (`.yarnrc.yml`):
```yaml
npmMinimalAgeGate: "3d"
```

Snyk, Dependabot, and Renovate all support cooldown periods for automated upgrade PRs.

### 3. Harden Installs with Security Tools

**npq** — pre-install auditor. Checks: vulnerabilities (Snyk DB), package age, typosquatting, registry signatures, provenance, preinstall scripts, binaries, deprecation, maintainer domains.

```bash
npm install -g npq
npq install express
# or alias: alias npm='npq-hero'
# pnpm: NPQ_PKG_MGR=pnpm npq install fastify
```

**Socket Firewall (sfw)** — real-time firewall using Socket's threat intelligence. Detects: malicious code, install script risks, typosquatting, dependency confusion, protestware, network/filesystem access patterns.

```bash
npm install -g sfw
sfw pnpm add express
```

| | npq | sfw |
|---|---|---|
| Approach | Pre-install marshalls | Real-time interception |
| Data source | Snyk + npm registry | Socket threat intelligence |
| Interaction | Interactive prompts | Blocks flagged packages |

### 4. Prevent Lockfile Injection

Malicious PRs can inject compromised packages into lockfiles. Validate lockfiles in CI.

```bash
npx lockfile-lint --path pnpm-lock.yaml --type npm --allowed-hosts npm --validate-https
```

CI integration (`package.json`):
```json
{
  "scripts": {
    "lint:lockfile": "lockfile-lint --path pnpm-lock.yaml --type npm --allowed-hosts npm --validate-https"
  }
}
```

**pnpm 10.26+**: `blockExoticSubdeps: true` in `pnpm-workspace.yaml` prevents transitive deps from using git repos or direct tarball URLs.

Note: pnpm is less susceptible than npm — it won't install unlisted lockfile packages.

### 5. Use Deterministic Installs

Never use `npm install` in CI. Use commands that enforce strict lockfile adherence.

| Manager | Command |
|---------|---------|
| pnpm | `pnpm install --frozen-lockfile` |
| npm | `npm ci` |
| yarn | `yarn install --immutable --immutable-cache` |
| bun | `bun install --frozen-lockfile` |
| deno | `deno install --frozen` |

Always commit lockfiles to version control.

### 6. Avoid Blind Package Upgrades

`npm update` and `npx npm-check-updates -u` blindly upgrade to latest, exposing you to compromised packages.

Use interactive review instead:
```bash
npx npm-check-updates --interactive
```

Or use automated services with security policies: Snyk, Dependabot, Renovate — all support cooldown and security review before merging.

### 7. No Plaintext Secrets in .env Files

Plaintext `.env` values are readable by any dependency in the process. Use secret references instead.

```bash
# Bad
DATABASE_PASSWORD=my-secret-password

# Good — 1Password reference
DATABASE_PASSWORD=op://vault/database/password

# Good — Infisical reference
API_KEY=infisical://project/env/api-key
```

Runtime injection:
```bash
op run -- pnpm start
op run --env-file="./.env" -- node server.js
```

### 8. Work in Dev Containers

Dev containers isolate projects from the host system, limiting blast radius from malicious packages.

`.devcontainer/devcontainer.json`:
```json
{
  "name": "Node.js Dev Container",
  "image": "mcr.microsoft.com/devcontainers/javascript-node:22",
  "features": {
    "ghcr.io/devcontainers/features/1password:1": {}
  },
  "postCreateCommand": "pnpm install --frozen-lockfile",
  "runArgs": [
    "--security-opt=no-new-privileges:true",
    "--cap-drop=ALL",
    "--cap-add=CHOWN",
    "--cap-add=SETUID",
    "--cap-add=SETGID"
  ]
}
```

### 9. Enable 2FA for npm Accounts

After the eslint-scope incident (2018), 2FA is essential for any npm account that publishes packages.

```bash
# For auth + publishing (recommended)
npm profile enable-2fa auth-and-writes

# For login/profile changes only
npm profile enable-2fa auth-only
```

### 10. Publish with Provenance Attestations

Provenance provides cryptographic proof linking published packages to their source code and build system.

GitHub Actions:
```yaml
permissions:
  id-token: write
steps:
  - run: npm publish --provenance
```

Requires npm CLI 9.5.0+ and cloud-hosted CI runners (GitHub Actions or GitLab CI/CD).

### 11. Publish with OIDC (Trusted Publishing)

OIDC eliminates long-lived npm tokens by using short-lived, cryptographically-signed tokens scoped to specific CI workflows.

GitHub Actions:
```yaml
permissions:
  id-token: write
steps:
  - run: npm publish
```

Tokens can't be extracted or reused. Publishing is limited to authorized workflow files. Automatic provenance attestation included.

### 12. Reduce Your Dependency Tree

Every dependency is attack surface. Prefer native alternatives:

```javascript
// Instead of lodash
const unique = [...new Set(array)];

// Instead of axios
const response = await fetch(url);

// Instead of is-empty
const isEmpty = obj => Object.keys(obj).length === 0;
```

Before adding a package, ask: can modern JavaScript/Node.js do this natively?

### 13. Check Package Health via Snyk

Go beyond vulnerability counts. Check [security.snyk.io](https://security.snyk.io) for:

- **Security**: known CVEs
- **Popularity**: download trends
- **Maintenance**: release frequency
- **Community**: contributor activity, issue responsiveness

### 14. Don't Blindly Trust npmjs.org

The npmjs.org website omits git and HTTPS dependencies from display. Source code shown can drift from actual installed tarballs.

Verify before trusting:
```bash
# Inspect what would be installed
npm pack <package-name> --dry-run

# Inspect actual contents
npm pack <package-name>
tar -tzf <package-name>-<version>.tgz
```

Use npq (section 3) for comprehensive pre-install auditing that consults multiple data sources beyond npmjs.org.
