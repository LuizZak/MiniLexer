// MARK: - Advanced parsing operators
public extension Parser {
    /// Tries to read from the current position using a given block, and skips
    /// advancing if either the block throws or returns `false`.
    ///
    /// Can be used w/ `consumeString` to read optional sections with certain
    /// gramatical rules.
    ///
    /// Returns `true`, if read was successful (`block` did not throw and returned
    /// `true`).
    @discardableResult
    @inlinable
    func optional(using block: (Parser) throws -> Bool) -> Bool {
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
    
    /// Tries to read exactly `count` rounds parser w/ the given `block`, stopping
    /// at the first read attempt that results in a thrown error, or when it
    /// returns `false`.
    ///
    /// The read head is then reset to before the last attempt.
    /// If `!= count` rounds have been performed before the block failed/returned
    /// `false`, an error is thrown.
    @inlinable
    func expect(exactly count: Int, of block: (Parser) throws -> Bool) throws {
        return try expect(between: count, max: count, of: block)
    }
    
    /// Tries to read as much as possible of the parser w/ the given `block`,
    /// stopping at the first read attempt that results in a thrown error, or
    /// when it returns `false`.
    ///
    /// The read head is then reset to before the last attempt.
    /// If `< count` rounds have been performed before the block failed/returned
    /// `false`, an error is thrown.
    @inlinable
    func expect(atLeast count: Int, of block: (Parser) throws -> Bool) throws {
        return try expect(between: count, max: Int.max, of: block)
    }
    
    /// Tries to read between the given range #-count of rounds of the parser w/
    /// the given `block`, stopping at the first read attempt that results in a
    /// thrown error, or when it returns `false`.
    ///
    /// The read head is then reset to before the last attempt.
    /// If `< min` or `> max` rounds have been performed before the block
    /// failed/returned `false`, an error is thrown.
    @inlinable
    func expect(between min: Int, max: Int, of block: (Parser) throws -> Bool) throws {
        let n = performGreedyRounds(block: { (l, r) in try r < max && block(l) })
        
        if n < min || n > max {
            if min == max {
                throw ParserError.miscellaneous("Expected \(min) rounds, received \(n)")
            }
            throw ParserError.miscellaneous("Expected between \(min) and \(max) rounds, received \(n)")
        }
    }
    
    /// Reads the current position as much as possible using the giving throwing
    /// block, returning the number of rounds that where performed.
    ///
    /// Tries to read as much as possible of the parser w/ the given `block`,
    /// stopping at the first read attempt that results in a thrown error, or
    /// when it returns `false`.
    ///
    /// The read head is then reset to before the last attempt.
    @inlinable
    func performGreedyRounds(block: (Parser, Int) throws -> Bool) -> Int {
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
    
    /// Given a list of parser-consuming closures, returns when the first closure
    /// successfully parses without throwing errors, throwing an error of its
    /// own if none of the parsers succeeded.
    ///
    /// The method automatically deals w/ backtracking to the current position
    /// when parsing fails across closure attempts.
    @inlinable
    func matchFirst(withEither options: (Parser) throws -> Void...) throws {
        var lastError: Error?
        for option in options {
            if optional(using: { parser -> Bool in
                do {
                    try option(parser)
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
        
        throw ParserError.genericParseError
    }
}
