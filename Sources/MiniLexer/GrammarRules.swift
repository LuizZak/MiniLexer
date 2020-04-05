import Foundation

/// A grammar rule that consumes from a Parser and returns a resulting type
public protocol ParserGrammarRule {
    associatedtype Result = Substring
    
    /// A short, formal description of this grammar rule to be used during debugging
    /// and error reporting
    var ruleDescription: String { get }
    
    /// Returns `true` if this rule contains any subrule that is recursive, or if
    /// this rule is recursive itself.
    var containsRecursiveRule: Bool { get }
    
    /// Consumes the required rule from a parser.
    /// Simply catches a substring from the parser's current position all the way
    /// to its later index after a call to `ParserGrammarRule.parse(with:)`
    func consume(from parser: Parser) throws -> Result
    
    /// Parses with a given parser, but does't return a result, simply advances the
    /// parser's offset as if it was parsed by `ParserGrammarRule.consume(from:)`.
    func stepThroughApplying(on parser: Parser) throws
    
    /// Whether this rule can consume its required data from a given parser.
    /// May not indicate a call to `consume(from:)` will be successful, that is,
    /// if `false`, indicates a call to `consume(from:)` will definitely fail,
    /// but if `true`, indicates a call to `consume(from:)` may be successful.
    func canConsume(from parser: Parser) -> Bool
    
    /// Returns the maximal length this grammar rule can consume from a given
    /// parser, if successful.
    ///
    /// Returns nil, if an error ocurred while consuming the rule.
    func maximumLength(in parser: Parser) -> Int?
    
    /// Returns `true` if this grammar rule validates effectively when applied on
    /// a given parser.
    ///
    /// Gives a better guarantee than using `canConsume(from:)` since that method
    /// does a cheaper validation of whether an initial consumption attempt can
    /// be performed without immediate failures.
    ///
    /// This method returns the parser to the previous state before returning.
    func passes(in parser: Parser) -> Bool
}

public extension ParserGrammarRule {
    func maximumLength(in parser: Parser) -> Int? {
        do {
            let start = parser.inputIndex
            
            let end: Parser.Index = try parser.withTemporaryIndex {
                try stepThroughApplying(on: parser)
                return parser.inputIndex
            }
            
            return parser.inputString.distance(from: start, to: end)
        } catch {
            return nil
        }
    }
    
    func passes(in parser: Parser) -> Bool {
        do {
            _=try parser.withTemporaryIndex {
                try stepThroughApplying(on: parser)
            }
            
            return true
        } catch {
            return false
        }
    }
}


/// Type-erasing type over `ParserGrammarRule`
public struct AnyGrammarRule<T>: ParserGrammarRule {
    public typealias Result = T
    
    @usableFromInline
    internal let _ruleDescription: () -> String
    @usableFromInline
    internal let _consume: (Parser) throws -> T
    @usableFromInline
    internal let _stepThroughApplying: (Parser) throws -> Void
    @usableFromInline
    internal let _canConsume: (Parser) -> Bool
    
    public var ruleDescription: String {
        return _ruleDescription()
    }
    
    public let containsRecursiveRule: Bool
    
    /// Creates a type-erased AnyGrammarRule<T> over a given grammar rule.
    @inlinable
    public init<U: ParserGrammarRule>(_ rule: U) where U.Result == T {
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
    public init<U: ParserGrammarRule, S: StringProtocol>(rule: U, transformer: @escaping (S, Parser.Index) throws -> T) where U.Result == S {
        _ruleDescription = { rule.ruleDescription }
        containsRecursiveRule = rule.containsRecursiveRule
        _consume = { parser in
            let index = parser.inputIndex
            let res = try rule.consume(from: parser)
            
            return try transformer(res, index)
        }
        _stepThroughApplying = rule.stepThroughApplying(on:)
        _canConsume = rule.canConsume(from:)
    }
    
    @inlinable
    public func consume(from parser: Parser) throws -> T {
        return try _consume(parser)
    }
    
    @inlinable
    public func stepThroughApplying(on parser: Parser) throws {
        return try _stepThroughApplying(parser)
    }
    
    @inlinable
    public func canConsume(from parser: Parser) -> Bool {
        return _canConsume(parser)
    }
}

/// Allows recursion into a `GrammarRule` node
public final class RecursiveGrammarRule: ParserGrammarRule {
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
    
    public func consume(from parser: Parser) throws -> Substring {
        return try _rule.consume(from: parser)
    }
    
    public func stepThroughApplying(on parser: Parser) throws {
        try _rule.stepThroughApplying(on: parser)
    }
    
    public func canConsume(from parser: Parser) -> Bool {
        return _rule.canConsume(from: parser)
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
public enum GrammarRule: ParserGrammarRule, Equatable, ExpressibleByUnicodeScalarLiteral, ExpressibleByArrayLiteral {
    case digit
    case letter
    case whitespace
    case char(Parser.Atom)
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
    
    public init(unicodeScalarLiteral value: Parser.Atom) {
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
    public func consume(from parser: Parser) throws -> Substring {
        return try parser.consumeString(performing: stepThroughApplying)
    }
    
    @inlinable
    public func stepThroughApplying(on parser: Parser) throws {
        // Simplify sequence cases since we'll just have to run the parser one
        // by one during canConsume, anyway.
        switch self {
        case .directSequence(let rules):
            for rule in rules {
                try rule.stepThroughApplying(on: parser)
            }
            
            return
        case .sequence(let rules):
            guard let first = rules.first else {
                return
            }
            
            try first.stepThroughApplying(on: parser)
            
            for rule in rules.dropFirst() {
                let whitespaceBacktrack = parser.backtracker()
                
                // Skip whitespace between tokens
                parser.skipWhitespace()
                
                let startIndex = parser.inputIndex
                try rule.stepThroughApplying(on: parser)
                
                // If no tokens where consumed, rewind back from whitespace
                if startIndex == parser.inputIndex {
                    whitespaceBacktrack.backtrack(parser: parser)
                }
            }
            
            return
        default:
            break
        }
       
        if !canConsume(from: parser) {
            throw parser.unexpectedCharacterError(char: try parser.peek(), "Expected \(self.ruleDescription)")
        }
        
        switch self {
        case .digit, .letter, .whitespace:
            parser.unsafeAdvance()
            
        case .namedRule(_, let rule):
            try rule.stepThroughApplying(on: parser)
            
        case .optional(let subRule):
            if !subRule.canConsume(from: parser) {
                return
            }
            
            try? subRule.stepThroughApplying(on: parser)
            
        case .char(let ch):
            try parser.advance(expectingCurrent: ch)
            
        case .keyword(let str):
            if !parser.advanceIf(equals: str) {
                throw parser.unexpectedStringError("Expected \(ruleDescription)")
            }
            
        case .recursive(let rec):
            try rec.stepThroughApplying(on: parser)
            
        case .oneOrMore(let subRule):
            // Micro-optimization for .digit, .letter, .whitespace and .char rules
            switch subRule {
            case .digit:
                try parser.advance(validatingCurrent: Parser.isDigit)
                parser.advance(while: Parser.isDigit)
            case .letter:
                try parser.advance(validatingCurrent: Parser.isLetter)
                parser.advance(while: Parser.isLetter)
            case .whitespace:
                try parser.advance(validatingCurrent: Parser.isWhitespace)
                parser.advance(while: Parser.isWhitespace)
            case .char(let ch):
                try parser.advance(expectingCurrent: ch)
                parser.advance(while: { $0 == ch })
                
            default:
                try subRule.stepThroughApplying(on: parser)
                
                repeat {
                    let backtracker = parser.backtracker()
                    
                    do {
                        try subRule.stepThroughApplying(on: parser)
                    } catch {
                        backtracker.backtrack(parser: parser)
                        break
                    }
                } while subRule.canConsume(from: parser)
            }
            
        case .zeroOrMore(let subRule):
            // Micro-optimization for .digit, .letter, .whitespace and .char rules
            switch subRule {
            case .digit:
                parser.advance(while: Parser.isDigit)
            case .letter:
                parser.advance(while: Parser.isLetter)
            case .whitespace:
                parser.advance(while: Parser.isWhitespace)
            case .char(let ch):
                parser.advance(while: { $0 == ch })
                
            default:
                if !subRule.canConsume(from: parser) {
                    return
                }
                
                repeat {
                    let backtracker = parser.backtracker()
                    
                    do {
                        try subRule.stepThroughApplying(on: parser)
                    } catch {
                        backtracker.backtrack(parser: parser)
                        break
                    }
                } while subRule.canConsume(from: parser)
            }
            
        case .or(let rules):
            var indexAfter: Parser.Index?
            for rule in rules {
                do {
                    let res = try parser.withTemporaryIndex { () -> Parser.Index in
                        try rule.stepThroughApplying(on: parser)
                        return parser.inputIndex
                    }
                    
                    indexAfter = res
                    break
                } catch {
                    
                }
            }
            
            guard let index = indexAfter else {
                throw parser.syntaxError("Failed to parse with rule \(ruleDescription)")
            }
            
            parser.inputIndex = index
            
        case .directSequence, .sequence:
            fatalError("Should have handled .directSequence/.sequence case at top")
        }
    }
    
    @inlinable
    public func canConsume(from parser: Parser) -> Bool {
        switch self {
        case .digit:
            return parser.safeNextCharPasses(with: Parser.isDigit)
        case .letter:
            return parser.safeNextCharPasses(with: Parser.isLetter)
        case .whitespace:
            return parser.safeNextCharPasses(with: Parser.isWhitespace)
            
        case .char(let ch):
            return parser.safeIsNextChar(equalTo: ch)
            
        case .keyword(let word) where word.isEmpty:
            return true
            
        case .keyword(let word):
            return word.unicodeScalars.first == (try? parser.peek())
            
        case .namedRule(_, let rule),
             .oneOrMore(let rule):
            return rule.canConsume(from: parser)
            
        case .recursive(let rule):
            return rule.canConsume(from: parser)
            
        case .zeroOrMore, .optional:
            // Zero or more and optional can always consume
            return true
            
        case .or(let rules):
            for rule in rules {
                if rule.canConsume(from: parser) {
                    return true
                }
            }
            
            return false
            
        case .sequence(let rules), .directSequence(let rules):
            return parser.withTemporaryIndex {
                // If the first consumer works, assume the remaining will as well
                // and try on.
                // This will aid in avoiding extreme recursions.
                guard let rule = rules.first else {
                    return false
                }
                
                if !rule.canConsume(from: parser) {
                    return false
                }
                
                do {
                    try rule.stepThroughApplying(on: parser)
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
            return "\\s"
            
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
