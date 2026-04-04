### Canonical Layout

Discover the current module layout: `ls packages/modules/src/{module}/`

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
