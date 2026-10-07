# ``FelinePine``

**FelinePine** provides an easy to use API for setting up logging and log categories across your architecture.

## Overview

![Feline on a Pine Tree Branch Logo](FelinePine.png)

### Requirements 

**Apple platforms only** (FelinePine logs through `os.Logger`)

- Xcode 16 or later
- Swift 6.0 or later (the package builds in Swift 5 or Swift 6 language mode)
- Deployment targets: iOS 17, Mac Catalyst 17, macOS 14, tvOS 17, visionOS 1, watchOS 10

### Installation

Use the Swift Package Manager to install this library via the repository url:

```
https://github.com/brightdigit/FelinePine.git
```

Use version up to `1.0.0`.

## Usage

### Getting Started

Create a `LoggingSystem` which defines the categories:

```swift
public enum BushelLogging: LoggingSystem {
  public enum Category: String, CaseIterable, Sendable {
    case library
    case data
    case view
    case machine
    case application
    case observation
    case market
  }
}
```

The `Category` enum inside must have a `RawType` of `String` and be `Sendable`
(a `public` enum is never implicitly `Sendable`, so declare it).
Additionally if you wish to take advantage of automatically created `Logger` object, 
then you should also have to implment `CaseIterable`.

Now to use your new `LoggingSystem` in any type:

1. Implement `Feline` and `Pine` 
2. Define your `LoggingSystem`
3. Define the `LoggingSystem.Category`

```swift
internal struct VirtualMachine: Loggable {
  internal typealias LoggingSystemType = BushelLogging

  internal static let loggingCategory: BushelLogging.Category = .machine
  
  func run () {
    Self.logger.debug("Starting Run")
    ...
  }

  ...
}
```

### Using the `Loggable` type

You can simplify by using the `Loggable` protocol to create protocol to use throughout your codebase:

```swift
public protocol BushelLoggable: FelinePine.Loggable 
  where Self.LoggingSystemType == BushelLogging {}
```

Now you can simply use the _new_ `Loggable` type:

```swift
internal struct VirtualMachine: BushelLoggable {
  internal static let loggingCategory: BushelLogging.Category = .machine

  func run () {
    Self.logger.debug("Starting Run")
    ...
  }
}
```

### License 

This code is distributed under the MIT license. See the [LICENSE](https://github.com/brightdigit/FelinePine/LICENSE) file for more info.
