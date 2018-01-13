import MiniLexer

/// A parser that reads from a lexer using grammar rules and outputs parser nodes
public class Parser {
    public var lexer: Lexer
    
    init(lexer: Lexer) {
        self.lexer = lexer
    }
    
    public func parse(rule: GrammarRule) -> ParserNode {
        return ParserNode()
    }
}
