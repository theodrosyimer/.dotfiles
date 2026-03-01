---
name: github-strategy
description: >
  GitHub organization and repository strategy for SaaS founders, freelancers, and consultancies.
  Use when the user asks about setting up a GitHub organization, managing client repositories,
  repository naming conventions, access control, team permissions, code ownership,
  transferring repos to clients, or choosing between personal accounts and organizations.
  Includes decision frameworks for different work models (solo, freelance, agency, consultancy).
---

# GitHub Organizations Strategy Guide

## Profile Integration

If `profiles/business-profile.md` exists, check:
- **Work model**: Solo founder, freelancer, consultancy, agency?
- **Team situation**: Solo or collaborating?
- **Client work**: Do they do client work alongside products?
- **Professional presence priority**: How important is GitHub as a credential?

If `profiles/tech-preferences.md` exists, check:
- **CI/CD**: GitHub Actions or other?
- **Monorepo vs multi-repo**: Affects organization structure
- **Collaboration needs**: Code review requirements, access patterns

---

## Organization vs Personal Account

### Quick Decision

| Situation | Recommendation |
|-----------|---------------|
| Solo, personal projects only | Personal account is fine |
| Any client work | Create an organization |
| Building a SaaS product | Create an organization |
| Want professional credibility | Create an organization |
| Working with a team | Definitely create an organization |
| Budget-conscious, just starting | Personal account → upgrade when second client arrives |

### Organization Advantages

| Feature | Personal | Organization |
|---------|----------|-------------|
| Team collaboration | Limited | Granular team permissions |
| Access control | Basic read/write | Role hierarchy (Owner/Member/Collaborator) |
| Professional presence | Personal branding | Business branding |
| Security features | Basic | Advanced (dependency scanning, audit logs) |
| CI/CD minutes | Limited | More GitHub Actions minutes |
| Repository ownership | Tied to individual | Multiple owners, transferable |

---

## Strategy by Work Model

### Strategy 1: Single Freelancer Organization ⭐ Best for Most Solo Founders

**Best for**: Freelancers, solo SaaS founders, small projects, deliverable-focused clients.

**Setup**:
- One organization: `yourname-dev` or `yourcompany`
- All client work and products in one org
- Team-based access for clients who need it
- Private repos for client work, public for portfolio/OSS

**Pros**: Centralized, one billing point, portfolio showcase, professional credibility
**Cons**: Client code mixing concerns, access control needs discipline

### Strategy 2: One Organization Per Client

**Best for**: Long-term consultancy (6+ months), clients wanting code ownership, compliance requirements.

**Setup**:
- Create `clientname-projects` org per client
- Client as org member with appropriate permissions
- Easy handoff: transfer org ownership when done

**Pros**: Clean separation, easy transfer, no cross-client visibility
**Cons**: Admin overhead, multiple billing, fragmented portfolio

### Strategy 3: Hybrid (Recommended for Growing Businesses)

**Setup**:
1. Your main org for products and internal tools
2. Per-client orgs only when client requires it
3. Start in your org → transfer to client org when project completes

**Flow**:
```
New Project → Your Org (private repo) → Client team access
    ↓
Project Complete → Client wants ownership? → Transfer to client org
                 → Client doesn't need it? → Keep in your org (portfolio)
```

---

## Naming Conventions

### Organization Names
```
yourname-dev          # Personal brand
yourcompany           # Company brand
clientname-projects   # Per-client org (if using that strategy)
```

### Repository Names
```
product-name          # SaaS products
product-name-api      # Backend service
product-name-app      # Frontend/mobile app
product-name-admin    # Admin dashboard
product-name-docs     # Documentation
client-projectname    # Client work (if in your org)
```

### Team Names (within organizations)
```
client-frontend       # Client-specific frontend access
client-backend        # Client-specific backend access
client-full-access    # Client-specific full access
core-team             # Your full team
read-only             # Stakeholders who just need visibility
```

---

## Access Control

| Role | Repo Access | Team Management | Billing | Org Settings |
|------|------------|-----------------|---------|-------------|
| **Owner** | Full | Full | Full | Full |
| **Member** | Based on team | Limited | None | None |
| **Outside Collaborator** | Specific repos | None | None | None |

### Best Practices
- Use **outside collaborator** for clients (not full members)
- Create teams per client/project for clean access boundaries
- **Least privilege**: Give minimum access needed
- Regular access audits (quarterly)
- Remove access promptly when projects end

---

## Repository Transfer Process

When a client wants code ownership:

1. **Discuss ownership expectations upfront** (before writing code)
2. **Document** the transfer process in the project scope
3. **Prepare**: Ensure repo is clean, documented, CI/CD independent
4. **Transfer**: GitHub Settings → Transfer → Target organization
5. **Verify**: Client confirms access and all features work
6. **Archive**: Keep a fork or backup if permitted

### What Transfers
- All code, branches, tags
- Issues and pull requests
- Stars and watchers (reset)
- GitHub Actions (may need reconfiguration)

### What Doesn't Transfer
- Secrets and environment variables
- GitHub Pages settings
- Webhooks (need reconfiguration)
- Branch protection rules (need reconfiguration)

---

## Security Checklist

- [ ] Enable 2FA for all organization members
- [ ] Enable dependency scanning (Dependabot)
- [ ] Enable secret scanning
- [ ] Use branch protection on main/production branches
- [ ] Require PR reviews before merge (when team grows)
- [ ] Audit member access quarterly
- [ ] Use least-privilege access principles

---

## Cost Structure

| Plan | Public Repos | Private Repos | Key Features |
|------|-------------|---------------|--------------|
| **Free (Individual)** | Unlimited | Unlimited (3 collaborators) | Basic |
| **Free (Organization)** | Unlimited | Unlimited (3 collaborators) | Basic + teams |
| **Pro (Individual)** | Unlimited | Unlimited | Enhanced features |
| **Team (Organization)** | Unlimited | Unlimited | Advanced security, more Actions minutes |

> Organizations are **free** for public repos — low-risk way to start professional.

---

## Implementation Checklist

### Initial Setup
- [ ] Create organization with professional name
- [ ] Set up organization profile and README
- [ ] Configure security settings (2FA, scanning)
- [ ] Set up billing if needed

### Per-Project
- [ ] Create repo with naming convention
- [ ] Set up branch protection rules
- [ ] Configure CI/CD (GitHub Actions)
- [ ] Create team and assign access (if client work)

### Project Completion
- [ ] Document handover process
- [ ] Transfer repo if client requests
- [ ] Archive or maintain portfolio copies
- [ ] Revoke client access from your org

---

## Common Pitfalls

| Pitfall | Impact | Solution |
|---------|--------|----------|
| Not discussing ownership early | Transfer conflicts | Include in project scope |
| Over-complex permissions | Management overhead | Start simple, add complexity when needed |
| Mixing personal and client code | Professionalism concerns | Separate personal and business orgs |
| Not documenting processes | Inconsistent handling | Create SOPs for common workflows |
| Forgetting to revoke access | Security risk | Quarterly access audits |

---

*This guide covers GitHub organization strategy for SaaS founders and freelancers. Choose the simplest approach that works and evolve as complexity demands.*
