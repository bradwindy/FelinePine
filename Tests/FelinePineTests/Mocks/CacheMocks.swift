//
//  CacheMocks.swift
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

@testable import FelinePine

// Every test that touches the process-wide cache uses its own system type,
// because the cache cannot be reset and Swift Testing runs tests in parallel.

/// Counts `identifier` and `subsystem` evaluations.
internal enum CountingSystem: LoggingSystem {
  internal enum Category: String, CaseIterable {
    case one
    case two
    case three
  }

  internal static let identifierReads = Counter()
  internal static let subsystemReads = Counter()

  internal static var identifier: String {
    identifierReads.increment()
    return "counting"
  }

  internal static var subsystem: String {
    subsystemReads.increment()
    return "nz.test.counting"
  }
}

/// Shares its `identifier` with ``CollidingSystemB`` but has its own categories.
internal enum CollidingSystemA: LoggingSystem {
  internal enum Category: String, CaseIterable {
    case apple
    case apricot
  }

  internal static var identifier: String {
    "shared-identifier"
  }
}

/// Shares its `identifier` with ``CollidingSystemA`` but has its own categories.
internal enum CollidingSystemB: LoggingSystem {
  internal enum Category: String, CaseIterable {
    case banana
  }

  internal static var identifier: String {
    "shared-identifier"
  }
}

internal enum SharedCategory: String, CaseIterable {
  case shared
}

/// Shares both its `identifier` and its `Category` type with ``SharedCategorySystemD``.
internal enum SharedCategorySystemC: LoggingSystem {
  internal typealias Category = SharedCategory

  internal static let subsystemReads = Counter()

  internal static var identifier: String {
    "shared-category"
  }

  internal static var subsystem: String {
    subsystemReads.increment()
    return "nz.test.c"
  }
}

/// Shares both its `identifier` and its `Category` type with ``SharedCategorySystemC``.
internal enum SharedCategorySystemD: LoggingSystem {
  internal typealias Category = SharedCategory

  internal static let subsystemReads = Counter()

  internal static var identifier: String {
    "shared-category"
  }

  internal static var subsystem: String {
    subsystemReads.increment()
    return "nz.test.d"
  }
}

/// `allCases` leaves out ``Category/unlisted``.
internal enum PartialSystem: LoggingSystem {
  internal enum Category: String, CaseIterable {
    case listed
    case unlisted

    internal static var allCases: [Self] {
      [.listed]
    }
  }
}

/// `allCases` repeats ``Category/one``.
internal enum DuplicatedSystem: LoggingSystem {
  internal enum Category: String, CaseIterable {
    case one
    case two

    internal static var allCases: [Self] {
      [.one, .one, .two]
    }
  }
}

/// Logs through another system while its own loggers are being built.
internal enum ReentrantSystem: LoggingSystem {
  internal enum Category: String, CaseIterable {
    case outer
  }

  internal static var subsystem: String {
    ReentrantHelperSystem.logger(forCategory: .inner).debug("building ReentrantSystem")
    return "nz.test.reentrant"
  }
}

internal enum ReentrantHelperSystem: LoggingSystem {
  internal enum Category: String, CaseIterable {
    case inner
  }
}
