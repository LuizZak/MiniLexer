import Foundation

// MARK: - Safe operations
public extension Lexer {
    /// Attempts to advance the string index forward by one, returning a value
    /// telling whether the advance was successful or whether the current index
    /// is pointing at the end of the string buffer
    @inline(__always)
    public func safeAdvance() -> Bool {
        if let next = inputSource.index(inputIndex, offsetBy: 1, limitedBy: inputSource.endIndex) {
            inputIndex = next
            return true
        }
        return false
    }
    
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
    public func advanceIf<S: StringProtocol>(equals: S, options: String.CompareOptions = .literal) -> Bool {
        guard let endIndex = inputString.index(inputIndex, offsetBy: String.IndexDistance(equals.count), limitedBy: inputString.endIndex) else {
            return false
        }
        
        if inputString[inputIndex..<endIndex].compare(equals, options: options) == .orderedSame {
            // Match! Advance stream and proceed...
            inputIndex = endIndex
            return true
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
        let prev = inputIndex
        let n = try next()
        if n != atom {
            inputIndex = prev
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
        let prev = inputIndex
        let n = try next()
        if try !validatingCurrent(n) {
            inputIndex = prev
            throw unexpectedCharacterError(char: n, "Unexpected \(n)")
        }
    }
    
    
    /// If the next characters in the read buffer do not ammount to `match`, an
    /// error is thrown.
    public func expect<S: StringProtocol>(match: S, options: String.CompareOptions = .literal) throws {
        if !advanceIf(equals: match, options: options) {
            throw unexpectedStringError("Expected '\(match)'")
        }
    }
}
