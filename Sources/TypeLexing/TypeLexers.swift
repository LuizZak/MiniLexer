import Foundation
import MiniLexer

public extension SignedInteger where Self: FixedWidthInteger {
    static var tokenLexer: AnyGrammarRule<Self> {
        return AnyGrammarRule(rule: ["-"] + .digit+) { result, index in
            guard let value = Self.init(result) else {
                throw ParserError.syntaxError(index, "Could not parse \(self) from string \(result)")
            }
            
            return value
        }
    }
}

public extension UnsignedInteger where Self: FixedWidthInteger {
    static var tokenLexer: AnyGrammarRule<Self> {
        return AnyGrammarRule(rule: .digit+) { result, index in
            guard let value = Self(result) else {
                throw ParserError.syntaxError(index, "Could not parse \(self) from string \(result)")
            }
            
            return value
        }
    }
}

public extension Float {
    static var tokenLexer: AnyGrammarRule<Float> {
        let rule: GrammarRule =
            ["-"] + .digit+ + ["." + .digit+] + [("e" | "E") + ["+" | "-"] + .digit+]
        
        return AnyGrammarRule(rule: rule) { result, index in
            guard let value = Float(result) else {
                throw ParserError.syntaxError(index, "Could not parse Float from string \(result)")
            }
            
            return value
        }
    }
}

public extension Double {
    static var tokenLexer: AnyGrammarRule<Double> {
        let rule: GrammarRule =
            ["-"] + .digit+ + ["." + .digit+] + [("e" | "E") + ["+" | "-"] + .digit+]
        
        return AnyGrammarRule(rule: rule) { result, index in
            guard let value = Double(result) else {
                throw ParserError.syntaxError(index, "Could not parse Double from string \(result)")
            }
            
            return value
        }
    }
}
