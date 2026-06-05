---
trigger: always_on
---

# Core Design Principles (Concise)

## Fundamental Laws
- **KISS & YAGNI**: Keep it simple. Don't implement features based on speculation about future needs.
- **DRY**: Don't repeat yourself. Use centralized utilities and avoid logic duplication.
- **Maintainability > Short-term UX**: Clean, maintainable code takes precedence over short-term UX gains that create technical debt.

## SOLID Simplified
- **Single Responsibility (SRP)**: One function/module = One reason to change.
- **Dependency Inversion (DIP)**: Depend on abstractions (Interface/Config), not concrete implementations.
- **Composition over Inheritance**: Favor object composition and delegation over deep class hierarchies.

## Code Organization
- **Focused Functions**: Small functions with single purposes (typically 10-50 lines).
- **Module Boundaries**: One feature = One directory.
- **Public API**: Clear public interfaces; internal implementation details must remain private.