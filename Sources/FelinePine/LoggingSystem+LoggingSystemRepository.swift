//
//  LoggingSystem+LoggingSystemRepository.swift
//  FelinePine
//
//  Created by Leo Dion.
//  Copyright © 2024 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
public import os

/// Process-wide cache of each ``LoggingSystem``'s loggers.
///
/// Entries are keyed by the system's type (`ObjectIdentifier` of its metatype),
/// never by ``LoggingSystem/identifier``: that is a user-overridable string, so two
/// systems could share it.
///
/// The builder runs outside the lock. It calls conformer code (`subsystem`,
/// `allCases`, `Logger.init`) which may itself log, so the lock is never held while
/// it runs and does not need to be recursive. If two threads miss at once both may
/// build, but the first value stored wins and every caller gets that one.
internal final class LoggingSystemRepository: @unchecked Sendable {
  internal static let shared = LoggingSystemRepository()

  private let lock = NSLock()
  private var items = [ObjectIdentifier: Any]()

  internal init() {}

  /// Returns the cached value for `system`, building and storing it on first use.
  internal func value<Value>(
    for system: Any.Type,
    build: () -> Value
  ) -> Value {
    let key = ObjectIdentifier(system)
    if let cached = lock.withLock({ items[key] }) as? Value {
      return cached
    }
    let built = build()
    return lock.withLock {
      if let existing = items[key] as? Value {
        return existing
      }
      items[key] = built
      return built
    }
  }

  /// The value currently cached for `system`, if any. Test seam.
  internal func cachedValue<Value>(
    for system: Any.Type,
    as _: Value.Type = Value.self
  ) -> Value? {
    lock.withLock { items[ObjectIdentifier(system)] } as? Value
  }
}

extension LoggingSystem {
  /// A readable name for the system, by default its fully qualified type name.
  ///
  /// Used only as the ``subsystem`` fallback when the process has no bundle
  /// identifier. It need not be unique: loggers are cached per type.
  public static var identifier: String {
    String(reflecting: Self.self)
  }

  /// By default, this is `Bundle.main.bundleIdentifier`, falling back to ``identifier``.
  public static var subsystem: String {
    Bundle.main.bundleIdentifier ?? identifier
  }
}

extension LoggingSystem where Category: CaseIterable {
  private static var loggers: [Category: Logger] {
    LoggingSystemRepository.shared.value(for: Self.self) {
      Self.makeLoggers { subsystem, category in
        Logger(subsystem: subsystem, category: category)
      }
    }
  }

  /// If ``Category`` implements `CaseIterable`, ``LoggingSystem`` can automatically
  /// iterate over the cases and automatically create the ``Logger`` objects needed.
  ///
  /// The loggers are built once per system and cached. A category missing from
  /// `allCases` gets a logger built on demand rather than trapping.
  ///
  /// Each call takes a short lock. On a hot path, cache the logger in the
  /// concrete type: `private static let log = Self.logger`.
  public static func logger(forCategory category: Category) -> Logger {
    loggers[category] ?? Logger(subsystem: Self.subsystem, category: category)
  }

  /// Builds one value per case of `allCases` from the system's subsystem and the
  /// case's raw value. Duplicate cases keep the first value. Test seam: `Logger`
  /// exposes neither its subsystem nor its category.
  internal static func makeLoggers<Value>(
    _ make: (_ subsystem: String, _ category: String) -> Value
  ) -> [Category: Value] {
    let subsystem = Self.subsystem
    return Dictionary(
      Category.allCases.map { ($0, make(subsystem, $0.rawValue)) },
      uniquingKeysWith: { first, _ in first }
    )
  }
}
