postfix operator *
postfix operator +

public postfix func *(lhs: GrammarRule) -> GrammarRule {
    return .zeroOrMore(lhs)
}

public postfix func *(lhs: Array<GrammarRule>) -> GrammarRule {
    return .zeroOrMore(.sequence(lhs))
}

public postfix func +(lhs: GrammarRule) -> GrammarRule {
    return .oneOrMore(lhs)
}

public postfix func +(lhs: Array<GrammarRule>) -> GrammarRule {
    return .oneOrMore(.sequence(lhs))
}

public func |(lhs: GrammarRule, rhs: GrammarRule) -> GrammarRule {
    switch (lhs, rhs) {
    case let (.or(l), .or(r)):
        return .or(l + r)
        
    case let (.or(l), r):
        return .or(l + [r])
    case let (l, .or(r)):
        return .or([l] + r)
        
    default:
        return .or([lhs, rhs])
    }
}
