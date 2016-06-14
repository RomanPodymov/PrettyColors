/* begin extension of color */ extension Color {

//------------------------------------------------------------------------------
// MARK: - Wrap
//------------------------------------------------------------------------------

public struct Wrap: SelectGraphicRenditionWrapType {

	public typealias Element = Parameter
	public typealias UnderlyingCollection = [Element]
	
	public var parameters = UnderlyingCollection()

	//------------------------------------------------------------------------------
	// MARK: - Initializers
	//------------------------------------------------------------------------------

	public init<S: Sequence where S.Iterator.Element == Element>(parameters: S) {
		self.parameters = UnderlyingCollection(parameters)
	}
	
	public init() {
		self.init(
			parameters: [] as UnderlyingCollection
		)
	}
	
	public init(arrayLiteral parameters: Element...) {
		self.init(parameters: parameters)
	}

	public init(
		foreground: Color.Named.Color? = nil,
		background: Color.Named.Color? = nil,
		style: StyleParameter...
	) {
		let colors: [Parameter] = [
			foreground.map { Color.Named(foreground: $0) },
			background.map { Color.Named(background: $0) }
		].flatMap { $0 } // concatenate non-nil ColorType parameters
		
		self.init(parameters: colors + style.map { $0 as Parameter })
	}
	
	public init(
		foreground: UInt8? = nil,
		background: UInt8? = nil,
		style: StyleParameter...
	) {
		let colors: [Parameter] = [
			foreground.map { Color.EightBit(foreground: $0) },
			background.map { Color.EightBit(background: $0) }
		].flatMap { $0 } // concatenate non-nil ColorType parameters
		
		self.init(parameters: colors + style.map { $0 as Parameter })
	}
	
	public init(styles: StyleParameter...) {
		self.init(parameters: styles.map { $0 as Parameter })
	}
	
	//------------------------------------------------------------------------------
	// MARK: - SelectGraphicRenditionWrap
	//------------------------------------------------------------------------------

	/// A SelectGraphicRendition code in two parts: enable and disable.
	public var code: (enable: SelectGraphicRendition, disable: SelectGraphicRendition) {
		
		if self.parameters.isEmpty {
			return ("", "")
		}

		let disableAll = [StyleParameter.Reset.defaultRendition]
		
		let (enables, disables) = self.parameters.reduce(
			(enable: [] as [UInt8], disable: [] as [UInt8])
		) { (previous: (enable: [UInt8], disable: [UInt8]), value) in
			let code = value.code
			let appendedEnable = previous.enable + code.enable
			
			guard
				previous.disable != disableAll,
				let disable = code.disable
			else {
				return (enable: appendedEnable, disable: disableAll)
			}
			
			return (enable: appendedEnable, disable: previous.disable + [disable])
		}
		
		let render = {
			ECMA48.controlSequenceIntroducer
			+ ($0 as [UInt8])
				.map(String.init)
				.joined(separator: ";")
			+ "m"
		}
		
		return (enable: render(enables), disable: render(disables))
	}
	
	/// Wraps the enable and disable SelectGraphicRendition codes around a string.
	public func wrap(_ string: String) -> String {
		let (enable, disable) = self.code
		return enable + string + disable
	}
	
	//------------------------------------------------------------------------------
	// MARK: - Foreground/Background Helpers
	//------------------------------------------------------------------------------
	
	private func filter(level: Level, inverse: Bool = false) -> UnderlyingCollection {
		return self.filter {
			let condition = (($0 as? ColorType)?.level == level) ?? false
			return inverse ? !condition : condition
		}
	}
	
	public var foreground: Parameter? {
		get {
			return self.filter(level: .Foreground).first
		}
		mutating set(newForeground) {
			self.parameters =
				[newForeground].flatMap { $0 } + // Empty array or array containing new foreground
				self.filter(level: .Foreground, inverse: true) // All non-foreground parameters
		}
	}
	
	public var background: Parameter? {
		get {
			return self.filter(level: .Background).first
		}
		mutating set(newBackground) {
			self.parameters =
				[newBackground].flatMap { $0 } + // Empty array or array containing new background
				self.filter(level: .Background, inverse: true) // All non-background parameters
		}
	}

	private func levelTransform(_ level: Level, @noescape transform: ColorType -> ColorType) -> (
		transformed: Bool,
		parameters: UnderlyingCollection
	) {
		return self.parameters.reduce(
			(transformed: false, parameters: [] as UnderlyingCollection)
		) { previous, value in
			if
				let color = value as? ColorType where color.level == level,
				case let transformation = [ transform(color) ] as UnderlyingCollection
			{
				return (transformed: true, parameters: previous.parameters + transformation)
			} else {
				return (previous.transformed, previous.parameters + [value])
			}
		}
	}
	
	/// Synchronously transform all ColorTypes with a `Level` of `Foreground`.
	public mutating func foreground(@noescape transform: ColorType -> ColorType) -> Bool {
		let transformation = levelTransform(.Foreground, transform: transform)
		self.parameters = transformation.parameters
		return transformation.transformed
	}

	/// Synchronously transform all ColorTypes with a `Level` of `Background`.
	public mutating func background(@noescape transform: ColorType -> ColorType) -> Bool {
		let transformation = levelTransform(.Background, transform: transform)
		self.parameters = transformation.parameters
		return transformation.transformed
	}
	
}

/* end extension of color */ }

//------------------------------------------------------------------------------
// MARK: - Wrap: SequenceType
//------------------------------------------------------------------------------

extension Color.Wrap: Sequence {
	public typealias Iterator = IndexingIterator<Array<Element>>
	public func makeIterator() -> Iterator {
		return parameters.makeIterator()
	}
}

//------------------------------------------------------------------------------
// MARK: - Wrap: CollectionType
//------------------------------------------------------------------------------

extension Color.Wrap: Collection, MutableCollection {
	public typealias Index = UnderlyingCollection.Index
	public var startIndex: Index { return parameters.startIndex }
	public var endIndex: Index { return parameters.endIndex }
	
	public subscript(position:Index) -> Iterator.Element {
		get { return parameters[position] }
		set { parameters[position] = newValue }
	}
}

//------------------------------------------------------------------------------
// MARK: - Wrap: RangeReplaceableCollectionType
//------------------------------------------------------------------------------

extension Color.Wrap: RangeReplaceableCollection {
	public mutating func replaceSubrange<C: Collection where C.Iterator.Element == Iterator.Element>(
		_ bounds: Range<Index>, with newElements: C
	) {
		parameters.replaceSubrange(bounds, with: newElements)
	}

	
	public mutating func reserveCapacity(n: Index.Distance) {
		parameters.reserveCapacity(n)
	}

	public mutating func append(newElement: Element) {
		parameters.append(newElement)
	}
	
	public mutating func append(style: StyleParameter...) {
		for parameter in style {
			parameters.append(parameter)
		}
	}
	
	public mutating func append<S: Sequence where S.Iterator.Element == Element>(contentsOf sequence: S) {
		parameters.append(contentsOf: sequence)
	}
}

//------------------------------------------------------------------------------
// MARK: - Wrap: ArrayLiteralConvertible
//------------------------------------------------------------------------------

extension Color.Wrap: ArrayLiteralConvertible {}

//------------------------------------------------------------------------------
// MARK: - Wrap: Equatable
//------------------------------------------------------------------------------

extension Color.Wrap: Equatable {
	
	public enum EqualityType {
		case Array
		case Set
	}
	
	private func setEqualilty(_ a: Color.Wrap, _ b: Color.Wrap) -> Bool {
		
		let x = Set( a.parameters.map { String($0.code.enable) } )
		let y = Set( b.parameters.map { String($0.code.enable) } )
		
		return x == y
		
	}
	
	public func isEqual(to other: Color.Wrap, equality: Color.Wrap.EqualityType = .Array) -> Bool {
		switch equality {
		case .Array:
			return
				self.parameters.count == other.parameters.count &&
				self.code.enable == other.code.enable
		case .Set:
			return setEqualilty(self, other)
		}
	}

}

public func == (a: Color.Wrap, b: Color.Wrap) -> Bool {
	return a.isEqual(to: b, equality: .Array)
}
