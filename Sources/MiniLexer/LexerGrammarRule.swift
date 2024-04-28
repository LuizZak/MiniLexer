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
