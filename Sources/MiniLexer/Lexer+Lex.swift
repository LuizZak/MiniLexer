// MARK: - Known Token Lexing
public extension Lexer {
    
    /// Attempts to lex an integer at the current read position.
    /// Throws an error if the operation failed.
    ///
    /// Grammar:
    ///
    ///     int = [0-9]+
    ///
    /// - Parameter skippingWhitespace: Whether to skip whitespace before attempting
    /// to read the integer.
    @inline(__always)
    public func lexInt(skippingWhitespace: Bool = true) throws -> Int {
        return try lexInt(minLength: 1, skippingWhitespace: skippingWhitespace)
    }
    
    @inline(__always)
    public func lexInt(minLength: Int, skippingWhitespace: Bool = true) throws -> Int {
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
                throw syntaxError("Expected integer with minimum length of \(minLength), but could read only \(distance) digits")
            }
        }
        
        guard let value = Int(string) else {
            throw syntaxError("Invalid integer string \(string)")
        }
        
        return value
    }
    
    /// Tries to lex an identifier (a letter, followed by sequence of alphanumeric
    /// characters) from the current position in the string.
    /// Throws and end-of-stream error if the current index points to the end of
    /// the string.
    ///
    /// Grammar:
    ///
    ///     identifier  = [a-zA-Z_] [a-zA-Z_0-9]*
    public func lexIdentifier() throws -> Substring {
        if try !Lexer.isLetter(peek()) {
            throw unexpectedCharacterError(char: unsafePeek(), "Expected identifier starting with a letter")
        }
        
        return consume(while: Lexer.isAlphanumeric)
    }
    
    /// Attempts to lex an identifier from the current buffer, throwing an error
    /// if the operation results in a failed parse.
    /// The read index is not modified during this operation.
    public func peekIdentifier() throws -> Substring {
        return try withTemporaryIndex {
            return try lexIdentifier()
        }
    }
    
    /// Peeks into the next identifier on the string, and also returns the index
    /// at which the identifier ends at - useful for check-then-consume-conditionaly
    /// routines
    public func peekIdentifierWithOffset() throws -> (Substring, Index) {
        return try withTemporaryIndex {
            return try withIndexAfter {
                try lexIdentifier()
            }
        }
    }
}
