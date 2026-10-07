//
//  CategorySendableTests.swift
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

@Suite
internal struct CategorySendableTests {
  private static func requireSendable<T: Sendable>(_: T.Type) -> Bool {
    true
  }

  /// Compiles only if the protocol itself guarantees `Category: Sendable`.
  private static func categoryIsSendable<System: LoggingSystem>(_: System.Type) -> Bool {
    requireSendable(System.Category.self)
  }

  @Test
  internal func everySystemCategoryIsSendable() {
    #expect(Self.categoryIsSendable(MockSystem.self))
    #expect(Self.categoryIsSendable(PublicSystem.self))
  }

  @Test
  internal func publicCategoryWorksAsStaticLet() async {
    #expect(PublicLoggable.loggingCategory == .data)
    let category = PublicLoggable.loggingCategory
    let roundTripped = await Task.detached { category }.value
    #expect(roundTripped == .data)
    PublicLoggable.logger.debug("public static let conformer")
  }
}
