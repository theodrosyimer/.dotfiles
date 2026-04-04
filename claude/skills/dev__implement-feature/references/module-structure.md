### Canonical Layout

```
packages/modules/src/{module}/
├── domain/                          # Pure business logic. DEPENDS ON: shared only.
│   ├── schemas/                     # Zod schemas (at module boundaries only)
│   ├── entities/                    # Domain entities with business rules
│   ├── ports/                       # Interface definitions (repositories, services)
│   ├── services/                    # Domain services (pure, stateless)
│   ├── events/                      # Domain events
│   ├── exceptions/                  # Domain exceptions
│   └── value-objects/               # Immutable value objects
├── slices/{feature}/                # Vertical slices. DEPENDS ON: own domain, other modules' contracts/ ONLY.
│   ├── {feature}.handler.ts         # Handler implementation (CommandHandler or QueryHandler)
│   ├── {feature}.handler.test.ts    # Acceptance test
│   └── fixtures/                    # Fixture factories for this feature
├── infrastructure/                  # Adapters. DEPENDS ON: own domain, own features.
│   ├── adapters/                   # ACLs for external bounded contexts
│   ├── repositories/               # Real (drizzle-*) + ultra-light fakes side-by-side
│   ├── gateways/                   # Real + fake gateway impls side-by-side
│   └── event-store/                # Real + fakes + integration tests side-by-side
├── shared/                          # Intra-module shared code (optional)
└── contracts/                       # Public Gateway + DTOs. DEPENDS ON: own module layers only.
    ├── {module}.gateway.ts          # Public API for other modules
    └── dtos/                        # Data Transfer Objects (contracts)

packages/modules/src/shared/         # Cross-module base utilities (Entity, Executable, DomainException)
```

Infrastructure subfolders group fakes alongside concrete siblings — no separate `fakes/` folder.
Ultra-light fakes (Azerhad-style): no internal state, test controls everything.

### Dependency Rules

```
DEPENDENCY DIRECTION:
  app → module contracts/ → slices/ → domain/
                                  ↑
                           infrastructure/

  shared/ → NOTHING (base utilities: Entity, Executable, DomainException)

INTER-MODULE COMMUNICATION:
  ✅ slices/ → other module contracts/        (Gateway returns DTOs, never entities)
  ❌ slices/ → other module domain/          (breaks bounded context encapsulation)
  ❌ slices/ → other module slices/          (creates hidden coupling between slices)
  ❌ slices/ → other module infrastructure/  (leaks adapter implementation details)
  ❌ domain/   → slices/                     (inner layer must not know outer layer)
  ❌ domain/   → infrastructure/               (domain defines ports, never implementations)
  ❌ shared/   → any module                    (shared is a leaf dependency)
```
