# Component Testing Strategy — React Native / Expo

> Where component tests fit in the 80/15/5 hierarchy and how to write them.

---

## Position in the Hierarchy

| Layer | SUT | Effort | Doubles | Speed |
|---|---|---|---|---|
| **Handler tests** (command/query handler `handle`) | Business behavior — sociable: real entities + domain services, fake infra ports | 80% | Ultra-light fakes, stubs, spies | ms |
| **Component contract tests** (RNTL) | UI behavior, a11y semantics, callbacks | 15% | `vi.fn()` for callbacks only | ms |
| **Integration / E2E** | Real adapters, critical flows, manual VoiceOver/TalkBack | 5% | None (real impls) | s |

---

## What Component Tests DO and DON'T Test

**DO test (component contract):**

- Accessibility semantics — roles, labels, states (verified via `getByRole`)
- Conditional rendering — error states, empty states, loading
- Callback invocations — `onPress`, `onSubmit`, `onChange` with correct args
- Prop-driven behavior — disabled state, expanded state, variant rendering

**DON'T test (handler responsibility):**

- Business rules ("is this booking cancellable?")
- Data fetching, API calls
- Navigation logic
- Anything that lives in a command/query handler

**Rule:** the component receives pre-computed props from a custom hook. The hook calls the handler. The component never decides business logic.

---

## Query Priority — Accessibility First

| Priority | Query | Verifies | Use when |
|---|---|---|---|
| 1 | `getByRole('button', { name: 'Submit' })` | Role + accessible name | Always — top preference |
| 2 | `getByLabelText('Email address')` | Label association | Form fields |
| 3 | `getByText('No results found')` | Text content | Static non-interactive text |
| 4 | `getByPlaceholderText('Search...')` | Placeholder | Last resort for inputs |
| 5 | `getByTestId('booking-card')` | Test ID | Escape hatch only — means a11y is broken |

**If `getByRole` doesn't find your element, the component is inaccessible — fix the component, not the test.**

---

## `getByRole` Options

```ts
screen.getByRole('button', {
  name: 'Cancel booking',    // accessibilityLabel or text content
  disabled: true,            // accessibilityState.disabled
  selected: false,           // accessibilityState.selected
  checked: true,             // accessibilityState.checked
  busy: false,               // accessibilityState.busy
  expanded: true,            // accessibilityState.expanded
})
```

Matches both `role` prop (RN 0.71+) and `accessibilityRole` prop.

---

## Test Doubles in Component Tests

| Double | When | Example |
|---|---|---|
| `vi.fn()` | Component callback props | `onCancel`, `onSubmit`, `onPress` |
| Fixture factory | Prop data | `createBookingFixture()` |
| **Never** | Business logic, domain services, handlers | — |

`vi.fn()` is acceptable here because component callbacks are **UI contracts** — the component's job is to call them with the right args at the right time. This is fundamentally different from mocking business logic in handler tests.

---

## Example: BookingCard

```tsx
import { render, screen, userEvent } from '@testing-library/react-native'
import { BookingCard } from './booking-card'
import { createBookingFixture } from '../fixtures/create-booking-fixture'

const user = userEvent.setup()

describe('BookingCard', () => {
  const booking = createBookingFixture()
  const onCancel = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders with correct a11y semantics', async () => {
    await render(<BookingCard booking={booking} onCancel={onCancel} />)

    expect(screen.getByRole('header', { name: booking.spaceName })).toBeTruthy()
    expect(screen.getByText(booking.formattedDate)).toBeTruthy()
    expect(screen.getByRole('button', { name: 'Cancel booking' })).toBeTruthy()
  })

  it('calls onCancel with booking id', async () => {
    await render(<BookingCard booking={booking} onCancel={onCancel} />)

    await user.press(screen.getByRole('button', { name: 'Cancel booking' }))

    expect(onCancel).toHaveBeenCalledWith(booking.id)
  })

  it('disables cancel when booking is past', async () => {
    const pastBooking = createBookingFixture({ isPast: true })
    await render(<BookingCard booking={pastBooking} onCancel={onCancel} />)

    expect(
      screen.getByRole('button', { name: 'Cancel booking', disabled: true })
    ).toBeTruthy()
  })

  it('communicates expanded state for details', async () => {
    await render(<BookingCard booking={booking} onCancel={onCancel} />)

    const toggle = screen.getByRole('button', {
      name: 'Show details',
      expanded: false,
    })
    await user.press(toggle)

    expect(
      screen.getByRole('button', { name: 'Hide details', expanded: true })
    ).toBeTruthy()
  })
})
```

---

## Example: Form with Validation Feedback

```tsx
import { render, screen, userEvent } from '@testing-library/react-native'
import { BookingForm } from './booking-form'

const user = userEvent.setup()

describe('BookingForm', () => {
  const onSubmit = vi.fn()

  it('calls onSubmit with form data', async () => {
    await render(<BookingForm onSubmit={onSubmit} />)

    await user.type(screen.getByLabelText('Start date'), '2026-04-01')
    await user.type(screen.getByLabelText('End date'), '2026-04-05')
    await user.press(screen.getByRole('button', { name: 'Book now' }))

    expect(onSubmit).toHaveBeenCalledWith({
      startDate: '2026-04-01',
      endDate: '2026-04-05',
    })
  })

  it('shows error with correct a11y role', async () => {
    await render(<BookingForm onSubmit={onSubmit} error="Dates unavailable" />)

    const alert = screen.getByRole('alert')
    expect(alert).toBeTruthy()
    expect(screen.getByText('Dates unavailable')).toBeTruthy()
  })

  it('disables submit while loading', async () => {
    await render(<BookingForm onSubmit={onSubmit} isLoading />)

    expect(
      screen.getByRole('button', { name: 'Book now', busy: true })
    ).toBeTruthy()
  })
})
```

---

## Architecture Flow

```
Handler Tests (80%)                Component Tests (15%)
┌──────────────────────┐          ┌──────────────────────┐
│ SUT: handler.handle()│          │ SUT: <Component />   │
│                      │          │                      │
│ Real: entities,      │          │ Props: fixture data   │
│   domain services    │          │ Callbacks: vi.fn()    │
│ Fake: infra ports    │          │                      │
│                      │          │ Assert: roles, labels,│
│ Assert: business     │          │   states, callbacks   │
│   outcomes           │          │                      │
└──────────────────────┘          └──────────────────────┘
         │                                 │
         │ handler returns Result          │ hook provides props
         ▼                                 ▼
    Domain Layer                    Custom Hook (glue)
                                        │
                                        ▼
                                   Component (UI box)
```

---

## Checklist — Per Component Test

- [ ] Primary queries are `getByRole` — not `getByTestId`
- [ ] All interactive elements found by role + accessible name
- [ ] State changes verified via `getByRole` options (`disabled`, `checked`, `expanded`, `busy`)
- [ ] Callbacks tested with `vi.fn()` — args verified
- [ ] Fixtures from shared `createXxxFixture()` factories — no floating literals
- [ ] No business logic assertions — only UI contract
- [ ] `userEvent` over `fireEvent` for realistic interaction simulation
- [ ] Error states use `role="alert"` or `accessibilityLiveRegion`

---

## Tools

| Tool | Purpose |
|---|---|
| `@testing-library/react-native` | Component rendering + queries |
| `vitest` | Test runner (never Jest) |
| `eslint-plugin-react-native-a11y` | Lint-time a11y checks |
| `@react-native-ama/core` | Runtime dev-time a11y enforcement |

**Note (RNTL v14+):** `render`, `fireEvent`, and `act` are async — always `await` them. Required for React 19 async rendering.[^1]

[^1]: https://github.com/callstack/react-native-testing-library/releases
