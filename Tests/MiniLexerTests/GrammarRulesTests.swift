import XCTest
@testable import MiniLexer

public class GrammarRuleTests: XCTestCase {
    
    func testGrammarRuleDigit() throws {
        let rule = GrammarRule.digit
        let lexer = Lexer(input: "123")
        
        XCTAssertEqual("1", try rule.consume(from: lexer))
        XCTAssertEqual("[0-9]", rule.ruleDescription)
    }
    
    func testGrammarRuleLetter() throws {
        let rule = GrammarRule.letter
        let lexer = Lexer(input: "abc")
        
        XCTAssertEqual("a", try rule.consume(from: lexer))
        XCTAssertEqual("[a-zA-Z]", rule.ruleDescription)
    }
    
    func testGrammarRuleWhitespace() throws {
        let rule = GrammarRule.whitespace
        let lexer = Lexer(input: " ")
        
        XCTAssertEqual(" ", try rule.consume(from: lexer))
        XCTAssertEqual("[\\s\\t\\r\\n]", rule.ruleDescription)
    }
    
    func testGrammarRuleChar() throws {
        let rule = GrammarRule.char("@")
        let lexer1 = Lexer(input: "@test")
        let lexer2 = Lexer(input: " @test")
        let lexer3 = Lexer(input: "test")
        let lexer4 = Lexer(input: "")
        
        XCTAssertEqual("@", try rule.consume(from: lexer1))
        XCTAssertEqual("@", try rule.consume(from: lexer2))
        XCTAssertThrowsError(try rule.consume(from: lexer3))
        XCTAssertThrowsError(try rule.consume(from: lexer4))
        XCTAssertEqual("'@'", rule.ruleDescription)
    }
    
    func testGrammarRuleKeyword() throws {
        let rule = GrammarRule.keyword("test")
        let lexer1 = Lexer(input: "test")
        let lexer2 = Lexer(input: " test test")
        let lexer3 = Lexer(input: "tes")
        let lexer4 = Lexer(input: "testtest")
        
        XCTAssertEqual("test", try rule.consume(from: lexer1))
        XCTAssertEqual("test", try rule.consume(from: lexer2))
        XCTAssertThrowsError(try rule.consume(from: lexer3))
        XCTAssertThrowsError(try rule.consume(from: lexer4))
        XCTAssertEqual("test", rule.ruleDescription)
    }
    
    func testGrammarNamedRule() throws {
        let rule = GrammarRule.namedRule(name: "number", .digit+)
        let lexer1 = Lexer(input: "123")
        let lexer2 = Lexer(input: "a")
        
        XCTAssertEqual("123", try rule.consume(from: lexer1))
        XCTAssertThrowsError(try rule.consume(from: lexer2))
        XCTAssertEqual("number", rule.ruleDescription)
    }
    
    func testGrammarRuleOneOrMore() throws {
        let rule = GrammarRule.oneOrMore(.digit)
        let lexer1 = Lexer(input: "123")
        let lexer2 = Lexer(input: "a")
        
        XCTAssertEqual("123", try rule.consume(from: lexer1))
        XCTAssertThrowsError(try rule.consume(from: lexer2))
        XCTAssertEqual("[0-9]+", rule.ruleDescription)
    }
    
    func testGrammarRuleZeroOrMore() throws {
        let rule = GrammarRule.zeroOrMore(.digit)
        let lexer1 = Lexer(input: "123")
        let lexer2 = Lexer(input: "a")
        
        XCTAssertEqual("123", try rule.consume(from: lexer1))
        XCTAssertEqual("", try rule.consume(from: lexer2))
        XCTAssertEqual("[0-9]*", rule.ruleDescription)
    }
    
    func testGrammarRuleOr() throws {
        let rule = GrammarRule.or([.digit, .letter])
        let lexer = Lexer(input: "a1")
        
        XCTAssertEqual("a", try rule.consume(from: lexer))
        XCTAssertEqual("1", try rule.consume(from: lexer))
        XCTAssertEqual("[0-9] | [a-zA-Z]", rule.ruleDescription)
    }
    
    func testGrammarRuleOneOrMoreOr() throws {
        let rule = GrammarRule.oneOrMore(.or([.digit, .letter]))
        let lexer1 = Lexer(input: "ab123")
        let lexer2 = Lexer(input: "ab 123")
        
        XCTAssertEqual("ab123", try rule.consume(from: lexer1))
        XCTAssertEqual("ab", try rule.consume(from: lexer2))
        XCTAssertEqual("([0-9] | [a-zA-Z])+", rule.ruleDescription)
    }
    
    func testGrammarRuleOptional() throws {
        let rule = GrammarRule.optional(.digit)
        let lexer1 = Lexer(input: "12")
        let lexer2 = Lexer(input: "")
        
        XCTAssertEqual("1", try rule.consume(from: lexer1))
        XCTAssertEqual("", try rule.consume(from: lexer2))
        XCTAssertEqual("[0-9]?", rule.ruleDescription)
    }
    
    func testGrammarRuleSequence() throws {
        let rule = GrammarRule.sequence([.letter, .digit])
        let lexer1 = Lexer(input: "a 1")
        let lexer2 = Lexer(input: "aa 2")
        
        XCTAssertEqual("a 1", try rule.consume(from: lexer1))
        XCTAssertThrowsError(try rule.consume(from: lexer2))
        XCTAssertEqual("[a-zA-Z] [0-9]", rule.ruleDescription)
    }
    
    func testGrammarRuleDirectSequence() throws {
        let rule = GrammarRule.directSequence([.letter, .digit])
        let lexer1 = Lexer(input: "a1")
        let lexer2 = Lexer(input: "aa2")
        
        XCTAssertEqual("a1", try rule.consume(from: lexer1))
        XCTAssertThrowsError(try rule.consume(from: lexer2))
        XCTAssertEqual("[a-zA-Z][0-9]", rule.ruleDescription)
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
        
        let lexer1 = Lexer(input: "abc, def, ghi")
        // let lexer2 = Lexer(input: "abc, def,")
        
        // Act
        let result = try argList.consume(from: lexer1)
        
        // Assert
        // XCTAssertThrowsError(try argList.consume(from: lexer2)) // TODO: Should this error or not?
        XCTAssertEqual("abc, def, ghi", result)
        XCTAssertEqual("arg (',' argList)*", argList.ruleDescription)
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
    
    func testRecursiveGrammarRuleCreate() throws {
        let rule = RecursiveGrammarRule.create(named: "list") { (rec) -> GrammarRule in
            return .sequence([.letter, [",", .recursive(rec)]*])
        }
        
        let lexer1 = Lexer(input: "a, b, c")
        let lexer2 = Lexer(input: ", , b")
        
        XCTAssertEqual("a, b, c", try rule.consume(from: lexer1))
        XCTAssertThrowsError(try rule.consume(from: lexer2))
    }
    
    func testGrammarRuleComplex() throws {
        // Tests a fully flexed complex grammar for a list of items enclosed
        // within parens
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
        //   [a-zA-Z_] [a-zA-Z_0-9]*
        //
        
        // Arrange
        let ident: GrammarRule = [.letter | "_", (.letter | "_" | .digit)*]
        let modifier: GrammarRule = .namedRule(name: "modifier", ident)
        
        let modifierList = RecursiveGrammarRule.create(named: "modifierList") {
            .sequence([modifier, [",", .recursive($0)]*])
        }
        
        let propertyModifierList: GrammarRule = ["(", modifierList, ")"]
        
        let lexer1 = Lexer(input: "(mod1, mod2)")
        let lexer2 = Lexer(input: "(mod1, )")
        
        // Act/assert
        XCTAssertEqual("(mod1, mod2)", try propertyModifierList.consume(from: lexer1))
        XCTAssertThrowsError(try propertyModifierList.consume(from: lexer2))
    }
    
    func testGrammarRulePerformance() {
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
        //   [a-zA-Z_] [a-zA-Z_0-9]*
        //
        
        let ident: GrammarRule = [.letter | "_", (.letter | "_" | .digit)*]
        let modifier: GrammarRule = .namedRule(name: "modifier", ident)
        
        let modifierList = RecursiveGrammarRule.create(named: "modifierList") {
            .sequence([modifier, [",", .recursive($0)]*])
        }
        
        let propertyModifierList: GrammarRule = ["(", modifierList, ")"]
        
        measure {
            for _ in 0...100 {
                let lexer = Lexer(input: "(mod1, mod2, mod3, mod4, mod5, mod6, mod7, mod8, mod9, mod10)")
                _=try! propertyModifierList.consume(from: lexer)
            }
        }
    }
}
