import Foundation

// MARK: - Safe operations
public extension Parser {
    /// Attempts to advance the string index forward by one, returning a value
    /// telling true if the advance was successful or false if the current index
    /// is pointing at the end of the string buffer
    @inlinable
    func safeAdvance() -> Bool {
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
    @inlinable
    func advance(while predicate: (Atom) throws -> Bool) rethrows {
        while try !isEof() && predicate(unsafePeek()) {
            unsafeAdvance()
        }
    }
    
    /// Advances while a given predicate method returns false.
    /// Stops when reaching end-of-string, or the when the predicate returns true.
    ///
    /// The char under `peek()` will be the char that the predicate returned `true`
    /// for.
    @inlinable
    func advance(until predicate: (Atom) throws -> Bool) rethrows {
        while try !isEof() && !predicate(unsafePeek()) {
            unsafeAdvance()
        }
    }
    
    /// Returns if the next characters in the read buffer equal to `match` according
    /// to the specified string comparison rules.
    func checkNext<S: StringProtocol>(matches match: S, options: String.CompareOptions = .literal) -> Bool {
        guard let endIndex = inputString.index(inputIndex, offsetBy: match.count, limitedBy: inputString.endIndex) else {
            return false
        }
        
        if options == .literal {
            return inputString[inputIndex..<endIndex] == match
        }
        
        return inputString[inputIndex..<endIndex].compare(match, options: options) == .orderedSame
    }
    
    /// Advances the stream if the current string under it matches the given string.
    /// The method checks the match, does nothing while returning false if the
    /// current stream position does not match the given string.
    /// By default, the parser does a `literal`, character-by-character match,
    /// which can be overriden by specifying the `options` parameter.
    func advanceIf<S: StringProtocol>(equals string: S, options: String.CompareOptions = .literal) -> Bool {
        guard let endIndex = inputString.index(inputIndex, offsetBy: string.count, limitedBy: inputString.endIndex) else {
            return false
        }
        
        let match: Bool
        if options == .literal {
            match = inputString[inputIndex..<endIndex] == string
        } else {
            match = inputString[inputIndex..<endIndex].compare(string, options: options) == .orderedSame
        }
        
        if match {
            inputIndex = endIndex
            return true
        }
        
        return false
    }
}

// MARK: - Unsafe/throwing operations
public extension Parser {
    
    /// Advances the stream without reading a character.
    /// Throws an EoF error if the current offset is at the end of the character
    /// stream.
    @inlinable
    func advance() throws {
        if isEof() {
            throw endOfStringError()
        }
        
        unsafeAdvance()
    }
    
    /// Unsafe version of advance(), proper for usages where check of isEoF is
    /// preemptively made.
    @usableFromInline
    internal func unsafeAdvance() {
        inputSource.formIndex(after: &inputIndex)
    }
    
    /// Attempts to advance a string of 'n' length from the current index.
    /// Throws, if less than 'n' characters are available to read.
    ///
    /// - precondition: `n > 0`
    @inlinable
    func advanceLength(_ n: Int) throws {
        precondition(n > 0)
        if isEof(offsetBy: n - 1) {
            throw endOfStringError()
        }
        
        inputIndex = inputSource.index(inputIndex, offsetBy: n)
    }
    
    /// Advance the stream if the current string under it matches the given atom
    /// character.
    /// The method throws an error if the current character is not the expected
    /// one, or advances to the next position, if it is.
    @inlinable
    func advance(expectingCurrent atom: Atom) throws {
        let next = try peek()
        guard next == atom else {
            throw unexpectedCharacterError(char: next, "Expected '\(atom)', received '\(next)' instead")
        }
        
        unsafeAdvance()
    }
    
    /// Advance the stream if the current string under it passes a given matcher
    /// function.
    ///
    /// The method throws an error if the current character returns false for the
    /// given closure, or advances to the next position, if it does.
    ///
    /// Calling when `isEoF() == true` results in an error thrown
    @inlinable
    func advance(validatingCurrent predicate: (Atom) throws -> Bool) throws {
        let next = try peek()
        guard try predicate(next) else {
            throw unexpectedCharacterError(char: next, "Unexpected \(next)")
        }
        
        unsafeAdvance()
    }
    
    /// If the next characters in the read buffer do not ammount to `match`, an
    /// error is thrown.
    ///
    /// The buffer advances if the string matches the current read buffer.
    func consume<S: StringProtocol>(match: S, options: String.CompareOptions = .literal) throws {
        if !advanceIf(equals: match, options: options) {
            throw unexpectedStringError("Expected '\(match)'")
        }
    }
}
