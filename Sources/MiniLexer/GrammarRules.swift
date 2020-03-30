import Foundation

/// A grammar rule that consumes from a Lexer and returns a resulting type
public protocol LexerGrammarRule {
    associatedtype Result = Substring
    
    /// A short, formal description of this grammar rule to be used during debugging
    /// and error reporting
    var ruleDescription: String { get }
    
    /// Returns `true` if this rule contains any subrule that is recursive, or if
    /// this rule is recursive itself.
    var containsRecursiveRule: Bool { get }
    
    /// Consumes the required rule from a lexer.
    /// Simply catches a substring from the lexer's current position all the way
    /// to its later index after a call to `LexerGrammarRule.parse(with:)`
    func consume(from lexer: Lexer) throws -> Result
    
    /// Parses with a given lexer, but does't return a result, simply advances the
    /// lexer's offset as if it was parsed by `LexerGrammarRule.consume(from:)`.
    func stepThroughApplying(on lexer: Lexer) throws
    
    /// Whether this rule can consume its required data from a given lexer.
    /// May not indicate a call to `consume(from:)` will be successful, that is,
    /// if `false`, indicates a call to `consume(from:)` will definitely fail,
    /// but if `true`, indicates a call to `consume(from:)` may be successful.
    func canConsume(from lexer: Lexer) -> Bool
    
    /// Returns the maximal length this grammar rule can consume from a given lexer,
    /// if successful.
    ///
    /// Returns nil, if an error ocurred while consuming the rule.
    func maximumLength(in lexer: Lexer) -> Int?
    
    /// Returns `true` if this grammar rule validates effectively when applied on
    /// a given lexer.
    ///
    /// Gives a better guarantee than using `canConsume(from:)` since that method
    /// does a cheaper validation of whether an initial consumption attempt can
    /// be performed without immediate failures.
    ///
    /// This method returns the lexer to the previous state before returning.
    func passes(in lexer: Lexer) -> Bool
}

public extension LexerGrammarRule {
    func maximumLength(in lexer: Lexer) -> Int? {
        do {
            let start = lexer.inputIndex
            
            let end: Lexer.Index = try lexer.withTemporaryIndex {
                try stepThroughApplying(on: lexer)
                return lexer.inputIndex
            }
            
            return lexer.inputString.distance(from: start, to: end)
        } catch {
            return nil
        }
    }
    
    func passes(in lexer: Lexer) -> Bool {
        do {
            _=try lexer.withTemporaryIndex {
                try stepThroughApplying(on: lexer)
            }
            
            return true
        } catch {
            return false
        }
    }
}


/// Type-erasing type over `LexerGrammarRule`
public struct AnyGrammarRule<T>: LexerGrammarRule {
    public typealias Result = T
    
    @usableFromInline
    internal let _ruleDescription: () -> String
    @usableFromInline
    internal let _consume: (Lexer) throws -> T
    @usableFromInline
    internal let _stepThroughApplying: (Lexer) throws -> Void
    @usableFromInline
    internal let _canConsume: (Lexer) -> Bool
    
    public var ruleDescription: String {
        return _ruleDescription()
    }
    
    public let containsRecursiveRule: Bool
    
    /// Creates a type-erased AnyGrammarRule<T> over a given grammar rule.
    @inlinable
    public init<U: LexerGrammarRule>(_ rule: U) where U.Result == T {
        _ruleDescription = { rule.ruleDescription }
        containsRecursiveRule = rule.containsRecursiveRule
        _consume = rule.consume(from:)
        _stepThroughApplying = rule.stepThroughApplying(on:)
        _canConsume = rule.canConsume(from:)
    }
    
    /// Creates a type-erased AnyGrammarRule<T> over a given grammar rule, with
    /// a transformer that takes that grammar's result and attempts to transform
    /// into another type, which is then returned by `AnyGrammarRule`'s `consume`
    /// method.
    @inlinable
    public init<U: LexerGrammarRule, S: StringProtocol>(rule: U, transformer: @escaping (S, Lexer.Index) throws -> T) where U.Result == S {
        _ruleDescription = { rule.ruleDescription }
        containsRecursiveRule = rule.containsRecursiveRule
        _consume = { lexer in
            let index = lexer.inputIndex
            let res = try rule.consume(from: lexer)
            
            return try transformer(res, index)
        }
        _stepThroughApplying = rule.stepThroughApplying(on:)
        _canConsume = rule.canConsume(from:)
    }
    
    @inlinable
    public func consume(from lexer: Lexer) throws -> T {
        return try _consume(lexer)
    }
    
    @inlinable
    public func stepThroughApplying(on lexer: Lexer) throws {
        return try _stepThroughApplying(lexer)
    }
    
    @inlinable
    public func canConsume(from lexer: Lexer) -> Bool {
        return _canConsume(lexer)
    }
}

/// Allows recursion into a `GrammarRule` node
public final class RecursiveGrammarRule: LexerGrammarRule {
    private var _rule: GrammarRule
    
    public var ruleName: String
    
    public var ruleDescription: String {
        return _rule.ruleDescription
    }
    
    public var containsRecursiveRule: Bool {
        return true
    }
    
    public init(ruleName: String, rule: GrammarRule) {
        self.ruleName = ruleName
        self._rule = rule
    }
    
    public func setRule(rule: GrammarRule) {
        self._rule = rule
    }
    
    public func consume(from lexer: Lexer) throws -> Substring {
        return try _rule.consume(from: lexer)
    }
    
    public func stepThroughApplying(on lexer: Lexer) throws {
        try _rule.stepThroughApplying(on: lexer)
    }
    
    public func canConsume(from lexer: Lexer) -> Bool {
        return _rule.canConsume(from: lexer)
    }
    
    /// Calls a block that takes a recursive grammar rule and must return a grammar
    /// rule that uses it somewhere.
    ///
    /// The static method then takes care of properly tying up the recursion semantics.
    public static func create(named: String, _ block: (RecursiveGrammarRule) -> GrammarRule) -> GrammarRule {
        let _recursive = RecursiveGrammarRule(ruleName: named, rule: .digit)
        _recursive.setRule(rule: block(_recursive))
        let recursive = GrammarRule.recursive(_recursive)
        
        return recursive
    }
}

/// Specifies basic grammar rules that can be used to create potent grammar parsers.
///
/// - digit: A digit from [0-9].
/// - letter: A lowercase or uppercase letter [a-zA-Z]
/// - whitespace: A whitespace specifier [\s\t\r\n]
/// - char: A single unicode character
/// - keyword: A string keyword
/// - recursive: A grammar rule that has a recursion on itself
/// - namedRule: Encapsulates a grammar rule with a semantic name, useful during
///     debugging.
/// - optional: Parses a rule if it's available, but safely ignores if not.
/// - oneOrMore: Attempts to parse one or more instances of a rule until it cannot
/// anymore. Fails if at least one instance of the rule cannot be parsed.
/// - zeroOrMore: Attempts to parse zero or more instances of a rule until it cannot
/// anymore. Safely bails if a first parsing instance cannot be parsed.
/// - or: Attempts to parse one of the grammar rules specified on an array.
/// Always tries to parse from the first to the last rule on the array.
/// - sequence: Attempts to parse a sequence of grammar rules, ignoring any whitespace
/// between the rules.
/// - directSequence: Attempts to parse a sequence of rules taking into consideration
/// any whitespace between the tokens. Fails if an unexpected whitespace is found
/// between rules.
public enum GrammarRule: LexerGrammarRule, Equatable, ExpressibleByUnicodeScalarLiteral, ExpressibleByArrayLiteral {
    case digit
    case letter
    case whitespace
    case char(Lexer.Atom)
    case keyword(String)
    case recursive(RecursiveGrammarRule)
    indirect case namedRule(name: String, GrammarRule)
    indirect case optional(GrammarRule)
    indirect case oneOrMore(GrammarRule)
    indirect case zeroOrMore(GrammarRule)
    indirect case or([GrammarRule])
    indirect case sequence([GrammarRule])
    indirect case directSequence([GrammarRule])
    
    @usableFromInline
    internal var requiresParenthesis: Bool {
        switch self {
        case .digit, .letter, .whitespace, .oneOrMore, .zeroOrMore, .optional,
             .keyword, .char, .recursive, .namedRule, .or:
            return false
        case .sequence, .directSequence:
            return true
        }
    }
    
    @usableFromInline
    internal var requiresParenthesisInRegex: Bool {
        switch self {
        case .digit, .letter, .oneOrMore, .zeroOrMore, .optional,
             .keyword, .char, .recursive, .namedRule, .or:
            return false
        case .whitespace, .sequence, .directSequence:
            return true
        }
    }
    
    @inlinable
    public var containsRecursiveRule: Bool {
        switch self {
        case .digit, .letter, .whitespace, .char, .keyword:
            return false
            
        case .recursive:
            return true
            
        case .namedRule(_, let rule),
             .optional(let rule),
             .oneOrMore(let rule),
             .zeroOrMore(let rule):
            return rule.containsRecursiveRule
            
        case .or(let rules), .sequence(let rules), .directSequence(let rules):
            return rules.contains(where: { $0.containsRecursiveRule })
        }
    }
    
    @inlinable
    public var ruleDescription: String {
        switch self {
        case .digit:
            return "[0-9]"
            
        case .letter:
            return "[a-zA-Z]"
            
        case .whitespace:
            return "[\\s\\t\\r\\n]"
            
        case .char(let ch):
            return "'\(ch)'"
            
        case .keyword(let str):
            return "'\(str)'"
            
        case .recursive(let rec):
            return rec.ruleName
            
        case .namedRule(let name, _):
            return name
            
        case .optional(let rule):
            if rule.requiresParenthesis {
                return "(\(rule.ruleDescription))?"
            }
            
            return "\(rule.ruleDescription)?"
            
        case .oneOrMore(let rule):
            if rule.requiresParenthesis {
                return "(\(rule.ruleDescription))+"
            }
            
            return "\(rule.ruleDescription)+"
            
        case .zeroOrMore(let rule):
            if rule.requiresParenthesis {
                return "(\(rule.ruleDescription))*"
            }
            
            return "\(rule.ruleDescription)*"
            
        case .or(let rules):
            return "(\(rules.map { $0.ruleDescription }.joined(separator: " | ")))"
        case .sequence(let rules):
            return rules.map { $0.ruleDescription }.joined(separator: " ")
        case .directSequence(let rules):
            return rules.map { $0.ruleDescription }.joined(separator: "")
        }
    }
    
    public init(unicodeScalarLiteral value: Lexer.Atom) {
        self = .char(value)
    }
    
    public init(arrayLiteral elements: GrammarRule...) {
        // Arrays with one rule compose into an optional.
        // This is a syntactic feature mostly, and used to provide a more natural
        // grammar when using the DSL.
        if elements.count == 1 {
            self = .optional(elements[0])
        } else {
            self = .sequence(elements)
        }
    }
    
    @inlinable
    public func consume(from lexer: Lexer) throws -> Substring {
        return try lexer.consumeString(performing: stepThroughApplying)
    }
    
    @inlinable
    public func stepThroughApplying(on lexer: Lexer) throws {
        // Simplify sequence cases since we'll just have to run the lexers one
        // by one during canConsume, anyway.
        switch self {
        case .directSequence(let rules):
            for rule in rules {
                try rule.stepThroughApplying(on: lexer)
            }
            
            return
        case .sequence(let rules):
            guard let first = rules.first else {
                return
            }
            
            try first.stepThroughApplying(on: lexer)
            
            for rule in rules.dropFirst() {
                let whitespaceBacktrack = lexer.backtracker()
                
                // Skip whitespace between tokens
                lexer.skipWhitespace()
                
                let startIndex = lexer.inputIndex
                try rule.stepThroughApplying(on: lexer)
                
                // If no tokens where consumed, rewind back from whitespace
                if startIndex == lexer.inputIndex {
                    whitespaceBacktrack.backtrack(lexer: lexer)
                }
            }
            
            return
        default:
            break
        }
       
        if !canConsume(from: lexer) {
            throw lexer.unexpectedCharacterError(char: try lexer.peek(), "Expected \(self.ruleDescription)")
        }
        
        switch self {
        case .digit, .letter, .whitespace:
            lexer.unsafeAdvance()
            
        case .namedRule(_, let rule):
            try rule.stepThroughApplying(on: lexer)
            
        case .optional(let subRule):
            if !subRule.canConsume(from: lexer) {
                return
            }
            
            try? subRule.stepThroughApplying(on: lexer)
            
        case .char(let ch):
            try lexer.advance(expectingCurrent: ch)
            
        case .keyword(let str):
            if !lexer.advanceIf(equals: str) {
                throw lexer.unexpectedStringError("Expected \(ruleDescription)")
            }
            
        case .recursive(let rec):
            try rec.stepThroughApplying(on: lexer)
            
        case .oneOrMore(let subRule):
            // Micro-optimization for .digit, .letter, .whitespace and .char rules
            switch subRule {
            case .digit:
                try lexer.advance(validatingCurrent: Lexer.isDigit)
                lexer.advance(while: Lexer.isDigit)
            case .letter:
                try lexer.advance(validatingCurrent: Lexer.isLetter)
                lexer.advance(while: Lexer.isLetter)
            case .whitespace:
                try lexer.advance(validatingCurrent: Lexer.isWhitespace)
                lexer.advance(while: Lexer.isWhitespace)
            case .char(let ch):
                try lexer.advance(expectingCurrent: ch)
                lexer.advance(while: { $0 == ch })
                
            default:
                try subRule.stepThroughApplying(on: lexer)
                
                repeat {
                    let backtracker = lexer.backtracker()
                    
                    do {
                        try subRule.stepThroughApplying(on: lexer)
                    } catch {
                        backtracker.backtrack(lexer: lexer)
                        break
                    }
                } while subRule.canConsume(from: lexer)
            }
            
        case .zeroOrMore(let subRule):
            // Micro-optimization for .digit, .letter, .whitespace and .char rules
            switch subRule {
            case .digit:
                lexer.advance(while: Lexer.isDigit)
            case .letter:
                lexer.advance(while: Lexer.isLetter)
            case .whitespace:
                lexer.advance(while: Lexer.isWhitespace)
            case .char(let ch):
                lexer.advance(while: { $0 == ch })
                
            default:
                if !subRule.canConsume(from: lexer) {
                    return
                }
                
                repeat {
                    let backtracker = lexer.backtracker()
                    
                    do {
                        try subRule.stepThroughApplying(on: lexer)
                    } catch {
                        backtracker.backtrack(lexer: lexer)
                        break
                    }
                } while subRule.canConsume(from: lexer)
            }
            
        case .or(let rules):
            var indexAfter: Lexer.Index?
            for rule in rules {
                do {
                    let res = try lexer.withTemporaryIndex { () -> Lexer.Index in
                        try rule.stepThroughApplying(on: lexer)
                        return lexer.inputIndex
                    }
                    
                    indexAfter = res
                    break
                } catch {
                    
                }
            }
            
            guard let index = indexAfter else {
                throw lexer.syntaxError("Failed to parse with rule \(ruleDescription)")
            }
            
            lexer.inputIndex = index
            
        case .directSequence, .sequence:
            fatalError("Should have handled .directSequence/.sequence case at top")
        }
    }
    
    @inlinable
    public func canConsume(from lexer: Lexer) -> Bool {
        switch self {
        case .digit:
            return lexer.safeNextCharPasses(with: Lexer.isDigit)
        case .letter:
            return lexer.safeNextCharPasses(with: Lexer.isLetter)
        case .whitespace:
            return lexer.safeNextCharPasses(with: Lexer.isWhitespace)
            
        case .char(let ch):
            return lexer.safeIsNextChar(equalTo: ch)
            
        case .keyword(""):
            return true
            
        case .keyword(let word):
            return word.unicodeScalars.first == (try? lexer.peek())
            
        case .namedRule(_, let rule),
             .oneOrMore(let rule):
            return rule.canConsume(from: lexer)
            
        case .recursive(let rule):
            return rule.canConsume(from: lexer)
            
        case .zeroOrMore, .optional:
            // Zero or more and optional can always consume
            return true
            
        case .or(let rules):
            for rule in rules {
                if rule.canConsume(from: lexer) {
                    return true
                }
            }
            
            return false
            
        case .sequence(let rules), .directSequence(let rules):
            return lexer.withTemporaryIndex {
                // If the first consumer works, assume the remaining will as well
                // and try on.
                // This will aid in avoiding extreme recursions.
                guard let rule = rules.first else {
                    return false
                }
                
                if !rule.canConsume(from: lexer) {
                    return false
                }
                
                do {
                    try rule.stepThroughApplying(on: lexer)
                    return true
                } catch {
                    return false
                }
            }
        }
    }
    
    /// Returns a regex-compatible string describing this grammar rule.
    /// Traps in case `containsRecursiveRule == true`.
    ///
    /// - seealso: `containsRecursiveRule`
    public func regexString() -> String {
        switch self {
        case .digit:
            return "[0-9]"
            
        case .letter:
            return "[a-zA-Z]"
            
        case .whitespace:
            return "\\s+"
            
        case .char(let ch):
            return escapeRegex("\(ch)")
            
        case .keyword(let str):
            return escapeRegex("\(str)")
            
        case .recursive:
            fatalError("Cannot generate regex for recursive grammar rules")
            
        case .namedRule(_, let rule):
            return rule.regexString()
            
        case .optional(let rule):
            if rule.requiresParenthesisInRegex {
                return "(\(rule.regexString()))?"
            }
            
            return "\(rule.regexString())?"
            
        case .oneOrMore(let rule):
            if rule.requiresParenthesisInRegex {
                return "(\(rule.regexString()))+"
            }
            
            return "\(rule.regexString())+"
            
        case .zeroOrMore(let rule):
            if rule.requiresParenthesisInRegex {
                return "(\(rule.regexString()))*"
            }
            
            return "\(rule.regexString())*"
            
        case .or(let rules):
            return "(\(rules.map { $0.regexString() }.joined(separator: "|")))"
        case .sequence(let rules):
            return rules.map { $0.regexString() }.joined(separator: "\\s*")
        case .directSequence(let rules):
            return rules.map { $0.regexString() }.joined(separator: "")
        }
    }
    
    func escapeRegex(_ string: String) -> String {
        do {
            let escapedCharacters = [
                ".", "*", "+", "?", "^", "$", "\\", "{", "}", "(", ")", "[", "]"
            ].map { "\\\($0)" }
            
            let pattern = "([\(escapedCharacters.joined())])"
            let regex = try NSRegularExpression(pattern: pattern)
            
            let range = NSRange(string.startIndex..<string.endIndex, in: string)
            return regex.stringByReplacingMatches(in: string, options: .anchored, range: range, withTemplate: "\\\\$1")
        } catch {
            return string
        }
    }
}

extension RecursiveGrammarRule: Equatable {
    public static func ==(lhs: RecursiveGrammarRule, rhs: RecursiveGrammarRule) -> Bool {
        return lhs === rhs
    }
}
