import XCTest
@testable import MiniLexer

public class GrammarRuleTests: XCTestCase {
    
    func testGrammarRuleDigit() throws {
        let rule = GrammarRule.digit
        let parser = Parser(input: "123")
        let parser2 = Parser(input: "abc")
        
        XCTAssert(rule.canConsume(from: parser))
        XCTAssertFalse(rule.canConsume(from: parser2))
        XCTAssertFalse(rule.containsRecursiveRule)
        XCTAssertEqual("1", try rule.consume(from: parser))
        XCTAssertEqual("[0-9]", rule.ruleDescription)
        XCTAssertEqual("[0-9]", rule.regexString())
    }
    
    func testGrammarRuleLetter() throws {
        let rule = GrammarRule.letter
        let parser = Parser(input: "abc")
        let parser2 = Parser(input: "1")
        
        XCTAssert(rule.canConsume(from: parser))
        XCTAssertFalse(rule.canConsume(from: parser2))
        XCTAssertFalse(rule.containsRecursiveRule)
        XCTAssertEqual("a", try rule.consume(from: parser))
        XCTAssertEqual("[a-zA-Z]", rule.ruleDescription)
        XCTAssertEqual("[a-zA-Z]", rule.regexString())
    }
    
    func testGrammarRuleWhitespace() throws {
        let rule = GrammarRule.whitespace
        let parser = Parser(input: " ")
        let parser2 = Parser(input: "1")
        
        XCTAssert(rule.canConsume(from: parser))
        XCTAssertFalse(rule.canConsume(from: parser2))
        XCTAssertFalse(rule.containsRecursiveRule)
        XCTAssertEqual(" ", try rule.consume(from: parser))
        XCTAssertEqual("[\\s\\t\\r\\n]", rule.ruleDescription)
        XCTAssertEqual("\\s", rule.regexString())
    }
    
    func testGrammarRuleChar() throws {
        let rule = GrammarRule.char("@")
        let parser1 = Parser(input: "@test")
        let parser2 = Parser(input: " @test")
        let parser3 = Parser(input: "test")
        let parser4 = Parser(input: "")
        
        XCTAssertEqual("@", try rule.consume(from: parser1))
        XCTAssertThrowsError(try rule.consume(from: parser2))
        XCTAssertThrowsError(try rule.consume(from: parser3))
        XCTAssertThrowsError(try rule.consume(from: parser4))
        XCTAssertFalse(rule.containsRecursiveRule)
        XCTAssertEqual("'@'", rule.ruleDescription)
        XCTAssertEqual("@", rule.regexString())
    }
    
    func testGrammarRuleKeyword() throws {
        let rule = GrammarRule.keyword("test")
        let parser1 = Parser(input: "test")
        let parser2 = Parser(input: " test test")
        let parser3 = Parser(input: "tes")
        let parser4 = Parser(input: "testtest")
        
        XCTAssertEqual("test", try rule.consume(from: parser1))
        XCTAssertThrowsError(try rule.consume(from: parser2))
        XCTAssertThrowsError(try rule.consume(from: parser3))
        XCTAssertEqual("test", try rule.consume(from: parser4))
        XCTAssertFalse(rule.containsRecursiveRule)
        XCTAssertEqual("'test'", rule.ruleDescription)
        XCTAssertEqual("test", rule.regexString())
    }
    
    func testGrammarNamedRule() throws {
        let rule = GrammarRule.namedRule(name: "number", .digit+)
        let parser1 = Parser(input: "123")
        let parser2 = Parser(input: "a")
        
        XCTAssertEqual("123", try rule.consume(from: parser1))
        XCTAssertThrowsError(try rule.consume(from: parser2))
        XCTAssertFalse(rule.containsRecursiveRule)
        XCTAssertEqual("number", rule.ruleDescription)
        XCTAssertEqual("[0-9]+", rule.regexString())
    }
    
    func testGrammarNamedOptional() throws {
        let rule = GrammarRule.optional(.digit)
        let parser1 = Parser(input: "123")
        let parser2 = Parser(input: "a")
        
        XCTAssertEqual("1", try rule.consume(from: parser1))
        XCTAssertEqual("", try rule.consume(from: parser2))
        XCTAssertFalse(rule.containsRecursiveRule)
        XCTAssertEqual("[0-9]?", rule.ruleDescription)
        XCTAssertEqual("[0-9]?", rule.regexString())
    }
    
    func testGrammarRuleOneOrMore() throws {
        let rule = GrammarRule.oneOrMore(.digit)
        let parser1 = Parser(input: "123")
        let parser2 = Parser(input: "a")
        
        XCTAssertEqual("123", try rule.consume(from: parser1))
        XCTAssertThrowsError(try rule.consume(from: parser2))
        XCTAssertFalse(rule.containsRecursiveRule)
        XCTAssertEqual("[0-9]+", rule.ruleDescription)
        XCTAssertEqual("[0-9]+", rule.regexString())
    }
    
    func testGrammarRuleZeroOrMore() throws {
        let rule = GrammarRule.zeroOrMore(.digit)
        let parser1 = Parser(input: "123")
        let parser2 = Parser(input: "a")
        
        XCTAssertEqual("123", try rule.consume(from: parser1))
        XCTAssertEqual("", try rule.consume(from: parser2))
        XCTAssertFalse(rule.containsRecursiveRule)
        XCTAssertEqual("[0-9]*", rule.ruleDescription)
        XCTAssertEqual("[0-9]*", rule.regexString())
    }
    
    func testGrammarRuleOr() throws {
        let rule = GrammarRule.or([.digit, .letter])
        let parser = Parser(input: "a1")
        
        XCTAssertEqual("a", try rule.consume(from: parser))
        XCTAssertEqual("1", try rule.consume(from: parser))
        XCTAssertFalse(rule.containsRecursiveRule)
        XCTAssertEqual("([0-9] | [a-zA-Z])", rule.ruleDescription)
        XCTAssertEqual("([0-9]|[a-zA-Z])", rule.regexString())
    }
    
    func testGrammarRuleMaximumLengthIn() {
        let rule = GrammarRule.digit
        let parserMatching = Parser(input: "123")
        let parserNonMatching = Parser(input: "a")
        
        XCTAssertEqual(rule.maximumLength(in: parserMatching), 1)
        XCTAssertNil(rule.maximumLength(in: parserNonMatching))
    }
    
    func testGrammarRuleMaximumLengthInWithZeroOrMoreRule() {
        let rule = GrammarRule.digit*
        let parserMatching = Parser(input: "123")
        let parserMatchingPartial = Parser(input: "123abc")
        let parserNonMatching = Parser(input: "a")
        
        XCTAssertEqual(rule.maximumLength(in: parserMatching), 3)
        XCTAssertEqual(rule.maximumLength(in: parserMatchingPartial), 3)
        XCTAssertEqual(rule.maximumLength(in: parserNonMatching), 0)
    }
    
    func testGrammarRuleMaximumLengthInWithGreedyRule() {
        let rule = GrammarRule.digit+
        let parserMatching = Parser(input: "123")
        let parserMatchingPartial = Parser(input: "123abc")
        let parserNonMatching = Parser(input: "a")
        
        XCTAssertEqual(rule.maximumLength(in: parserMatching), 3)
        XCTAssertEqual(rule.maximumLength(in: parserMatchingPartial), 3)
        XCTAssertNil(rule.maximumLength(in: parserNonMatching))
    }
    
    func testGrammarRuleMaximumLengthIgnoresWhitespaceAfterToken() {
        let rule: GrammarRule = ["-"] .. .digit+ .. ["."]
        let parser = Parser(input: "-270 0")
        
        XCTAssertEqual(rule.maximumLength(in: parser), 4)
    }
    
    func testGrammarRulePassesIn() {
        let rule = GrammarRule.digit
        let parserMatching = Parser(input: "123")
        let parserNonMatching = Parser(input: "a")
        
        XCTAssert(rule.passes(in: parserMatching))
        XCTAssertFalse(rule.passes(in: parserNonMatching))
    }
    
    func testGrammarRulePassesInWithZeroOrMoreRule() {
        let rule = GrammarRule.digit*
        let parserMatching = Parser(input: "123")
        let parserNonMatching = Parser(input: "a")
        
        XCTAssert(rule.passes(in: parserMatching))
        XCTAssert(rule.passes(in: parserNonMatching))
    }
    
    func testGramarRuleOrStopsAtFirstMatchFound() throws {
        // test:
        //   ('@keyword' [0-9]+) | ('@keyword' 'abc') | ('@keyword' | 'a')
        //
        // ident:
        //   [a-zA-Z] [a-zA-Z0-9]*
        //
        // number:
        //   [0-9]+
        //
        
        let test =
            (.keyword("@keyword") .. .digit+) | (.keyword("@keyword") .. .keyword("abc")) | (.keyword("@keyword") .. "a")
        
        let parser1 = Parser(input: "@keyword 123")
        let parser2 = Parser(input: "@keyword abc")
        let parser3 = Parser(input: "@keyword a")
        let parser4 = Parser(input: "@keyword _abc")
        
        XCTAssertEqual("@keyword 123", try test.consume(from: parser1))
        XCTAssertEqual("@keyword abc", try test.consume(from: parser2))
        XCTAssertEqual("@keyword a", try test.consume(from: parser3))
        XCTAssertThrowsError(try test.consume(from: parser4))
    }
    
    func testGrammarRuleOneOrMoreOr() throws {
        let rule = GrammarRule.oneOrMore(.or([.digit, .letter]))
        let parser1 = Parser(input: "ab123")
        let parser2 = Parser(input: "ab 123")
        
        XCTAssertEqual("ab123", try rule.consume(from: parser1))
        XCTAssertEqual("ab", try rule.consume(from: parser2))
        XCTAssertEqual("([0-9] | [a-zA-Z])+", rule.ruleDescription)
        XCTAssertEqual(rule, .oneOrMore(.or([.digit, .letter])))
        XCTAssertNotEqual(rule, .oneOrMore(.or([.letter, .digit])))
    }
    
    func testGrammarRuleOptional() throws {
        let rule = GrammarRule.optional(.keyword("abc"))
        let parser1 = Parser(input: "abc")
        let parser2 = Parser(input: "ab")
        let parser3 = Parser(input: "")
        
        XCTAssertEqual("abc", try rule.consume(from: parser1))
        XCTAssertEqual("", try rule.consume(from: parser2))
        XCTAssertEqual("", try rule.consume(from: parser3))
        XCTAssertEqual("'abc'?", rule.ruleDescription)
        XCTAssertEqual(rule, .optional(.keyword("abc")))
        XCTAssertNotEqual(rule, .optional(.keyword("def")))
    }
    
    func testGrammarRuleOptionalRuleDescriptionWithMany() throws {
        XCTAssertEqual("[0-9]?", GrammarRule.optional(.digit).ruleDescription)
        XCTAssertEqual("([0-9])?", GrammarRule.optional(.sequence([.digit])).ruleDescription)
        XCTAssertEqual("([0-9] [a-zA-Z])?", GrammarRule.optional(.sequence([.digit, .letter])).ruleDescription)
        XCTAssertEqual("([0-9][a-zA-Z])?", GrammarRule.optional(.directSequence([.digit, .letter])).ruleDescription)
    }
    
    func testGrammarRuleSequence() throws {
        let rule = GrammarRule.sequence([.letter, .digit])
        let parser1 = Parser(input: "a 1")
        let parser2 = Parser(input: "aa 2")
        
        XCTAssert(rule.canConsume(from: parser1))
        XCTAssert(rule.canConsume(from: parser2))
        XCTAssertEqual("a 1", try rule.consume(from: parser1))
        XCTAssertThrowsError(try rule.consume(from: parser2))
        XCTAssertEqual("[a-zA-Z] [0-9]", rule.ruleDescription)
        XCTAssertEqual(rule, .sequence([.letter, .digit]))
        XCTAssertNotEqual(rule, .sequence([.digit, .letter]))
    }
    
    func testGrammarRuleDirectSequence() throws {
        let rule = GrammarRule.directSequence([.letter, .digit])
        let parser1 = Parser(input: "a1")
        let parser2 = Parser(input: "a 1")
        let parser3 = Parser(input: "aa2")
        let parser4 = Parser(input: " a2")
        
        XCTAssert(rule.canConsume(from: parser1))
        XCTAssert(rule.canConsume(from: parser2)) // TODO: these two could be easy to check as false,
        XCTAssert(rule.canConsume(from: parser3)) // should we ignore possible recursions and do it anyway?
        XCTAssertFalse(rule.canConsume(from: parser4))
        XCTAssertEqual("a1", try rule.consume(from: parser1))
        XCTAssertThrowsError(try rule.consume(from: parser2))
        XCTAssertThrowsError(try rule.consume(from: parser3))
        XCTAssertEqual("[a-zA-Z][0-9]", rule.ruleDescription)
        XCTAssertEqual(rule, .directSequence([.letter, .digit]))
        XCTAssertNotEqual(rule, .directSequence([.digit, .letter]))
    }
    
    func testGrammarRecursive() throws {
        // Test a recursive rule as follows:
        //
        // argList:
        //   arg (',' argList)*
        //
        // arg:
        //   ident
        //
        // ident:
        //   [a-zA-Z]+
        //
        
        // Arrange
        let ident: GrammarRule = .namedRule(name: "ident", .letter+)
        let arg: GrammarRule = .namedRule(name: "arg", ident)
        
        let argList = RecursiveGrammarRule(ruleName: "argList", rule: .digit)
        let recArg = GrammarRule.recursive(argList)
        
        argList.setRule(rule: [arg, [",", recArg]* ])
        
        let parser1 = Parser(input: "abc, def, ghi")
        // let parser2 = parser(input: "abc, def,")
        
        // Act
        let result = try argList.consume(from: parser1)
        
        // Assert
        // XCTAssertThrowsError(try argList.consume(from: parser2)) // TODO: Should this error or not?
        XCTAssert(argList.containsRecursiveRule)
        XCTAssertEqual("abc, def, ghi", result)
        XCTAssertEqual("arg (',' argList)*", argList.ruleDescription)
        XCTAssertEqual(GrammarRule.recursive(argList), .recursive(argList))
    }
    
    func testGrammarRuleOperatorZeroOrMore() {
        let rule = GrammarRule.digit
        let zeroOrMore = rule*
        
        switch zeroOrMore {
        case .zeroOrMore:
            // Success!
            break
        default:
            XCTFail("Expected '*' operator to compose as .zeroOrMore")
        }
    }
    
    func testGrammarRuleOperatorZeroOrMoreOnArray() {
        let rule: [GrammarRule] = [.digit, .letter]
        let zeroOrMore = rule*
        
        switch zeroOrMore {
        case .zeroOrMore(.sequence):
            // Success!
            break
        default:
            XCTFail("Expected '*' operator on array of rules to compose as .zeroOrMore(.sequence)")
        }
    }
    
    func testGrammarRuleOperatorOneOrMore() {
        let rule = GrammarRule.digit
        let oneOrMore = rule+
        
        switch oneOrMore {
        case .oneOrMore:
            // Success!
            break
        default:
            XCTFail("Expected '+' operator to compose as .oneOrMore")
        }
    }
    
    func testGrammarRuleOperatorOneOrMoreOnArray() {
        let rule: [GrammarRule] = [.digit, .letter]
        let oneOrMore = rule+
        
        switch oneOrMore {
        case .oneOrMore(.sequence):
            // Success!
            break
        default:
            XCTFail("Expected '+' operator on array of rules to compose as .oneOrMore(.sequence)")
        }
    }
    
    func testGrammarRuleOperatorOr() {
        let rule1 = GrammarRule.digit
        let rule2 = GrammarRule.letter
        let oneOrMore = rule1 | rule2
        
        switch oneOrMore {
        case .or(let ar):
            XCTAssertEqual(ar.count, 2)
            
            if case .digit = ar[0], case .letter = ar[1] {
                // Success!
                return
            }
            
            XCTFail("Failed to generate proper OR operands")
            break
        default:
            XCTFail("Expected '+' operator to compose as .oneOrMore")
        }
    }
    
    func testGrammarRuleOperatorOrCollapseSequential() {
        let oneOrMore: GrammarRule = .digit | .letter | .char("@")
        
        switch oneOrMore {
        case .or(let ar):
            XCTAssertEqual(ar.count, 3)
            
            if case .digit = ar[0], case .letter = ar[1], case .char("@") = ar[2] {
                // Success!
                return
            }
            
            XCTFail("Failed to generate proper OR operands")
            break
        default:
            XCTFail("Expected '+' operator to compose as .oneOrMore")
        }
    }
    
    func testGrammarRuleOperatorSequence() {
        let rule1 = GrammarRule.digit
        let rule2 = GrammarRule.letter
        let oneOrMore = rule1 .. rule2
        
        switch oneOrMore {
        case .sequence(let ar):
            XCTAssertEqual(ar.count, 2)
            
            if case .digit = ar[0], case .letter = ar[1] {
                // Success!
                return
            }
            
            XCTFail("Failed to generate proper sequence operands")
            break
        default:
            XCTFail("Expected '..' operator to compose as .sequence")
        }
    }
    
    func testGrammarRuleOperatorSequenceCollapseSequential() {
        let oneOrMore: GrammarRule = .digit .. .letter .. .char("@")
        
        switch oneOrMore {
        case .sequence(let ar):
            XCTAssertEqual(ar.count, 3)
            
            if case .digit = ar[0], case .letter = ar[1], case .char("@") = ar[2] {
                // Success!
                return
            }
            
            XCTFail("Failed to generate proper sequence operands")
            break
        default:
            XCTFail("Expected '..' operator to compose as .sequence")
        }
    }
    
    func testGrammarRuleOperatorDirectSequence() {
        let rule1 = GrammarRule.digit
        let rule2 = GrammarRule.letter
        let oneOrMore = rule1 + rule2
        
        switch oneOrMore {
        case .directSequence(let ar):
            XCTAssertEqual(ar.count, 2)
            
            if case .digit = ar[0], case .letter = ar[1] {
                // Success!
                return
            }
            
            XCTFail("Failed to generate proper direct sequence operands")
            break
        default:
            XCTFail("Expected '+' operator to compose as .directSequence")
        }
    }
    
    func testGrammarRuleOperatorDirectSequenceCollapseSequential() {
        let oneOrMore: GrammarRule = .digit + .letter + .char("@")
        
        switch oneOrMore {
        case .directSequence(let ar):
            XCTAssertEqual(ar.count, 3)
            
            if case .digit = ar[0], case .letter = ar[1], case .char("@") = ar[2] {
                // Success!
                return
            }
            
            XCTFail("Failed to generate proper sequence operands")
            break
        default:
            XCTFail("Expected '+' operator to compose as .directSequence")
        }
    }
    
    func testGrammarRuleArrayWithOneItemBecomesOptional() {
        let ruleOptional: GrammarRule = [.digit]
        let ruleSequence: GrammarRule = [.digit, .letter]
        
        switch ruleOptional {
        case .optional(.digit):
            // Success!
            break
        default:
            XCTFail("Expected array literal containing one rule to compose as .optional")
        }
        
        switch ruleSequence {
        case .sequence(let ar):
            XCTAssertEqual(ar.count, 2)
            
            if case .digit = ar[0], case .letter = ar[1] {
                // Success!
                return
            }
            
            XCTFail("Failed to generate proper sequence")
            break
        default:
            XCTFail("Expected array literal containing more than one rule to compose as .sequence")
        }
    }
    
    func testRecursiveGrammarRuleCreate() throws {
        let rule = RecursiveGrammarRule.create(named: "list") { (rec) -> GrammarRule in
            return .sequence([.letter, [",", .recursive(rec)]*])
        }
        
        let parser1 = Parser(input: "a, b, c")
        let parser2 = Parser(input: ", , b")
        
        XCTAssertEqual("a, b, c", try rule.consume(from: parser1))
        XCTAssertThrowsError(try rule.consume(from: parser2))
    }
    
    func testRecursiveGrammarRuleDescription() {
        let rule1 = RecursiveGrammarRule(ruleName: "rule_rec1", rule: .digit)
        let rule2 = RecursiveGrammarRule(ruleName: "rule_rec2", rule: .recursive(rule1))
        
        XCTAssertEqual("[0-9]", rule1.ruleDescription)
        XCTAssertEqual("rule_rec1", rule2.ruleDescription)
    }
    
    func testGrammarRuleComplexNonRecursive() throws {
        // Tests a fully flexed complex grammar for a list of items enclosed
        // within parens, avoiding a recursive rule
        //
        // propertyModifierList:
        //   '(' modifierList ')'
        //
        // modifierList:
        //   modifier (',' modifier)*
        //
        // modifier:
        //   ident
        //
        // ident:
        //   [a-zA-Z_][a-zA-Z_0-9]*
        //
        
        // Arrange
        let ident: GrammarRule = (.letter | "_") + (.letter | "_" | .digit)*
        let modifier: GrammarRule = .namedRule(name: "modifier", ident)
        
        let modifierList: GrammarRule =
            modifier .. ("," .. modifier)*
        
        let propertyModifierList =
            "(" .. modifierList .. ")"
        
        let parser1 = Parser(input: "(mod1, mod2)")
        let parser2 = Parser(input: "(mod1, )")
        
        // Act/assert
        XCTAssertEqual("(mod1, mod2)", try propertyModifierList.consume(from: parser1))
        XCTAssertThrowsError(try propertyModifierList.consume(from: parser2))
    }
    
    func testGrammarRuleComplexRecursive() throws {
        // Tests a fully flexed complex grammar for a list of items enclosed
        // within parens, including a recursive rule
        //
        // propertyModifierList:
        //   '(' modifierList ')'
        //
        // modifierList:
        //   modifier (',' modifierList)*
        //
        // modifier:
        //   ident
        //
        // ident:
        //   [a-zA-Z_][a-zA-Z_0-9]*
        //
        
        // Arrange
        let ident: GrammarRule =
            (.letter | "_") + (.letter | "_" | .digit)*
        let modifier: GrammarRule =
            .namedRule(name: "modifier", ident)
        
        let modifierList = RecursiveGrammarRule.create(named: "modifierList") {
            .sequence([modifier, [",", .recursive($0)]*])
        }
        
        let propertyModifierList =
            "(" .. modifierList .. ")"
        
        let parser1 = Parser(input: "(mod1, mod2)")
        let parser2 = Parser(input: "()")
        let parser3 = Parser(input: "(mod1, )")
        let parser4 = Parser(input: "(mod1, ")
        let parser5 = Parser(input: "( ")
        
        // Act/assert
        XCTAssertEqual("(mod1, mod2)", try propertyModifierList.consume(from: parser1))
        XCTAssertThrowsError(try propertyModifierList.consume(from: parser2))
        XCTAssertThrowsError(try propertyModifierList.consume(from: parser3))
        XCTAssertThrowsError(try propertyModifierList.consume(from: parser4))
        XCTAssertThrowsError(try propertyModifierList.consume(from: parser5))
    }
    
    func testGrammarRuleComplexRecursiveWithLookaheadWithKeyword() throws {
        // Tests a recursive lookahead parsing
        //
        // propertyModifierList:
        //   '(' modifierList ')'
        //
        // modifierList:
        //   modifier (',' modifierList)*
        //
        // modifier:
        //   compound
        //
        // compound:
        //   ('@keyword' 'abc') | ('@keyword' number) | ('@keyword' | 'a')
        //
        // number:
        //   [0-9]+
        //
        
        // Arrange
        let number: GrammarRule =
            .digit+
        
        let compound =
            (.keyword("@keyword") .. .keyword("abc")) | (.keyword("@keyword") .. number) | (.keyword("@keyword") .. "a")
        
        let modifier: GrammarRule =
            .namedRule(name: "modifier", compound)
        
        let modifierList = RecursiveGrammarRule.create(named: "modifierList") {
            modifier .. ("," .. .recursive($0))*
        }
        
        let propertyModifierList =
            "(" .. modifierList .. ")"
        
        let parser1 = Parser(input: "(@keyword 123, @keyword abc, @keyword a)")
        let parser2 = Parser(input: "(@keyword mod, @keyword 123, @keyword a, @keyword abc)")
        let parser3 = Parser(input: "(@keyword ace)")
        let parser4 = Parser(input: "(@keyword b)")
        let parser5 = Parser(input: "(mod1, ")
        let parser6 = Parser(input: "( ")
        
        // Act/assert
        XCTAssertEqual("(@keyword 123, @keyword abc, @keyword a)", try propertyModifierList.consume(from: parser1))
        XCTAssertThrowsError(try propertyModifierList.consume(from: parser2))
        XCTAssertThrowsError(try propertyModifierList.consume(from: parser3))
        XCTAssertThrowsError(try propertyModifierList.consume(from: parser4))
        XCTAssertThrowsError(try propertyModifierList.consume(from: parser5))
        XCTAssertThrowsError(try propertyModifierList.consume(from: parser6))
    }
    
    func testGramarRuleLookahead() throws {
        // test:
        //   ('a' ident) | ('a' number) | ('a' '@keyword')
        //
        // ident:
        //   [a-zA-Z][a-zA-Z0-9]*
        //
        // number:
        //   [0-9]+
        //
        
        let number: GrammarRule =
            .digit+
        
        let ident: GrammarRule =
            (.letter) + (.letter | .digit)*
        
        let test =
            ("a" .. ident) | ("a" .. number) | ("a" .. .keyword("@keyword"))
        
        let parser1 = Parser(input: "a 123")
        let parser2 = Parser(input: "a abc")
        let parser3 = Parser(input: "a @keyword")
        let parser4 = Parser(input: "a _abc")
        
        XCTAssertEqual("a 123", try test.consume(from: parser1))
        XCTAssertEqual("a abc", try test.consume(from: parser2))
        XCTAssertEqual("a @keyword", try test.consume(from: parser3))
        XCTAssertThrowsError(try test.consume(from: parser4))
    }
    
    func testGramarRuleLookaheadWithKeyword() throws {
        // test:
        //   ('@keyword' ident) | ('@keyword' number) | ('@keyword' 'a')
        //
        // ident:
        //   [a-zA-Z][a-zA-Z0-9]*
        //
        // number:
        //   [0-9]+
        //
        
        let number: GrammarRule =
            .digit+
        
        let ident: GrammarRule =
            (.letter) + (.letter | .digit)*
        
        let test =
            (.keyword("@keyword") .. ident) | (.keyword("@keyword") .. number) | (.keyword("@keyword") .. "a")
        
        let parser1 = Parser(input: "@keyword 123")
        let parser2 = Parser(input: "@keyword abc")
        let parser3 = Parser(input: "@keyword a")
        let parser4 = Parser(input: "@keyword _abc")
        
        XCTAssertEqual("@keyword 123", try test.consume(from: parser1))
        XCTAssertEqual("@keyword abc", try test.consume(from: parser2))
        XCTAssertEqual("@keyword a", try test.consume(from: parser3))
        XCTAssertThrowsError(try test.consume(from: parser4))
    }
    
    func testGrammarRulePerformance() {
        // With non-recursive modifierList
        
        // propertyModifierList:
        //   '(' modifierList ')'
        //
        // modifierList:
        //   modifier (',' modifier)*
        //
        // modifier:
        //   ident
        //
        // ident:
        //   [a-zA-Z_][a-zA-Z_0-9]*
        //
        
        let ident: GrammarRule =
            (.letter | "_") + (.letter | "_" | .digit)*
        let modifier: GrammarRule =
            .namedRule(name: "modifier", ident)
        
        let modifierList =
            modifier .. ("," .. modifier)*
        
        let propertyModifierList =
            "(" .. modifierList .. ")"
        
        measure {
            for _ in 0...100 {
                let parser = Parser(input: "(mod1, mod2, mod3, mod4, mod5, mod6, mod7, mod8, mod9, mod10)")
                _=try! propertyModifierList.consume(from: parser)
            }
        }
    }
    
    func testManualLexingPerformance() {
        // With manual lexing without use of GrammarRules
        
        // propertyModifierList:
        //   '(' modifierList ')'
        //
        // modifierList:
        //   modifier (',' modifier)*
        //
        // modifier:
        //   ident
        //
        // ident:
        //   [a-zA-Z_][a-zA-Z_0-9]*
        //
        
        measure {
            do {
                for _ in 0...100 {
                    let parser = Parser(input: "(mod1, mod2, mod3, mod4, mod5, mod6, mod7, mod8, mod9, mod10)")
                    
                    _=try parser.consumeString { parser in
                        try parser.advance(expectingCurrent: "(")
                        
                        var expIdent = true
                        while !parser.safeIsNextChar(equalTo: ")") {
                            expIdent = false
                            
                            parser.skipWhitespace()
                            
                            // Ident
                            try parser.advance(validatingCurrent: { Parser.isLetter($0) || $0 == "_" })
                            parser.advance(while: { Parser.isLetter($0) || Parser.isDigit($0) || $0 == "_" })
                            
                            parser.skipWhitespace()
                            
                            if try parser.peek() == "," {
                                parser.unsafeAdvance()
                                expIdent = true
                            }
                        }
                        
                        if expIdent {
                            throw parser.syntaxError("Expected identifier")
                        }
                        
                        try parser.advance(expectingCurrent: ")")
                    }
                }
            } catch {
                XCTFail("\(error)")
            }
        }
    }
    
    func testGrammarRuleRecursiveWithZeroOrMorePerformance() {
        // With recursive modifierList
        
        // propertyModifierList:
        //   '(' modifierList ')'
        //
        // modifierList:
        //   modifier (',' modifierList)*
        //
        // modifier:
        //   ident
        //
        // ident:
        //   [a-zA-Z_][a-zA-Z_0-9]*
        //
        
        let ident: GrammarRule =
            (.letter | "_") + (.letter | "_" | .digit)*
        
        let modifier: GrammarRule =
            .namedRule(name: "modifier", ident)
        
        let modifierList = RecursiveGrammarRule.create(named: "modifierList") {
            modifier .. ("," .. .recursive($0))*
        }
        
        let propertyModifierList =
            "(" .. modifierList .. ")"
        
        measure {
            for _ in 0...100 {
                let parser = Parser(input: "(mod1, mod2, mod3, mod4, mod5, mod6, mod7, mod8, mod9, mod10)")
                _=try! propertyModifierList.consume(from: parser)
            }
        }
    }
    
    func testGrammarRuleRecursiveWithOptionalPerformance() {
        // With recursive modifierList
        
        // propertyModifierList:
        //   '(' modifierList ')'
        //
        // modifierList:
        //   modifier (',' modifierList)?
        //
        // modifier:
        //   ident
        //
        // ident:
        //   [a-zA-Z_][a-zA-Z_0-9]*
        //
        
        let ident: GrammarRule =
            (.letter | "_") + (.letter | "_" | .digit)*
        
        let modifier: GrammarRule =
            .namedRule(name: "modifier", ident)
        
        let modifierList = RecursiveGrammarRule.create(named: "modifierList") {
            modifier .. ["," .. .recursive($0)]
        }
        
        let propertyModifierList =
            "(" .. modifierList .. ")"
        
        measure {
            for _ in 0...100 {
                let parser = Parser(input: "(mod1, mod2, mod3, mod4, mod5, mod6, mod7, mod8, mod9, mod10)")
                _=try! propertyModifierList.consume(from: parser)
            }
        }
    }
    
    func testGrammarRuleBacktrackingFailedZeroOrMoreRule() {
        // ansi-escape:
        //      "\e[" digit-list? code
        //
        // digit-list:
        //      digit (';' digit-list)*
        //
        // code:
        //      'A'
        //      'B'
        //
        let rule = .keyword("\u{001B}[") .. (.digit+ .. ";")* .. [.digit+] .. ("A" | "B")
        
        let parser1 = Parser(input: "\u{001B}[10A")
        let parser2 = Parser(input: "\u{001B}[A")
        let parser3 = Parser(input: "\u{001B}[10;11B")
        let parser4 = Parser(input: "\u{001B}[3")
        
        XCTAssertEqual("\u{001B}[10A", try rule.consume(from: parser1))
        XCTAssertEqual("\u{001B}[A", try rule.consume(from: parser2))
        XCTAssertEqual("\u{001B}[10;11B", try rule.consume(from: parser3))
        XCTAssertThrowsError(try rule.consume(from: parser4))
    }
    
    func testGrammarRuleBacktrackingFailedOneOrMoreRule() {
        // ansi-escape:
        //      "\e[" digit-list digit? code
        //
        // digit-list:
        //      (digit ';')+
        //
        // code:
        //      'A'
        //      'B'
        //
        let rule = .keyword("\u{001B}[") .. (.digit+ .. ";")+ .. [.digit+] .. ("A" | "B")
        
        let parser1 = Parser(input: "\u{001B}[10;A")
        let parser2 = Parser(input: "\u{001B}[A")
        let parser3 = Parser(input: "\u{001B}[10;11B")
        let parser4 = Parser(input: "\u{001B}[3")
        
        XCTAssertEqual("\u{001B}[10;A", try rule.consume(from: parser1))
        XCTAssertThrowsError(try rule.consume(from: parser2))
        XCTAssertEqual("\u{001B}[10;11B", try rule.consume(from: parser3))
        XCTAssertThrowsError(try rule.consume(from: parser4))
    }
}
