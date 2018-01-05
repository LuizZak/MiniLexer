import Foundation

/// Class capable of parsing tokens out of a string.
/// Currently presents support to parse some simple time formats,
/// single/double-quoted strings, and floating point numbers.
public final class Lexer {
    
    public typealias Atom = UnicodeScalar
    public typealias Index = String.Index
    
    public let inputString: String
    
    @_versioned
    internal var inputSource: String.UnicodeScalarView {
        return inputString.unicodeScalars
    }
    
    public var inputIndex: Index
    
    @_versioned
    internal let endIndex: Index
    
    public init(input: String) {
        inputString = input
        inputIndex = inputString.startIndex
        endIndex = inputString.endIndex
    }
    
    public init(input: String, index: Index) {
        inputString = input
        inputIndex = index
        endIndex = inputString.endIndex
    }
    
    // MARK: Raw parsing methods
    @inline(__always)
    public func parseInt(skippingWhitespace: Bool = true) throws -> Int {
        return try parseInt(minLength: 1, skippingWhitespace: skippingWhitespace)
    }
    
    @inline(__always)
    public func parseInt(minLength: Int, skippingWhitespace: Bool = true) throws -> Int {
        if skippingWhitespace {
            skipWhitespace()
        }
        
        // Consume raw like this - type-checking is provided on conversion
        // method bellow
        let start = inputIndex
        let string = consume(while: Lexer.isDigit)
        
        if minLength > 1 {
            let distance = inputSource.distance(from: start, to: inputIndex)
            if distance < minLength {
                throw invalidCharError("Expected integer with minimum length of \(minLength), but could read only \(distance) digits")
            }
        }
        
        guard let value = Int(string) else {
            throw invalidCharError("Invalid integer string \(string)")
        }
        
        return value
    }
    
    // MARK: String consuming methods
    public func peekIdent() throws -> Substring {
        return try withTemporaryIndex {
            return try nextIdent()
        }
    }
    
    /// Peeks into the next identifier on the string, and also returns the index
    /// at which the identifier ends at - useful for check-then-consume-conditionaly
    /// routines
    public func peekIdentWithOffset() throws -> (Substring, Index) {
        return try withTemporaryIndex {
            let ident = try nextIdent()
            
            return (ident, inputIndex)
        }
    }
    
    /// Advances the stream until the first non-whitespace character is found.
    public func skipWhitespace() {
        advance(while: Lexer.isWhitespace)
    }
    
    /// Returns whether the current stream position points to the end of the input
    /// string.
    /// No further reading is possible when a stream is pointing to the end.
    @inline(__always)
    public func isEof() -> Bool {
        return inputIndex >= endIndex
    }
    
    /// Returns whether the current stream position + `offsetBy` points to past
    /// the end of the input string.
    @inline(__always)
    public func isEof(offsetBy: Int) -> Bool {
        return inputSource.index(inputIndex, offsetBy: offsetBy) >= endIndex
    }
    
    /// Returns whether the next char returns true when passed to the given predicate,
    /// This method is safe, since it checks isEoF before making the check call.
    @inline(__always)
    public func safeNextCharPasses(with predicate: (Atom) throws -> Bool) rethrows -> Bool {
        return try !isEof() && predicate(unsafePeek())
    }
    
    /// Returns whether the next char in the string the given char.
    /// This method is safe, since it checks isEoF before making the check call,
    /// and returns 'false' if EoF.
    @inline(__always)
    public func safeIsNextChar(equalTo char: Atom) -> Bool {
        return !isEof() && unsafePeek() == char
    }
    
    /// Reads a single character from the current stream position, and forwards
    /// the stream by 1 unit.
    @inline(__always)
    public func next() throws -> Atom {
        let atom = try peek()
        unsafeAdvance()
        return atom
    }
    
    /// Peeks the current character at the current index
    @inline(__always)
    public func peek() throws -> Atom {
        if isEof() {
            throw endOfStringError()
        }
        
        return inputSource[inputIndex]
    }
    
    /// Peeks a character forward `count` characters from the current position.
    ///
    /// - precondition: `count > 0`
    /// - throws: `LexerError.endOfStringError`, if inputIndex + count >= endIndex
    @inline(__always)
    public func peekForward(count: Int = 1) throws -> Atom {
        precondition(count >= 0)
        guard let newIndex = inputSource.index(inputIndex, offsetBy: count, limitedBy: endIndex) else {
            throw endOfStringError()
        }
        
        return inputSource[newIndex]
    }
    
    /// Unsafe version of peek(), proper for usages where check of isEoF is
    /// preemptively made.
    @inline(__always)
    @_versioned
    internal func unsafePeek() -> Atom {
        return inputSource[inputIndex]
    }
    
    /// Advances the stream without reading a character.
    /// Throws an EoF error if the current offset is at the end of the character
    /// stream.
    @inline(__always)
    public func advance() throws {
        if isEof() {
            throw endOfStringError()
        }
        
        unsafeAdvance()
    }
    
    /// Unsafe version of advance(), proper for usages where check of isEoF is
    /// preemptively made.
    @inline(__always)
    @_versioned
    internal func unsafeAdvance() {
        inputSource.formIndex(after: &inputIndex)
    }
    
    /// Advances while a given predicate returns true.
    /// Stops when reaching end-of-string, or the when the predicate returns false.
    ///
    /// The char under `peek()` will be the char that the predicate returned `false`
    /// for.
    @inline(__always)
    public func advance(while predicate: (Atom) throws -> Bool) rethrows {
        while(try !isEof() && predicate(unsafePeek())) {
            unsafeAdvance()
        }
    }
    
    /// Consumes the input string while a given predicate returns true.
    /// Stops when reaching end-of-string, or the when the predicate returns false.
    ///
    /// The char under `peek()` will be the char that the predicate returned `false`
    /// for.
    @inline(__always)
    public func consume(while predicate: (Atom) throws -> Bool) rethrows -> Substring {
        let start = inputIndex
        try advance(while: predicate)
        return inputString[start..<inputIndex]
    }
    
    /// Consumes the entire buffer from the current point up until the last
    /// character.
    /// Returns an empty string, if the current character is already pointing at
    /// the end of the buffer.
    @inline(__always)
    public func consumeRemaining() -> Substring {
        return consumeString { $0.inputIndex = $0.endIndex }
    }
    
    /// Advances while a given predicate method returns false.
    /// Stops when reaching end-of-string, or the when the predicate returns true.
    ///
    /// The char under `peek()` will be the char that the predicate returned `true`
    /// for.
    @inline(__always)
    public func advance(until predicate: (Atom) throws -> Bool) rethrows {
        while try !isEof() && !predicate(unsafePeek()) {
            unsafeAdvance()
        }
    }
    
    /// Attempts to advance a string of 'n' length from the current index.
    /// Throws, if less than 'n' characters are available to read.
    ///
    /// - precondition: `n > 0`
    @inline(__always)
    public func advanceLength(_ n: Int) throws {
        precondition(n > 0)
        if isEof(offsetBy: n) {
            throw endOfStringError()
        }
        
        inputIndex = inputSource.index(inputIndex, offsetBy: n)
    }
    
    /// Consumes the input string while a given predicate returns false.
    /// Stops when reaching end-of-string, or the when the predicate returns true.
    ///
    /// The char under `peek()` will be the char that the predicate returned `true`
    /// for.
    @inline(__always)
    public func consume(until predicate: (Atom) throws -> Bool) rethrows -> Substring {
        let start = inputIndex
        try advance(until: predicate)
        return inputString[start..<inputIndex]
    }
    
    /// Attempts to consume a string of 'n' length from the current index.
    /// Throws, if less than 'n' characters are available to read.
    ///
    /// - precondition: `n > 0`
    @inline(__always)
    public func consumeLength(_ n: Int) throws -> Substring {
        precondition(n > 0)
        if isEof(offsetBy: n) {
            throw endOfStringError()
        }
        
        return consumeString { lexer in
            inputIndex = inputSource.index(inputIndex, offsetBy: n)
        }
    }
    
    /// Advances the stream if the current string under it matches the given string.
    /// The method checks the match, does nothing while returning false if the
    /// current stream position does not match the given string.
    /// By default, the lexer does a `literal`, character-by-character match,
    /// which can be overriden by specifying the `options` parameter.
    public func advanceIf(equals: String, options: String.CompareOptions = .literal) -> Bool {
        guard let current = inputIndex.samePosition(in: inputString) else {
            return false
        }
        
        if let range = inputString.range(of: equals, options: options, range: current..<inputString.endIndex) {
            // Match! Advance stream and proceed...
            if range.lowerBound == current {
                inputIndex = range.upperBound
                
                return true
            }
        }
        
        return false
    }
    
    /// Advance the stream if the current string under it matches the given atom
    /// character.
    /// The method throws an error if the current character is not the expected
    /// one, or advances to the next position, if it is.
    @inline(__always)
    public func advance(expectingCurrent atom: Atom) throws {
        let n = try next()
        if n != atom {
            throw invalidCharError("Expected '\(atom)', received '\(n)' instead")
        }
    }
    
    /// Advance the stream if the current string under it passes a given matcher
    /// function.
    ///
    /// The method throws an error if the current character returns false for the
    /// given closure, or advances to the next position, if it does.
    ///
    /// Calling when `isEoF() == true` results in an error thrown
    @inline(__always)
    public func advance(validatingCurrent: (Atom) throws -> Bool) throws {
        let n = try next()
        if try !validatingCurrent(n) {
            throw invalidCharError("Unexpected \(n)")
        }
    }
    
    /// Tries to parse an identifier (a letter, followed by sequence of
    /// alphanumeric characters) from the current position in the string.
    /// Throws and end-of-stream error if the current index points to the end of
    /// the string.
    public func nextIdent() throws -> Substring {
        if try !Lexer.isLetter(peek()) {
            throw invalidCharError("Expected identifier starting with a letter")
        }
        
        return consume(while: Lexer.isAlphanumeric)
    }
    
    /// Performs discardable index changes inside a given closure.
    /// Any changes to this parser's state are undone after the method returns.
    @inline(__always)
    public func withTemporaryIndex<T>(changes: () throws -> T) rethrows -> T {
        let index = inputIndex
        defer {
            inputIndex = index
        }
        return try changes()
    }
    
    /// Returns a string that starts from the current input index, all the way
    /// until the index after the given block performs index-advancing operations
    /// on this lexer.
    /// If no index change is made, an empty string is returned.
    @inline(__always)
    public func consumeString(performing block: (Lexer) throws -> Void) rethrows -> Substring {
        let start = inputIndex
        try block(self)
        return inputString[start..<inputIndex]
    }
    
    // MARK: Character checking
    @inline(__always)
    public static func isDigit(_ c: Atom) -> Bool {
        return c >= "0" && c <= "9"
    }
    
    @inline(__always)
    public static func isStringDelimiter(_ c: Atom) -> Bool {
        return c == "\"" || c == "\'"
    }
    
    @inline(__always)
    public static func isWhitespace(_ c: Atom) -> Bool {
        return c == " " || c == "\r" || c == "\n" || c == "\t"
    }
    
    @inline(__always)
    public static func isLetter(_ c: Atom) -> Bool {
        return isLowercaseLetter(c) || isUppercaseLetter(c)
    }
    
    public static func isLowercaseLetter(_ c: Atom) -> Bool {
        switch c {
        case "a"..."z":
            return true
            
        default:
            return false
        }
    }
    
    public static func isUppercaseLetter(_ c: Atom) -> Bool {
        switch c {
        case "A"..."Z":
            return true
            
        default:
            return false
        }
    }
    
    public static func isAlphanumeric(_ c: Atom) -> Bool {
        return isLetter(c) || isDigit(c)
    }
    
    // MARK: Error methods
    public func invalidCharError(_ message: String) -> Error {
        return LexerError.invalidCharacter(message)
    }
    
    public func endOfStringError(_ message: String = "Reached unexpected end of input string") -> Error {
        return LexerError.endOfStringError(message)
    }
}

// MARK: - String-typed number parsing methods
extension Lexer {
    @inline(__always)
    public func parseIntString(skippingWhitespace: Bool = true) throws -> Substring {
        if skippingWhitespace {
            skipWhitespace()
        }
        
        if !Lexer.isDigit(try peek()) {
            throw invalidCharError("Expected integer but received '\(unsafePeek())'")
        }
        
        return consume(while: Lexer.isDigit)
    }
    
    @inline(__always)
    public func parseFloatString(skippingWhitespace: Bool = true) throws -> String {
        if skippingWhitespace {
            skipWhitespace()
        }
        
        // (0-9)+('.'(0..9)+)
        if !Lexer.isDigit(try peek()) {
            throw invalidCharError("Expected float but received '\(unsafePeek())'")
        }
        
        let start = inputIndex
        
        advance(while: Lexer.isDigit)
        
        if safeIsNextChar(equalTo: ".") {
            unsafeAdvance()
            
            // Expect more digits
            if !Lexer.isDigit(try peek()) {
                throw invalidCharError("Expected float but received '\(unsafePeek())'")
            }
            
            advance(while: Lexer.isDigit)
        }
        
        return String(inputString[start..<inputIndex]) // Consume the entire offset
    }
    
}

// MARK: - Find/skip to next methods
extension Lexer {
    
    /// Returns the index of the next occurrence of a given input char.
    /// Method starts searching from current read index.
    /// This method does not alter the current
    public func findNext(_ atom: Atom) -> Index? {
        return withTemporaryIndex {
            advance(until: { $0 == atom })
            
            if inputIndex != inputString.endIndex {
                return inputIndex
            }
            
            return nil
        }
    }
    
    /// Skips all chars until the next occurrence of a given char.
    /// Method starts searching from current read index.
    /// If the char is not found after the current index, an error is thrown.
    public func skipToNext(_ atom: Atom) throws {
        guard let index = findNext(atom) else {
            throw LexerError.notFound("Expected \(atom) but it was not found.")
        }
        
        inputIndex = index
    }
}

// MARK: - Advanced parsing operators
public extension Lexer {
    /// Tries to read from the current position using a given block, and skips
    /// advancing if either the block throws or returns `false`.
    ///
    /// Can be used w/ `consumeString` to read optional sections with certain
    /// gramatical rules.
    ///
    /// Returns `true`, if read was successful (`block` did not throw and returned
    /// `true`).
    @discardableResult
    @inline(__always)
    public func optional(using block: (Lexer) throws -> Bool) -> Bool {
        do {
            let (res, index) = try withTemporaryIndex {
                (try block(self), inputIndex)
            }
            
            if !res {
                return false
            }
            
            inputIndex = index
            return true
        } catch {
            return false
        }
    }
    
    /// Tries to read exactly `count` rounds lexer w/ the given `block`, stopping
    /// at the first read attempt that results in a thrown error, or when it
    /// returns `false`.
    ///
    /// The read head is then reset to before the last attempt.
    /// If `!= count` rounds have been performed before the block failed/returned
    /// `false`, an error is thrown.
    @inline(__always)
    public func expect(exactly count: Int, of block: (Lexer) throws -> Bool) throws {
        return try expect(between: count, max: count, of: block)
    }
    
    /// Tries to read as much as possible of the lexer w/ the given `block`,
    /// stopping at the first read attempt that results in a thrown error, or
    /// when it returns `false`.
    ///
    /// The read head is then reset to before the last attempt.
    /// If `< count` rounds have been performed before the block failed/returned
    /// `false`, an error is thrown.
    @inline(__always)
    public func expect(atLeast count: Int, of block: (Lexer) throws -> Bool) throws {
        return try expect(between: count, max: Int.max, of: block)
    }
    
    /// Tries to read between the given range #-count of rounds of the lexer w/
    /// the given `block`, stopping at the first read attempt that results in a
    /// thrown error, or when it returns `false`.
    ///
    /// The read head is then reset to before the last attempt.
    /// If `< min` or `> max` rounds have been performed before the block
    /// failed/returned `false`, an error is thrown.
    @inline(__always)
    public func expect(between min: Int, max: Int, of block: (Lexer) throws -> Bool) throws {
        let n = performGreedyRounds(block: { (l, r) in try r < max && block(l) })
        
        if n < min || n > max {
            if min == max {
                throw LexerError.miscellaneous("Expected \(min) of rounds, received \(n)")
            }
            throw LexerError.miscellaneous("Expected between \(min) and \(max) of rounds, received \(n)")
        }
    }
    
    /// Reads the current position as much as possible using the giving throwing
    /// block, returning the number of rounds that where performed.
    ///
    /// Tries to read as much as possible of the lexer w/ the given `block`,
    /// stopping at the first read attempt that results in a thrown error, or
    /// when it returns `false`.
    ///
    /// The read head is then reset to before the last attempt.
    @inline(__always)
    public func performGreedyRounds(block: (Lexer, Int) throws -> Bool) -> Int {
        var rounds = 0
        repeat {
            do {
                let (passed, index) = try withTemporaryIndex {
                    (try block(self, rounds), inputIndex)
                }
                if !passed {
                    break
                }
                rounds += 1
                inputIndex = index
            } catch {
                break
            }
        } while true
        
        return rounds
    }
    
    /// Given a list of lexer-consuming closures, returns when the first closure
    /// successfully parses without throwing errors, throwing an error of its
    /// own if none of the parsers succeeded.
    ///
    /// The method automatically deals w/ backtracking to the current position
    /// when parsing fails across closure attempts.
    @inline(__always)
    public func matchFirst(withEither options: (Lexer) throws -> Void...) throws {
        var lastError: Error?
        for option in options {
            if optional(using: { lexer -> Bool in
                do {
                    try option(lexer)
                } catch {
                    lastError = error
                    throw error
                }
                return true
            }) {
                return
            }
        }
        
        if let error = lastError {
            throw error
        }
        
        throw LexerError.genericParseError
    }
}

public enum LexerError: Error {
    case invalidCharacter(String)
    case endOfStringError(String)
    case notFound(String)
    case miscellaneous(String)
    case genericParseError // No string messages attached
}

