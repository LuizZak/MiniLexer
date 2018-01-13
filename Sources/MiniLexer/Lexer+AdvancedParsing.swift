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
                throw LexerError.miscellaneous("Expected \(min) rounds, received \(n)")
            }
            throw LexerError.miscellaneous("Expected between \(min) and \(max) rounds, received \(n)")
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
