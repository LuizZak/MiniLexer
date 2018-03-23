import MiniLexer

/// A parser that reads from a lexer using grammar rules and outputs parser nodes
open class Parser {
    public var lexer: Lexer
    
    public init(lexer: Lexer) {
        self.lexer = lexer
    }
    
    open func parse(rule: GrammarRule) -> ParserNode {
        return ParserNode()
    }
}
