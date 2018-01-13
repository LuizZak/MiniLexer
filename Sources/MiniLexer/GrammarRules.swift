/// A grammar rule that consumes from a Lexer and returns a resulting type
public protocol LexerGrammarRule {
    associatedtype Result = Substring
    
    /// A short, formal description of this grammar rule to be used during debugging
    /// and error reporting
    var ruleDescription: String { get }
    
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
}

/// Allows recursion into a `GrammarRule` node
public class RecursiveGrammarRule: LexerGrammarRule {
    private var _rule: GrammarRule
    
    public var ruleName: String
    
    public var ruleDescription: String {
        return _rule.ruleDescription
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
public enum GrammarRule: LexerGrammarRule, ExpressibleByUnicodeScalarLiteral, ExpressibleByArrayLiteral {
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
    
    private var isRuleWithMany: Bool {
        switch self {
        case .digit, .letter, .whitespace, .oneOrMore, .zeroOrMore, .optional, .keyword, .char, .recursive, .namedRule:
            return false
        case .or, .sequence, .directSequence:
            return true
        }
    }
    
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
            return str
            
        case .recursive(let rec):
            return rec.ruleName
            
        case .namedRule(let name, _):
            return name
            
        case .optional(let rule):
            if rule.isRuleWithMany {
                return "(\(rule.ruleDescription))?"
            }
            
            return "\(rule.ruleDescription)?"
            
        case .oneOrMore(let rule):
            if rule.isRuleWithMany {
                return "(\(rule.ruleDescription))+"
            }
            
            return "\(rule.ruleDescription)+"
            
        case .zeroOrMore(let rule):
            if rule.isRuleWithMany {
                return "(\(rule.ruleDescription))*"
            }
            
            return "\(rule.ruleDescription)*"
            
        case .or(let rules):
            return rules.map { $0.ruleDescription }.joined(separator: " | ")
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
        self = .sequence(elements)
    }
    
    public func consume(from lexer: Lexer) throws -> Substring {
        return try lexer.consumeString(performing: stepThroughApplying)
    }
    
    public func stepThroughApplying(on lexer: Lexer) throws {
        // Simplify sequence cases since we'll just have to run the lexers one
        // by one during canConsume, anyway.
        if case .directSequence(let rules) = self {
            for rule in rules {
                try rule.stepThroughApplying(on: lexer)
            }
            
            return
        }
        if case .sequence(let rules) = self {
            for (i, rule) in rules.enumerated() {
                try rule.stepThroughApplying(on: lexer)
                // Skip whitespace between tokens, appending them along the way
                if i < rules.count - 1 {
                    lexer.skipWhitespace()
                }
            }
            
            return
        }
        
        if !canConsume(from: lexer) {
            throw lexer.unexpectedCharacterError(char: try lexer.peek(), "Expected \(self.ruleDescription)")
        }
        
        switch self {
        case .digit, .letter, .whitespace:
            try lexer.advance()
            
        case .namedRule(_, let rule):
            try rule.stepThroughApplying(on: lexer)
            
        case .optional(let subRule):
            if !subRule.canConsume(from: lexer) {
                return
            }
            
            do {
                try subRule.stepThroughApplying(on: lexer)
            } catch {
                
            }
            
        case .char(let ch):
            try lexer.advance(expectingCurrent: ch)
            
        case .keyword(let str):
            if !lexer.advanceIf(equals: str) {
                throw lexer.unexpectedStringError("Expected \(ruleDescription)")
            }
            
        case .recursive(let rec):
            try rec.stepThroughApplying(on: lexer)
            
        case .oneOrMore(let subRule):
            while subRule.canConsume(from: lexer) {
                try subRule.stepThroughApplying(on: lexer)
            }
            
        case .zeroOrMore(let subRule):
            if !subRule.canConsume(from: lexer) {
                return
            }
            
            while subRule.canConsume(from: lexer) {
                try subRule.stepThroughApplying(on: lexer)
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
                throw LexerError.syntaxError("Failed to parse with rule \(ruleDescription)")
            }
            
            lexer.inputIndex = index
            
        case .directSequence, .sequence:
            fatalError("Should have handled .directSequence/.sequence case at top")
        }
    }
    
    public func canConsume(from lexer: Lexer) -> Bool {
        switch self {
        case .digit:
            return lexer.safeNextCharPasses(with: Lexer.isDigit)
        case .letter:
            return lexer.safeNextCharPasses(with: Lexer.isLetter)
        case .whitespace:
            return lexer.safeNextCharPasses(with: Lexer.isWhitespace)
            
        case .char(let ch):
            return lexer.withTemporaryIndex {
                lexer.skipWhitespace()
                return lexer.safeIsNextChar(equalTo: ch)
            }
            
        case .keyword:
            return !lexer.isEof()
            
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
            
        case .sequence(let rules):
            return lexer.withTemporaryIndex {
                // If the first consumer works, assume the remaining will
                // as well and try on.
                // This will aid in avoiding extreme recursions.
                guard let rule = rules.first else {
                    return false
                }
                
                do {
                    try rule.stepThroughApplying(on: lexer)
                    return true
                } catch {
                    return false
                }
            }
            
        case .directSequence(let rules):
            return lexer.withTemporaryIndex {
                for rule in rules {
                    if !rule.canConsume(from: lexer) {
                        return false
                    }
                    
                    do {
                        // If the first consumer works, assume the remaining will
                        // as well and try on.
                        // This will aid in avoiding extreme recursions.
                        try rule.stepThroughApplying(on: lexer)
                        return true
                    } catch {
                        return false
                    }
                }
                
                return true
            }
        }
    }
}
