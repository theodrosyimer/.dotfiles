# Architecture Decision Records

This log captures all architectural decisions for the project. Each record documents the context,
decision, and consequences of a significant choice.

| #                                                                       | Decision                                                               | Date       | Status                                                                             |
| ----------------------------------------------------------------------- | ---------------------------------------------------------------------- | ---------- | ---------------------------------------------------------------------------------- |
| [0000](0000-classify-parko-subdomains-and-bounded-contexts.md)          | Classify Parko Subdomains and Bounded Contexts                         | 2026-03-03 | accepted                                                                           |
| [0001](0001-use-modular-monolith-as-default-architecture.md)            | Use Modular Monolith as Default Architecture                           | 2025-01-01 | accepted                                                                           |
| [0002](0002-type-driven-domain-modeling-with-zod-at-boundaries.md)      | Type-Driven Domain Modeling with Zod at Boundaries                     | 2025-01-01 | accepted                                                                           |
| [0003](0003-use-fakes-over-mocks-for-testing.md)                        | Use Fakes Over Mocks for Testing                                       | 2025-01-01 | superseded by [0016](0016-use-ultra-light-test-fakes-over-intelligent-inmemory.md) |
| [0004](0004-use-vertical-slice-architecture-within-modules.md)          | Use Vertical Slice Architecture Within Modules                         | 2025-01-01 | accepted                                                                           |
| [0005](0005-test-business-behavior-at-use-case-boundary.md)             | Test Business Behavior at Use Case Boundary                            | 2025-01-01 | accepted                                                                           |
| [0006](0006-use-vitest-over-jest.md)                                    | Use Vitest Over Jest                                                   | 2025-01-01 | accepted                                                                           |
| [0007](0007-use-gateway-and-acl-for-inter-module-communication.md)      | Use Gateway and ACL for Inter-Module Communication                     | 2025-01-01 | accepted                                                                           |
| [0008](0008-treat-react-as-ui-layer-only.md)                            | Treat React and React Native as UI Layer Only                          | 2025-01-01 | accepted                                                                           |
| [0009](0009-event-source-core-subdomains-by-default.md)                 | Event Source Core Subdomains by Default                                | 2026-03-26 | accepted                                                                           |
| [0010](0010-prohibit-barrel-files-except-package-top-level.md)          | Prohibit Barrel Files Except at Package Top Level                      | 2025-01-01 | accepted                                                                           |
| [0011](0011-use-task-based-api-design-for-cqrs-bounded-contexts.md)     | Use Task-Based API Design for CQRS Bounded Contexts                    | 2026-03-02 | accepted                                                                           |
| [0012](0012-use-state-level-switch-case-for-domain-function-fsms.md)    | Use State-Level Switch/Case for Domain Function FSMs                   | 2026-03-08 | accepted                                                                           |
| [0013](0013-adopt-nullables-selectively-for-infrastructure-gateways.md) | Adopt Shore's Nullable Pattern Selectively for Infrastructure Gateways | 2026-03-13 | accepted                                                                           |
| [0014](0014-keep-domain-layer-null-free-using-adt-read-models.md)       | Keep Domain Layer Null-Free Using ADT Read Models                      | 2026-03-13 | accepted                                                                           |
| [0015](0015-capture-time-in-imperative-shell-via-clock-port.md)         | Capture Time in Imperative Shell via Clock Port                        | 2026-03-14 | accepted                                                                           |
| [0016](0016-use-ultra-light-test-fakes-over-intelligent-inmemory.md)    | Use Ultra-Light Test Fakes Over Intelligent InMemory Implementations   | 2026-03-15 | accepted                                                                           |
| [0017](0017-extract-data-mapper-as-standalone-concern.md)               | Extract Data Mapper as Standalone Concern                              | 2026-03-18 | accepted                                                                           |
| [0018](0018-separate-core-primitives-from-shared-utilities.md)          | Separate Core Primitives from Shared Utilities                         | 2026-03-18 | accepted                                                                           |
| [0019](0019-adopt-emmett-as-event-store-infrastructure.md)             | Adopt Emmett as Event Store Infrastructure                             | 2026-04-02 | proposed                                                                           |

## Statistics

- **Total decisions**: 20
- **Accepted**: 18
- **Superseded**: 1
- **Proposed**: 1
- **Deprecated**: 0

## How to Use

- **Before implementing**: Search for ADRs related to your feature area
- **During code review**: Verify implementation aligns with accepted ADRs
- **When questioning a choice**: Read the ADR's context and alternatives before proposing changes
- **To change a decision**: Create a new ADR that supersedes the existing one — accepted ADRs are
  immutable
