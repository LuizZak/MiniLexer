// MARK: - Known Token Lexing
public extension Lexer {
    /*
    
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
    @inline(__always)
    public func lexIdentifier() throws -> Substring {
        return try consumeString { lexer in
            try lexer.advance(validatingCurrent: { Lexer.isLetter($0) || $0 == "_" })
            
            lexer.advance(while: { Lexer.isAlphanumeric($0) || $0 == "_" } )
        }
    }
    
    /// Attempts to lex an identifier from the current buffer, throwing an error
    /// if the operation results in a failed parse.
    /// The read index is not modified during this operation.
    @inline(__always)
    public func peekIdentifier() throws -> Substring {
        return try withTemporaryIndex {
            return try lexIdentifier()
        }
    }
    */
}
