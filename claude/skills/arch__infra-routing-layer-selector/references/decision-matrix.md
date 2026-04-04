# Decision Matrix — Reverse Proxy vs Load Balancer vs API Gateway

Reference material for the infra-routing-layer-selector skill. This file contains the full decision framework, tool comparisons, and layered architecture patterns.

---

## 1. The Capabilities Spectrum

These are not three boxes — they're a spectrum. Every tool sits somewhere on this continuum, and many span multiple segments.

```
CAPABILITIES SPECTRUM

  ┌──────────────────┬────────────────────────┬──────────────────────────┐
  │  REVERSE PROXY   │    LOAD BALANCER       │     API GATEWAY          │
  ├──────────────────┼────────────────────────┼──────────────────────────┤
  │  Forward requests│  Traffic distribution  │  Auth / authorization    │
  │  SSL termination │  Health checks         │  Rate limiting (per-tier)│
  │  Caching         │  Failover              │  Request transformation  │
  │  Compression     │  Multiple algorithms   │  API versioning          │
  │  Security (hide) │  L4 / L7 routing       │  Analytics / monitoring  │
  │  Static assets   │  Session persistence   │  Developer portal        │
  └──────────────────┴────────────────────────┴──────────────────────────┘

  ◄─── general purpose ──────────────────────────── API-specific ───►
```

---

## 2. Capability-Requirement Matrix

Use this matrix to map requirements to layers. Check which capabilities the user needs, then identify the minimal set of layers.

```
REQUIREMENT                                    | REV. PROXY | LOAD BAL. | API GATEWAY
───────────────────────────────────────────────┼────────────┼───────────┼────────────
SSL termination                                |     ✅     |     ✅    |     ✅
Caching static content                         |     ✅     |     ❌    |     ❌
GZIP / Brotli compression                      |     ✅     |     ❌    |     ❌
Hide backend server IPs                        |     ✅     |     ✅    |     ✅
Serve static assets                            |     ✅     |     ❌    |     ❌
Distribute traffic across instances            |     ❌     |     ✅    |    ⚠️ *
Health checks / automatic failover             |     ❌     |     ✅    |    ⚠️ *
Session persistence / stickiness               |     ❌     |     ✅    |     ❌
L4 (TCP) load balancing                        |     ❌     |     ✅    |     ❌
L7 (HTTP) content-based routing                |     ❌     |     ✅    |     ✅
Auth / authorization at the edge               |     ❌     |     ❌    |     ✅
Rate limiting (per-client / per-tier)          |     ❌     |     ❌    |     ✅
Request/response transformation                |     ❌     |     ❌    |     ✅
API versioning routing                         |     ❌     |     ❌    |     ✅
Traffic analytics / P95 latency / error rates  |     ❌     |     ❌    |     ✅
Developer portal / API key management          |     ❌     |     ❌    |     ✅

* API gateways can distribute traffic internally, but a dedicated
  load balancer is optimized for high-throughput distribution.
```

---

## 3. Decision Flowchart

Follow this top-to-bottom to determine which layers are needed:

```
DECISION FLOW

  Q1: Do you need SSL termination, caching, or compression?
      YES → You need a REVERSE PROXY (minimum layer)
      NO  → You might still want one for security (hiding backends)

  Q2: Do you run multiple instances of any service?
      YES → You need a LOAD BALANCER
      NO  → Skip for now. Add when scaling.

  Q3: Are you exposing APIs to external developers or third parties?
      YES → You need an API GATEWAY
      NO  → Continue to Q4.

  Q4: Do you need centralized auth, rate limiting, or API versioning?
      YES → You need an API GATEWAY
      NO  → Reverse proxy (+ optional LB) is sufficient.

  Q5: Do you serve static content to global users?
      YES → Consider a CDN in front of everything
      NO  → Reverse proxy caching is sufficient.
```

---

## 4. Layer Definitions

### 4.1 Reverse Proxy

**Purpose**: General-purpose request forwarding with SSL, caching, compression, and security.

```
REVERSE PROXY — Core Capabilities

  Client → [Reverse Proxy] → Backend

  WHAT IT DOES:
    ✅ SSL/TLS termination (offload CPU-intensive encryption)
    ✅ Cache frequently requested responses
    ✅ GZIP/Brotli compress responses
    ✅ Hide backend server topology
    ✅ Serve static files (images, CSS, JS)
    ✅ Basic request routing by URL path

  WHAT IT DOESN'T DO:
    ❌ Distribute traffic across multiple backends intelligently
    ❌ Health check backends and failover
    ❌ Auth, rate limiting, API-specific management
```

### 4.2 Load Balancer

**Purpose**: Distribute incoming requests across multiple backend instances for scalability and availability.

```
LOAD BALANCER — Core Capabilities

  Client → [Load Balancer] → Backend A / Backend B / Backend C

  WHAT IT DOES:
    ✅ Distribute requests across instances
    ✅ Health checks — detect and remove unhealthy backends
    ✅ Failover — route around failed instances
    ✅ Multiple algorithms (round robin, least connections, IP hash, weighted)
    ✅ L4 (TCP) or L7 (HTTP) modes

  WHAT IT DOESN'T DO:
    ❌ API-specific management (auth, rate limiting, versioning)
    ❌ Request/response transformation
    ❌ Per-client or per-tier traffic policies
```

**L4 vs L7 decision:**

```
DECISION — Layer 4 vs Layer 7

CHOOSE L4 WHEN:
  ✅ Maximum throughput is the priority
  ✅ Routing by IP/port is sufficient
  ✅ Non-HTTP protocols (gRPC, raw TCP, WebSocket passthrough)
  ❌ Cannot inspect HTTP headers, cookies, or URL paths

CHOOSE L7 WHEN:
  ✅ Content-based routing needed (URL path, headers, cookies)
  ✅ /api/users → pool A, /api/orders → pool B
  ✅ Need to terminate SSL and inspect HTTP
  ❌ Higher processing overhead than L4

DEFAULT: L7 for most web/API workloads.
         L4 for extreme throughput or non-HTTP traffic.
```

**Load balancing algorithms:**

```
ALGORITHM          | HOW IT WORKS                              | BEST WHEN
Round Robin        | Servers take turns sequentially            | Identical servers, uniform requests
Least Connections  | Route to server with fewest active reqs    | Variable request duration
IP Hash            | Same client IP → same server               | Session stickiness needed *
Weighted           | Proportional distribution by server weight | Mixed server capacities
Random             | Random server selection                    | Large server pools, simplicity

* Stateless architecture (JWT, external session store) is preferred
  over IP hash stickiness in modern systems.
```

### 4.3 API Gateway

**Purpose**: Manage APIs — centralize crosscutting concerns for API exposure.

```
API GATEWAY — Core Capabilities

  Client → [API Gateway] → Service A / Service B / Service C

  WHAT IT DOES:
    ✅ Auth / authorization at the edge
    ✅ Rate limiting (per-client, per-tier, per-endpoint)
    ✅ Request/response transformation (JSON ↔ XML, field stripping)
    ✅ API versioning routing (/v1/users → old, /v2/users → new)
    ✅ Analytics: endpoint usage, P95 latency, error rates
    ✅ Developer portal, API key management
    ✅ Can distribute traffic (but not optimized for it)

  WHAT IT DOESN'T DO:
    ❌ High-throughput traffic distribution (use a dedicated LB)
    ❌ General-purpose caching (use a reverse proxy or CDN)
    ❌ Serve static assets
```

### 4.4 CDN (Bonus Layer)

```
CDN — Globally Distributed Reverse Proxy

  ✅ Cache static content at edge locations worldwide
  ✅ Terminate SSL close to users (lower latency)
  ✅ Absorb traffic spikes (DDoS mitigation)
  ✅ Serve images, CSS, JS, fonts without touching your origin

  WHEN TO ADD:
    → Serving static content to geographically distributed users
    → Need to reduce origin server load significantly
    → DDoS protection is a concern

  WHEN NOT TO ADD:
    → All users are in one region
    → API-only service with no static content
    → Prototype / early stage
```

---

## 5. Tool Comparison

```
TOOL            | PRIMARY ROLE    | ALSO DOES            | NOTES
────────────────┼─────────────────┼──────────────────────┼─────────────────────────
Nginx           | Reverse proxy   | L7 LB, basic rate    | Most common. Upstream
                |                 | limiting, static     | blocks for LB. OpenResty
                |                 | serving              | extends to gateway-like.
────────────────┼─────────────────┼──────────────────────┼─────────────────────────
HAProxy         | Load balancer   | Reverse proxy, L4/L7 | Best pure LB performance.
                |                 |                      | Enterprise: HAProxy EE.
────────────────┼─────────────────┼──────────────────────┼─────────────────────────
Caddy           | Reverse proxy   | Automatic HTTPS, LB  | Zero-config TLS. Great
                |                 |                      | for small deployments.
────────────────┼─────────────────┼──────────────────────┼─────────────────────────
Traefik         | Reverse proxy   | LB, auto-discovery   | Native Docker/K8s
                |                 | (Docker, K8s)        | integration. Dynamic config.
────────────────┼─────────────────┼──────────────────────┼─────────────────────────
Kong            | API gateway     | Rev proxy, LB        | Built on Nginx/OpenResty.
                |                 | (via Nginx)          | Plugin ecosystem. OSS + EE.
────────────────┼─────────────────┼──────────────────────┼─────────────────────────
Tyk             | API gateway     | Rev proxy, LB,       | Go-based. Good analytics.
                |                 | developer portal     | OSS + paid.
────────────────┼─────────────────┼──────────────────────┼─────────────────────────
AWS ALB         | L7 load         | Content-based        | Managed. Integrates with
                | balancer        | routing, WAF         | ECS/EKS/EC2. No API mgmt.
────────────────┼─────────────────┼──────────────────────┼─────────────────────────
AWS NLB         | L4 load         | Ultra-low latency,   | Managed. Static IPs.
                | balancer        | static IPs           | For non-HTTP or extreme TPS.
────────────────┼─────────────────┼──────────────────────┼─────────────────────────
AWS API GW      | API gateway     | Rate limiting, auth, | Managed. Pay-per-request.
                |                 | transformation       | REST + WebSocket + HTTP.
────────────────┼─────────────────┼──────────────────────┼─────────────────────────
Apigee          | API gateway     | Full API lifecycle   | Google Cloud. Enterprise
                |                 | management           | API management.
────────────────┼─────────────────┼──────────────────────┼─────────────────────────
Azure API Mgmt  | API gateway     | Developer portal,    | Azure-native. Policy engine.
                |                 | policies, analytics  |
────────────────┼─────────────────┼──────────────────────┼─────────────────────────
CloudFront      | CDN             | Edge caching, DDoS,  | AWS. Lambda@Edge for
                |                 | SSL termination      | edge compute.
────────────────┼─────────────────┼──────────────────────┼─────────────────────────
Cloudflare      | CDN             | DDoS, WAF, Workers   | Edge compute. Free tier.
                |                 | (edge compute)       | DNS + CDN + security.
```

---

## 6. Layered Architecture Patterns

### Pattern A: Simple (Single Instance)

```
PATTERN A — Single Backend Instance

  Client → [Nginx] → Backend

  Nginx handles: SSL, caching, compression, static assets
  No LB needed (single instance)
  No API gateway needed (single internal client)

  WHEN: Prototype, MVP, low traffic, single client app
```

### Pattern B: Scaled (Multiple Instances)

```
PATTERN B — Multiple Backend Instances

  Client → [Nginx / ALB] → Backend A
                          → Backend B
                          → Backend C

  LB handles: Distribution, health checks, failover
  Often Nginx upstream blocks or a managed ALB

  WHEN: Single service needs horizontal scaling
```

### Pattern C: Microservices (Internal Only)

```
PATTERN C — Multiple Services, Internal Clients Only

  Client → [Nginx] → [LB] → Service A instances
                            → Service B instances
                            → Service C instances

  Nginx: SSL termination, routing by path
  LB: Per-service traffic distribution
  No API gateway: no external developers, auth handled in-app

  WHEN: Microservices architecture, internal frontend only
```

### Pattern D: Public API (Full Stack)

```
PATTERN D — Public API with External Developers

  Client → [CDN] → [API Gateway] → [LB] → Service instances

  CDN: Edge caching, DDoS, SSL close to users
  API Gateway: Auth, rate limiting, versioning, analytics
  LB: Per-service distribution, health checks

  WHEN: Public API, external developers, usage tiers, API monetization
```

---

## 7. Stack-Specific Recommendations

### NestJS Backend

```
NESTJS — Recommended Tool Mapping

  STAGE: Single instance (dev / early prod)
    → Nginx reverse proxy
    → @nestjs/throttler for rate limiting
    → helmet for security headers
    → better-auth for authentication

  STAGE: Multiple instances (scaling)
    → Nginx upstream (or managed ALB)
    → PM2 cluster mode OR Docker replicas
    → Stateless sessions (JWT + external store)

  STAGE: Public API (external developers)
    → Kong (Nginx-based, familiar ecosystem)
    → OR AWS API Gateway (if already on AWS)
    → Dedicated ALB behind the gateway
    → nestjs-pino for service-level logging
    → Gateway-level analytics for traffic insights
```

### Docker / Docker Compose

```
DOCKER — Typical Setup

  STAGE: Development
    → Traefik as reverse proxy (auto-discovers containers)
    → Labels on containers for routing rules
    → No LB needed (single replica per service)

  STAGE: Production (Docker Swarm or Compose)
    → Traefik or Nginx for reverse proxy + LB
    → Docker service replicas for scaling
    → Consider Kong if API management needed
```

### Kubernetes

```
KUBERNETES — Typical Setup

  INGRESS CONTROLLER:
    → Nginx Ingress Controller (most common, reverse proxy + L7 LB)
    → Traefik Ingress Controller (auto-discovery, middleware)
    → Kong Ingress Controller (if API gateway needed at ingress)

  LOAD BALANCING:
    → kube-proxy handles L4 within the cluster (ClusterIP)
    → Ingress controller handles L7 externally
    → Managed cloud LB (ALB, GCP LB) for external traffic

  API GATEWAY:
    → Kong Ingress Controller for gateway-at-ingress pattern
    → OR separate Kong/Tyk deployment behind ingress
    → Ambassador (Envoy-based) for gRPC-heavy workloads
```

---

## 8. Migration Path Template

When recommending infrastructure changes, always include a migration path:

```
MIGRATION PATH — {Project Name}

  CURRENT:
    {Describe current setup}

  NEXT STEP (when {trigger condition}):
    {What to add and why}

  FUTURE (when {trigger condition}):
    {Full target architecture}

  RULE: Only move to the next step when the trigger condition is met.
        Don't pre-build infrastructure for problems you don't have.
```
