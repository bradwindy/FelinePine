//
//  LoggerCacheTests.swift
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
import os
import Testing

@Suite
internal struct LoggerCacheTests {
  private struct Descriptor: Equatable {
    internal let subsystem: String
    internal let category: String
  }

  private final class Box: Sendable {}

  private enum RepositoryKey {}

  @Test
  internal func loggerLookupBuildsOnceAndNeverReadsIdentifier() {
    for _ in 0..<100 {
      for category in CountingSystem.Category.allCases {
        _ = CountingSystem.logger(forCategory: category)
      }
    }
    #expect(CountingSystem.subsystemReads.value == 1)
    #expect(CountingSystem.identifierReads.value == 0)
  }

  @Test
  internal func distinctSystemsWithSameIdentifierGetOwnLoggers() throws {
    _ = CollidingSystemA.logger(forCategory: .apple)
    _ = CollidingSystemB.logger(forCategory: .banana)
    _ = CollidingSystemA.logger(forCategory: .apricot)
    _ = CollidingSystemB.logger(forCategory: .banana)

    let repository = LoggingSystemRepository.shared
    let cachedA = try #require(
      repository.cachedValue(
        for: CollidingSystemA.self,
        as: [CollidingSystemA.Category: Logger].self
      )
    )
    let cachedB = try #require(
      repository.cachedValue(
        for: CollidingSystemB.self,
        as: [CollidingSystemB.Category: Logger].self
      )
    )
    #expect(Set(cachedA.keys) == Set(CollidingSystemA.Category.allCases))
    #expect(Set(cachedB.keys) == Set(CollidingSystemB.Category.allCases))
  }

  @Test
  internal func systemsSharingIdentifierAndCategoryBuildFromOwnSubsystem() {
    _ = SharedCategorySystemC.logger(forCategory: .shared)
    _ = SharedCategorySystemD.logger(forCategory: .shared)
    _ = SharedCategorySystemC.logger(forCategory: .shared)

    #expect(SharedCategorySystemC.subsystemReads.value == 1)
    // Before the fix D silently reused C's cached loggers (subsystem "nz.test.c").
    #expect(SharedCategorySystemD.subsystemReads.value == 1)
  }

  @Test
  internal func loggersAreBuiltFromSubsystemAndRawValue() {
    let descriptors = OverriddenSystem.makeLoggers(Descriptor.init)
    let expected: [OverriddenSystem.Category: Descriptor] = [
      .first: Descriptor(subsystem: "nz.test.override", category: "first"),
      .second: Descriptor(subsystem: "nz.test.override", category: "second")
    ]
    #expect(descriptors == expected)
  }

  @Test
  internal func loggableResolvesItsOwnCategory() {
    let descriptors = MockSystem.makeLoggers(Descriptor.init)
    #expect(descriptors[MockLoggable.loggingCategory]?.category == "beta")
    #expect(descriptors[MockType.loggingCategory]?.category == "alpha")
    MockLoggable.logger.debug("beta")
  }

  @Test
  internal func categoryMissingFromAllCasesGetsFallbackLogger() {
    #expect(PartialSystem.makeLoggers(Descriptor.init).keys.contains(.unlisted) == false)
    PartialSystem.logger(forCategory: .unlisted).debug("not in allCases")
    PartialSystem.logger(forCategory: .listed).debug("in allCases")
  }

  @Test
  internal func duplicateAllCasesDoNotTrap() {
    let descriptors = DuplicatedSystem.makeLoggers(Descriptor.init)
    #expect(descriptors.count == 2)
    DuplicatedSystem.logger(forCategory: .one).debug("duplicated case")
    DuplicatedSystem.logger(forCategory: .two).debug("single case")
  }

  @Test
  internal func builderMayLogThroughAnotherSystem() {
    ReentrantSystem.logger(forCategory: .outer).debug("built while logging")
    #expect(
      LoggingSystemRepository.shared.cachedValue(
        for: ReentrantSystem.self,
        as: [ReentrantSystem.Category: Logger].self
      )?.count == 1
    )
  }

  @Test
  internal func concurrentFirstAccessLeavesOneCompleteEntry() async {
    await withTaskGroup(of: Void.self) { group in
      for _ in 0..<200 {
        group.addTask {
          for category in ConcurrentSystem.Category.allCases {
            ConcurrentSystem.logger(forCategory: category).debug("concurrent")
          }
        }
      }
    }
    let cached = LoggingSystemRepository.shared.cachedValue(
      for: ConcurrentSystem.self,
      as: [ConcurrentSystem.Category: Logger].self
    )
    #expect(cached?.count == ConcurrentSystem.Category.allCases.count)
  }

  @Test
  internal func concurrentFirstAccessReturnsTheStoredValueToEveryCaller() async {
    let repository = LoggingSystemRepository()
    let builds = Counter()
    let boxes = await withTaskGroup(of: Box.self) { group in
      for _ in 0..<200 {
        group.addTask {
          repository.value(for: RepositoryKey.self) {
            builds.increment()
            return Box()
          }
        }
      }
      var results = [Box]()
      for await box in group {
        results.append(box)
      }
      return results
    }

    let stored = repository.cachedValue(for: RepositoryKey.self, as: Box.self)
    #expect(boxes.count == 200)
    #expect(boxes.allSatisfy { $0 === stored })

    let buildsAfterRace = builds.value
    #expect(buildsAfterRace >= 1)
    let again = repository.value(for: RepositoryKey.self) {
      builds.increment()
      return Box()
    }
    #expect(again === stored)
    #expect(builds.value == buildsAfterRace)
  }

  @Test
  internal func repositoryKeysByTypeNotByValueType() {
    let repository = LoggingSystemRepository()
    let first = repository.value(for: CollidingSystemA.self) { 1 }
    let second = repository.value(for: CollidingSystemB.self) { 2 }
    #expect(first == 1)
    #expect(second == 2)
    #expect(repository.value(for: CollidingSystemA.self) { 3 } == 1)
  }
}
