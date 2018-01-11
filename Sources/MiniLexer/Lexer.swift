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
    
    /// Performs an operation, retuning the index of the read head after the
    /// operation is completed.
    ///
    /// Can be used to record index after changes are made in conjunction to
    /// `withTemporaryIndex`
    @inline(__always)
    public func withIndexAfter<T>(performing changes: () throws -> T) rethrows -> (T, Lexer.Index) {
        return (try changes(), inputIndex)
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
    public func unexpectedCharacterError(char: Atom, _ message: String) -> Error {
        return LexerError.unexpectedCharacter(char, message)
    }
    
    public func syntaxError(_ message: String) -> Error {
        return LexerError.syntaxError(message)
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
            throw unexpectedCharacterError(char: unsafePeek(), "Expected digit for integer")
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
            throw unexpectedCharacterError(char: unsafePeek(), "Expected digit for float")
        }
        
        let start = inputIndex
        
        advance(while: Lexer.isDigit)
        
        if safeIsNextChar(equalTo: ".") {
            unsafeAdvance()
            
            // Expect more digits
            if !Lexer.isDigit(try peek()) {
                throw unexpectedCharacterError(char: unsafePeek(), "Expected digit for float")
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

public enum LexerError: Error {
    case unexpectedCharacter(Lexer.Atom, String)
    case unexpectedString(String)
    case syntaxError(String)
    case endOfStringError(String)
    case notFound(String)
    case miscellaneous(String)
    case genericParseError
}
