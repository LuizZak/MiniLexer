import Foundation
import MiniLexer

public extension SignedInteger where Self: FixedWidthInteger {
    static var tokenLexer: AnyGrammarRule<Self> {
        return AnyGrammarRule(rule: ["-"] + .digit+) { result, index in
            guard let value = Self.init(result) else {
                throw LexerError.syntaxError(index, "Could not parse \(self) from string \(result)")
            }
            
            return value
        }
    }
}

public extension UnsignedInteger where Self: FixedWidthInteger {
    static var tokenLexer: AnyGrammarRule<Self> {
        return AnyGrammarRule(rule: .digit+) { result, index in
            guard let value = Self(result) else {
                throw LexerError.syntaxError(index, "Could not parse \(self) from string \(result)")
            }
            
            return value
        }
    }
}

public extension FloatingPoint where Self: BinaryFloatingPoint & LosslessStringConvertible {
    static var tokenLexer: AnyGrammarRule<Self> {
        let rule: GrammarRule =
            ["-"] + .digit+ + ["." + .digit+] + [("e" | "E") + ["+" | "-"] + .digit+]
        
        return AnyGrammarRule(rule: rule) { result, index in
            guard let value = Self(String(result)) else {
                throw LexerError.syntaxError(index, "Could not parse Float from string \(result)")
            }
            
            return value
        }
    }
}
