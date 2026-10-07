//
//  LoggingSystem.swift
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

#if !canImport(os)
  #error("FelinePine requires an Apple platform: it logs through os.Logger.")
#endif

public import os

/// Defines the logging categories for your application.
public protocol LoggingSystem: Sendable {
  /// Logging categories available to types in the application.
  ///
  /// Categories are cached in a process-wide store and handed to every thread
  /// and actor, so they must be `Sendable`. A `public` enum is never implicitly
  /// `Sendable`, so declare it: `public enum Category: String, CaseIterable, Sendable`.
  associatedtype Category: Hashable & RawRepresentable & Sendable
    where Category.RawValue == String

  static var identifier: String { get }

  /// Subsystem to use for each ``Logger``.
  /// By default, this is `Bundle.main.bundleIdentifier`.
  ///
  /// It is read while the system's loggers are built, so it must not log
  /// through this same system (that recurses without end). Logging through
  /// another ``LoggingSystem`` is fine.
  static var subsystem: String { get }

  /// Fetches the correct logger based on the category.
  static func logger(forCategory category: Category) -> Logger
}
