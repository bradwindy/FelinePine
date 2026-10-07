# Changelog

## 2.0.0 (2026-10-07, bradwindy fork)

### Source-breaking

- `LoggingSystem.Category` must be `Sendable`. A `public` enum is never
  implicitly `Sendable`, so declare it: `public enum Category: String, CaseIterable, Sendable`.
- On Swift 6.2 and later `Feline` and `Pine` refine `SendableMetatype`. A conformer
  in a module with default `MainActor` isolation must declare
  `nonisolated static let loggingCategory` (or be `nonisolated`) instead of relying
  on an inferred isolated conformance. In such a module the `LoggingSystem` enum
  and its nested `Category` enum must both be declared `nonisolated` too, or
  `Category`'s inferred `MainActor`-isolated `Hashable` conformance cannot satisfy
  `Category: Hashable & Sendable`.
- Apple platforms only. Linux was advertised but had no `logger` API since 1.0.0.
- Swift tools 6.0 (Xcode 16) or later; one manifest. Deployment targets are
  iOS 17, Mac Catalyst 17, macOS 14, tvOS 17, visionOS 1 and watchOS 10.

### Fixed

- The logger cache is keyed by the `LoggingSystem` type, not by the overridable
  `identifier` string. Two systems sharing an identifier no longer trip a Debug
  assert, rebuild each other's loggers, or get loggers with the wrong subsystem.
- First access from several threads stores one value and returns it to every
  caller. Builders run outside the lock, so a `subsystem` or `allCases` that logs
  through another `LoggingSystem` cannot deadlock. They must not log through their
  own system: that recurses until the stack overflows, as it did before.
- A category missing from `allCases`, or listed twice, no longer traps.
- `public import os` that was only used internally no longer warns; stale
  experimental feature flags are gone from the manifest.
