---
name: infra-routing-layer-selector
description: "Help decide which infrastructure routing layer to use: reverse proxy, load balancer, API gateway, CDN, or a combination. Use this skill whenever the user discusses, plans, or questions traffic routing architecture — even if they don't use the exact terms. Trigger on phrases like 'should I use nginx or kong', 'do I need a load balancer', 'how should traffic reach my backend', 'API gateway vs reverse proxy', 'where should auth/rate limiting live', 'how to expose my API publicly', 'need SSL termination', 'scaling my backend', 'adding health checks', or any infrastructure decision involving request routing between clients and servers. Also trigger when the user is setting up deployment architecture, choosing between AWS ALB/NLB/API Gateway, deciding where crosscutting concerns (auth, rate limiting, monitoring) should live, or evaluating tools like Nginx, HAProxy, Kong, Traefik, Caddy, Tyk, or Apigee."
---

# Infrastructure Routing Layer Selector

Help developers choose the right combination of reverse proxy, load balancer, and API gateway for their architecture. These three are not competing categories — they form a **spectrum of capabilities** that often work together.

## When This Skill Applies

This skill applies whenever the decision involves **how requests travel from clients to backend services**. The user might be asking about a single layer ("do I need a load balancer?") or the full stack ("how should I architect my request pipeline?").

## Skill Contents

```
infra-routing-layer-selector/
├── SKILL.md                              ← You are here
└── references/
    └── decision-matrix.md                ← Full decision matrix, tool comparison, layered patterns
```

**Before making a recommendation, read `references/decision-matrix.md`.** It contains the decision matrix, tool comparison, and layered architecture patterns you need to give accurate advice.

---

## Process

### Step 1 — Understand the Context

Before recommending anything, gather these facts about the user's system. Check the codebase, project knowledge, or ask:

1. **What's the backend?** (NestJS, Express, Django, Go, etc.)
2. **How many instances?** (single server, multiple, auto-scaling)
3. **Who are the clients?** (own frontend only, external developers, mobile apps, third parties)
4. **What crosscutting concerns exist?** (auth, rate limiting, transformation, versioning, monitoring)
5. **What's the current setup?** (bare metal, Docker, Kubernetes, managed cloud)
6. **What's the growth trajectory?** (prototype, early production, scaling)

### Step 2 — Read the Decision Matrix

Read `references/decision-matrix.md` to load the full decision framework. Use it to match the user's context to the right combination of layers.

### Step 3 — Recommend Layers, Not Tools First

Start by recommending **which layers** are needed and why. Then suggest specific tools that fit the user's stack. The recommendation should follow this structure:

```
RECOMMENDATION — {User's Context}

CURRENT NEEDS:
  ✅ {Layer}: {why it's needed}
  ❌ {Layer}: {why it's NOT needed yet}

RECOMMENDED SETUP:
  {Diagram showing the request flow}

TOOL CHOICES:
  {Layer} → {Tool} — {why this tool fits}

MIGRATION PATH:
  {Current} → {Next step} → {Future state}
```

### Step 4 — Address the "Spectrum Problem"

Users often ask "should I use X or Y?" when the real answer is "both, at different points in the request pipeline." Explain where each layer sits and why they're complementary, not competing. Reference the capabilities spectrum from the decision matrix.

### Step 5 — Warn About Over-Engineering

Always check whether the user actually needs the complexity they're asking about. A single NestJS instance behind Nginx doesn't need an API gateway. A prototype doesn't need a CDN. The principle: **match infrastructure to actual requirements, not anticipated ones.**

---

## Key Principles

1. **Layers are complementary, not competing.** A reverse proxy, load balancer, and API gateway can coexist in the same request pipeline, each handling what it does best.

2. **The spectrum matters.** Reverse proxy → Load balancer → API gateway is a continuum of capabilities. Tools blur the lines (Nginx can load balance, Kong is an API gateway on top of Nginx). Focus on capabilities needed, not tool categories.

3. **Start simple, add layers when pain appears.** Don't add an API gateway until you need auth at the edge or per-client rate limits. Don't add a load balancer until one instance can't handle traffic.

4. **Crosscutting concerns drive the decision.** If auth, rate limiting, and monitoring are duplicated across services, that's the signal for an API gateway. If a single server is a bottleneck, that's the signal for a load balancer.

5. **Layer 4 vs Layer 7 matters.** If routing needs to inspect HTTP content (URL path, headers), you need Layer 7. If raw TCP throughput is the priority, Layer 4 is faster.

---

## Common Mistakes to Flag

```
ANTI-PATTERNS:

❌ Adding an API gateway for a single internal client
   → Use @nestjs/throttler or middleware instead until external clients appear

❌ Using Layer 4 load balancing when content-based routing is needed
   → L4 can't read URLs or headers; use L7 (ALB, Nginx upstream with location blocks)

❌ Duplicating auth/rate limiting across every microservice
   → Centralize at the API gateway edge

❌ Skipping the load balancer and relying on API gateway for distribution
   → API gateways can distribute but dedicated LBs are optimized for it

❌ Adding a CDN before having traffic that justifies it
   → CDN adds complexity; a reverse proxy with caching is sufficient for small scale

❌ Choosing tools by category instead of capabilities
   → "I need a reverse proxy" is less useful than "I need SSL termination and caching"
```

---

## Style

- Use structured text diagrams (ASCII boxes, arrows, ✅/❌ markers) for architecture recommendations
- Always include a migration path showing current → next step → future state
- When recommending tools, explain why the tool fits the user's specific stack
- Don't just list features — connect each layer to a specific problem the user has
