import MiniLexer

public extension SignedInteger where Self: FixedWidthInteger {
    public static var tokenLexer: AnyGrammarRule<Self> {
        return AnyGrammarRule(rule: ["-"] + .digit+) { result in
            guard let value = Self.init(result) else {
                throw LexerError.syntaxError("Could not parse \(self) from string \(result)")
            }
            
            return value
        }
    }
}

public extension UnsignedInteger where Self: FixedWidthInteger {
    public static var tokenLexer: AnyGrammarRule<Self> {
        return AnyGrammarRule(rule: .digit+) { result in
            guard let value = Self(result) else {
                throw LexerError.syntaxError("Could not parse \(self) from string \(result)")
            }
            
            return value
        }
    }
}

public extension Float {
    public static var tokenLexer: AnyGrammarRule<Float> {
        let rule: GrammarRule =
            ["-"] + .digit+ + ["." + .digit+] + [("e" | "E") + ["+" | "-"] + .digit+]
        
        return AnyGrammarRule(rule: rule) { result in
            guard let value = Float(result) else {
                throw LexerError.syntaxError("Could not parse Float from string \(result)")
            }
            
            return value
        }
    }
}

public extension Double {
    public static var tokenLexer: AnyGrammarRule<Double> {
        let rule: GrammarRule =
            ["-"] + .digit+ + ["." + .digit+] + [("e" | "E") + ["+" | "-"] + .digit+]
        
        return AnyGrammarRule(rule: rule) { result in
            guard let value = Double(result) else {
                throw LexerError.syntaxError("Could not parse Double from string \(result)")
            }
            
            return value
        }
    }
}
