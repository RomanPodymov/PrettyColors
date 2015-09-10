
import PrettyColors
import Foundation
import XCTest

class PrettyColorsTests: XCTestCase {

	override func setUp() {
		super.setUp()
	}

	override func tearDown() {
		super.tearDown()
	}
	
	func test_basics() {
		let redText: String = Color.Wrap(foreground: .Red).wrap("A red piece of text.")
		print(redText)
		
		_ = ((
			Color.Wrap(foreground: .Yellow, style: .Bold),
			Color.Wrap(foreground: .Green, background: .Black, style: .Bold, .Underlined),
			
			// 8-bit (256) color support
			Color.Wrap(foreground: 114),
			Color.Wrap(foreground: 114, style: .Bold)
		))
	}

	func test_problem_SingleStyleParameter() {
		/*
			As of `swiftlang-700.0.57.3`, the following statement errors:
			«Ambiguous use of 'init(foreground:background:style:)'»
		*/
		// Color.Wrap(style: .Bold)
		
		_ = ((
			// Workarounds:
			Color.Wrap(foreground: nil as UInt8?, style: .Bold),
			Color.Wrap(foreground: nil as Color.Named.Color?, style: .Bold),
			[StyleParameter.Bold] as Color.Wrap,
			Color.Wrap(styles: .Bold),
			
			// Multiple
			Color.Wrap(styles: .Bold, .Blink)
		))
	}
	
	func test_problem_TypeInference() {

		// As of `swiftlang-700.0.57.3`, this doesn't get type-inferred properly.
		/*
		Color.Wrap(
			parameters: [
				Color.Named(foreground: .Green),
				Color.EightBit(foreground: 114),
				StyleParameter.Bold
			]
		)
		*/
		
		_ = ((
			// Workarounds:
			Color.Wrap(
				parameters: [
					Color.Named(foreground: .Green),
					Color.EightBit(foreground: 114),
					StyleParameter.Bold
				] as [Color.Wrap.Element]
			),

			Color.Wrap(
				parameters: [
					Color.Named(foreground: .Green),
					Color.EightBit(foreground: 114),
					StyleParameter.Bold
				] as [Parameter]
			),

			[
				Color.Named(foreground: .Green),
				Color.EightBit(foreground: 114),
				StyleParameter.Bold
			] as Color.Wrap
		))
	}

	func testImmutableFilterOrMap() {
		let redBold = Color.Wrap(foreground: .Red, style: .Bold)
		let redItalic = Color.Wrap(foreground: .Red, style: .Italic)
		
		// Filter
		XCTAssert(
			redBold == redItalic
				.filter { $0 != StyleParameter.Italic }
				+ [ StyleParameter.Bold ]
		)
		
		// Map
		XCTAssert(
			// `ArrayLiteralConvertible` inferred
			[] + redItalic
				.map {
					switch $0 as? StyleParameter {
						case .Some: /* replace value */ return StyleParameter.Bold
						case .None: /* same value */ return $0
					}
				}
				== redBold
		)
	}

	func testEmptyWrap() {
		XCTAssert(
			Color.Wrap(parameters: []).code.enable == "",
			"Wrap with no parameters wrapping an empty string should return an empty SelectGraphicRendition."
		)
		XCTAssert(
			Color.Wrap(parameters: []).wrap("") == "",
			"Wrap with no parameters wrapping an empty string should return an empty string."
		)
	}
	
	func testMulti() {
		let multi = [
			Color.EightBit(foreground: 227),
			Color.Named(foreground: .Green, brightness: .NonBright)
		] as Color.Wrap
		XCTAssert(
			multi.code.enable ==
			ECMA48.controlSequenceIntroducer + "38;5;227" + ";" + "32" + "m"
		)
		XCTAssert(
			multi.code.disable ==
			ECMA48.controlSequenceIntroducer + "0" + "m"
		)
	}

	func testLetWorkflow() {
		let redOnBlack = Color.Wrap(foreground: .Red, background: .Black)
		let boldRedOnBlack: Color.Wrap = redOnBlack + [ StyleParameter.Bold ] as Color.Wrap
		
		XCTAssert(
			boldRedOnBlack == Color.Wrap(foreground: .Red, background: .Black, style: .Bold)
		)
		XCTAssert(
			[
				boldRedOnBlack,
				Color.Wrap(foreground: .Red, background: .Black, style: .Bold)
			].reduce(true) {
				(previous, value) in
				return previous && value.parameters.reduce(true) {
					(previous, value) in
					// For some reason, referencing `value` avoids the
					// `Expression was too complex to be solved in reasonable time` 
					// error for the returned expression… 😕
					_ = value
					return previous && (
						value == Color.Named(foreground: .Red) as Parameter ||
						value == Color.Named(background: .Black) as Parameter ||
						value == StyleParameter.Bold
					)
				}
			} == true
		)
	}

	
	func testAppendStyleParameter() {
		let red = Color.Wrap(foreground: .Red)
		
		let _ = { (wrap: Color.Wrap) -> Void in
			var formerlyRed = wrap
			formerlyRed.append(StyleParameter.Bold)
			XCTAssert(
				formerlyRed == Color.Wrap(foreground: .Red, style: .Bold)
			)
		}(red)
		
		let _ = { (wrap: Color.Wrap) -> Void in
			var formerlyRed = wrap
			formerlyRed.append(style: .Bold)
			XCTAssert(
				formerlyRed == Color.Wrap(foreground: .Red, style: .Bold)
			)
		}(red)
		
		XCTAssert(
			red + Color.Wrap(styles: .Bold) == Color.Wrap(foreground: .Red, style: .Bold)
		)
		
		// Multiple
		let _ = { (wrap: Color.Wrap) -> Void in
			var formerlyRed = wrap
			formerlyRed.append(StyleParameter.Bold)
			formerlyRed.append(StyleParameter.Italic)
			XCTAssert(
				formerlyRed == Color.Wrap(foreground: .Red, style: .Bold, .Italic)
			)
		}(red)
		
		let _ = { (wrap: Color.Wrap) -> Void in
			var formerlyRed = wrap
			formerlyRed.append(style: .Bold, .Italic)
			XCTAssert(
				formerlyRed == Color.Wrap(foreground: .Red, style: .Bold, .Italic)
			)
		}(red)

		XCTAssert(
			red + Color.Wrap(styles: .Bold, .Italic) == Color.Wrap(foreground: .Red, style: .Bold, .Italic)
		)
	}

	func testMutableAppend() {
		var formerlyRed = Color.Wrap(foreground: .Red)
		let redBlackBackground = Color.Wrap(foreground: .Red, background: .Black)
		
		
		formerlyRed.append( Color.Named(background: .Black) )
		
		XCTAssert(
			formerlyRed == redBlackBackground
		)
	}
	
	//------------------------------------------------------------------------------
	// MARK: - Foreground/Background
	//------------------------------------------------------------------------------
	
	func testSetForeground() {
		var formerlyRed = Color.Wrap(foreground: .Red)
		formerlyRed.foreground = Color.EightBit(foreground: 227) // A nice yellow
		XCTAssert(
			formerlyRed == Color.Wrap(foreground: 227)
		)
	}
		
	func testSetForegroundToNil() {
		var formerlyRed = Color.Wrap(foreground: .Red)
		formerlyRed.foreground = nil
		
		XCTAssert(
			formerlyRed == Color.Wrap(foreground: nil as Color.Named.Color?)
		)
		XCTAssert(
			formerlyRed == Color.Wrap(foreground: nil as UInt8?)
		)
	}

	func testSetForegroundToParameter() {
		var formerlyRed = Color.Wrap(foreground: .Red)
		formerlyRed.foreground = StyleParameter.Bold
		
		XCTAssert( formerlyRed == [StyleParameter.Bold] as Color.Wrap )

	}
	
	func testTransformForeground() {
		var formerlyRed = Color.Wrap(foreground: .Red)
		formerlyRed.foreground { (color: ColorType) -> ColorType in
			return Color.EightBit(foreground: 227) // A nice yellow
		}
		XCTAssert( formerlyRed == Color.Wrap(foreground: 227) )
	}

	func testTransformForeground2() {
		var formerlyRed = Color.Wrap(foreground: 124)
		formerlyRed.foreground { (color: ColorType) -> ColorType in
			if let color = color as? Color.EightBit {
				var soonYellow = color
				soonYellow.color += (227 as UInt8 - 124)
				return soonYellow
			} else { return color }
		}
		XCTAssert( formerlyRed == Color.Wrap(foreground: 227) )
	}
	
	func testTransformForeground2_withGuard() {
		var formerlyRed = Color.Wrap(foreground: 124) // will soon be yellow…
		formerlyRed.foreground { (color: ColorType) -> ColorType in
			guard let eight·bit·color = color as? Color.EightBit else { return color }
			
			return Color.EightBit(
				foreground: UInt8.addWithOverflow(eight·bit·color.color, 227 - 124).0
			)
		}
		XCTAssert( formerlyRed == Color.Wrap(foreground: 227) )
	}
	
	func testTransformForegroundWithVar() {
		var formerlyRed = Color.Wrap(foreground: .Red)
		formerlyRed.foreground { (color: ColorType) -> ColorType in
			if let namedColor = color as? Color.Named {
				var soonYellow = namedColor
				soonYellow.color = .Yellow
				return soonYellow
			} else { return color }
		}
		XCTAssert( formerlyRed == Color.Wrap(foreground: .Yellow) )
	}

	func testTransformForegroundToBright() {
		var formerlyRed = Color.Wrap(foreground: .Red)
		formerlyRed.foreground { (color: ColorType) -> ColorType in
			var clone = color as! Color.Named
			clone.brightness.toggle()
			return clone
		}
		
		let brightRed = [
			Color.Named(foreground: .Red, brightness: .Bright)
		] as Color.Wrap
		
		XCTAssert( formerlyRed == brightRed )
	}
	
	func testComputedVariableForegroundEquality() {
		XCTAssert(
			Color.Named(foreground: .Red) == Color.Wrap(foreground: .Red).foreground! as! Color.Named
		)
	}

	func testEightBitForegroundBackgroundDifference() {
		let foreground = Color.Named(foreground: .Green).code.enable
		let background = Color.Named(background: .Green).code.enable
		
		let difference = zip(foreground, background)
			.map {
				$0 as (foreground: UInt8, background: UInt8)
			}
			.reduce(0 as UInt8) { sum, values in
				return sum + values.background - values.foreground
			}
		
		XCTAssert( difference == 10 )
	}

	func testNamedForegroundBackgroundDifference() {
		let foreground = Color.Named(foreground: .Green).code.enable
		let background = Color.Named(background: .Green).code.enable
		
		let difference = zip(foreground, background)
			.map {
				$0 as (foreground: UInt8, background: UInt8)
			}
			.reduce(0 as UInt8) { sum, values in
				return sum + values.background - values.foreground
			}
		
		XCTAssert( difference == 10 )
	}
	
	func testNamedBrightnessDifference() {
		let non·bright = Color.Named(foreground: .Green).code.enable
		let bright = Color.Named(foreground: .Green, brightness: .Bright).code.enable
		
		let difference = zip(non·bright, bright)
			.map {
				$0 as (non·bright: UInt8, bright: UInt8)
			}
			.reduce(0 as UInt8) { sum, values in
				return sum + values.bright - values.non·bright
			}

		
		XCTAssert( difference == 60 )
	}
	
	//------------------------------------------------------------------------------
	// MARK: - Zap
	//------------------------------------------------------------------------------
	
	func testZapAllStyleParameters() {
		
		let red = Color.Named(foreground: .Red)
		let niceColor = Color.EightBit(foreground: 114)
		
		let iterables: Array<Array<Parameter>> = [
			[red],
			[niceColor],
		]
	
		for parameters in iterables {

			let wrap = Color.Wrap(parameters: parameters)
			
			for i in stride(from: 1 as UInt8, through: 55, by: 1) {
				if let parameter = StyleParameter(rawValue: i) {
					for wrapAndSuffix in [
						(wrap, "normal"),
						(wrap + [ StyleParameter.Bold ] as Color.Wrap, "bold"),
						(wrap + [ StyleParameter.Italic ] as Color.Wrap, "italic"),
						(wrap + [ StyleParameter.Underlined ] as Color.Wrap, "underlined")
					] {
						let wrap = (wrapAndSuffix.0 + [parameter] as Color.Wrap)
						let suffix = wrapAndSuffix.1
						let formattedNumber = NSString(format: "%02d", i) as String

						print("• " + wrap.wrap("__|øat·•ªº^∆©|__") + " \(formattedNumber) + \(suffix)")
					}
				}
			}
		}
	}

}
