# PrettyColors

[![Carthage Compatibility](https://img.shields.io/badge/Carthage-✔-f2a77e.svg?style=flat)][carthage]
[![CocoaPods Version](https://img.shields.io/cocoapods/v/PrettyColors.svg?style=flat)][cocoadocs]
[![License](https://img.shields.io/cocoapods/l/PrettyColors.svg?style=flat)][cocoadocs]
[![Platform](https://img.shields.io/cocoapods/p/PrettyColors.svg?style=flat)][cocoadocs]
[carthage]: https://github.com/Carthage/Carthage/
[cocoadocs]: http://cocoadocs.org/docsets/PrettyColors

## Description
`PrettyColors` is a Swift library for styling and coloring text in the Terminal.
The library outputs [ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code) and conforms to [ECMA Standard 48](http://www.ecma-international.org/publications/standards/Ecma-048.htm).

### Example
```swift
import PrettyColors

let redText: String = Color.Wrap(foreground: .red).wrap("A red piece of text.")
println(redText)

Color.Wrap(foreground: .yellow, style: .bold)
Color.Wrap(foreground: .green, background: .black, style: .bold, .underlined)

// 8-bit (256) color support
Color.Wrap(foreground: 114)
Color.Wrap(foreground: 114, style: .bold)
```

**More examples can be found in [the tests](./Tests/UnitTests/PrettyColorsTests.swift).**

### Installation
#### [Carthage](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)
Add the following to your Cartfile:

```ogdl
github "jdhealy/PrettyColors"
```
#### [CocoaPods](https://cocoapods.org)
Add the following to your [Podfile](https://guides.cocoapods.org/using/the-podfile.html):

```ruby
pod 'PrettyColors', :git => 'https://github.com/jdhealy/PrettyColors'
```

You will also need to make sure you're opting into using frameworks:

```ruby
use_frameworks!
```

Then run `pod install` with CocoaPods 0.36 or newer.

## Inspiration
- [`junegunn/ansi256`](https://github.com/junegunn/ansi256/)
- [`tehmaze/ansi`](https://github.com/tehmaze/ansi/)

## License
PrettyColors is released under the [MIT license](https://opensource.org/licenses/MIT). See [LICENSE.md](./LICENSE.md) for details.
