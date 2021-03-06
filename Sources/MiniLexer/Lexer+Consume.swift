// MARK: - Safe operations
public extension Lexer {
    /// Consumes the input string while a given predicate returns true.
    /// Stops when reaching end-of-string, or the when the predicate returns false.
    ///
    /// The char under `peek()` will be the char that the predicate returned `false`
    /// for.
    @inlinable
    func consume(while predicate: (Atom) throws -> Bool) rethrows -> Substring {
        let index = inputIndex
        try advance(while: predicate)
        return inputString[index..<inputIndex]
    }
    
    /// Consumes the entire buffer from the current point up until the last
    /// character.
    /// Returns an empty string, if the current character is already pointing at
    /// the end of the buffer.
    @inlinable
    func consumeRemaining() -> Substring {
        defer {
            inputIndex = endIndex
        }
        
        return inputString[inputIndex..<endIndex]
    }
    
    /// Consumes the input string while a given predicate returns false.
    /// Stops when reaching end-of-string, or the when the predicate returns true.
    ///
    /// The char under `peek()` will be the char that the predicate returned `true`
    /// for.
    @inlinable
    func consume(until predicate: (Atom) throws -> Bool) rethrows -> Substring {
        let index = inputIndex
        try advance(until: predicate)
        return inputString[index..<inputIndex]
    }
    
    /// Returns a string that starts from the current input index, all the way
    /// until the index after the given block performs index-advancing operations
    /// on this lexer.
    /// If no index change is made, an empty string is returned.
    @inlinable
    func consumeString(performing block: (Lexer) throws -> Void) rethrows -> Substring {
        let range = startRange()
        try block(self)
        return range.string()
    }
}

// MARK: - Unsafe/throwing operations
public extension Lexer {
    /// Attempts to consume a string of 'n' length from the current index.
    /// Throws, if less than 'n' characters are available to read.
    ///
    /// - precondition: `n > 0`
    @inlinable
    func consumeLength(_ n: Int) throws -> Substring {
        precondition(n > 0)
        if isEof(offsetBy: n - 1) {
            throw endOfStringError()
        }
        
        return consumeString { lexer in
            inputIndex = inputSource.index(inputIndex, offsetBy: n)
        }
    }
}
