// MARK: - Safe operations
public extension Lexer {
    /// Advances while a given predicate returns true.
    /// Stops when reaching end-of-string, or the when the predicate returns false.
    ///
    /// The char under `peek()` will be the char that the predicate returned `false`
    /// for.
    @inline(__always)
    public func advance(while predicate: (Atom) throws -> Bool) rethrows {
        while try !isEof() && predicate(unsafePeek()) {
            unsafeAdvance()
        }
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
    
    /// Advances the stream if the current string under it matches the given string.
    /// The method checks the match, does nothing while returning false if the
    /// current stream position does not match the given string.
    /// By default, the lexer does a `literal`, character-by-character match,
    /// which can be overriden by specifying the `options` parameter.
    public func advanceIf(equals: String, options: String.CompareOptions = .literal) -> Bool {
        if let range = inputString.range(of: equals, options: options, range: inputIndex..<inputString.endIndex) {
            // Match! Advance stream and proceed...
            if range.lowerBound == inputIndex {
                inputIndex = range.upperBound
                
                return true
            }
        }
        
        return false
    }
}

// MARK: - Unsafe/throwing operations
public extension Lexer {
    
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
    
    /// Advance the stream if the current string under it matches the given atom
    /// character.
    /// The method throws an error if the current character is not the expected
    /// one, or advances to the next position, if it is.
    @inline(__always)
    public func advance(expectingCurrent atom: Atom) throws {
        let n = try next()
        if n != atom {
            throw unexpectedCharacterError(char: n, "Expected '\(atom)', received '\(n)' instead")
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
            throw unexpectedCharacterError(char: n, "Unexpected \(n)")
        }
    }
    
    
    /// If the next characters in the read buffer do not ammount to `match`, an
    /// error is thrown.
    public func expect(match: String, options: String.CompareOptions = .literal) throws {
        if !advanceIf(equals: match, options: options) {
            throw LexerError.unexpectedString("Expected '\(match)'")
        }
    }
}
