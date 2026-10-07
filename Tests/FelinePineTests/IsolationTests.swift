//
//  IsolationTests.swift
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
import Testing

/// A `MainActor`-isolated type whose conformance must still be nonisolated.
@MainActor
internal struct MainActorLoggable: Loggable {
  internal typealias LoggingSystemType = MockSystem

  internal nonisolated static let loggingCategory: MockSystem.Category = .gamma
}

@Suite
internal struct IsolationTests {
  /// Captures a generic `Loggable` metatype in a `@Sendable` closure, which Swift
  /// 6.2 allows only when the protocol guarantees `SendableMetatype`.
  private static func detachedCategory<T: Loggable>(
    of _: T.Type
  ) async -> T.LoggingSystemType.Category {
    await Task.detached {
      T.logger.debug("detached generic access")
      return T.loggingCategory
    }
    .value
  }

  @Test
  internal func genericLoggableIsUsableFromDetachedTask() async {
    #expect(await Self.detachedCategory(of: MockLoggable.self) == .beta)
    #expect(await Self.detachedCategory(of: PublicLoggable.self) == .data)
  }

  @Test
  internal func mainActorTypeLogsOffTheMainActor() async {
    let category = await Task.detached {
      MainActorLoggable.logger.debug("detached MainActor type")
      return MainActorLoggable.loggingCategory
    }
    .value
    #expect(category == .gamma)
    #expect(await Self.detachedCategory(of: MainActorLoggable.self) == .gamma)
  }
}
