precedencegroup GrammarSequencePrecedence {
    associativity: left
    higherThan: RangeFormationPrecedence
    lowerThan: AdditionPrecedence
}

infix operator .. : GrammarSequencePrecedence

postfix operator *
postfix operator +

/// Creates a sequence rule from two grammar rules.
///
/// Produces:
///
/// ```
/// result:
///   lhs rhs
/// ```
public func ..(lhs: GrammarRule, rhs: GrammarRule) -> GrammarRule {
    switch (lhs, rhs) {
    case let (.sequence(left), .sequence(right)):
        return .sequence(left + right)
    case let (.sequence(left), right):
        return .sequence(left + [right])
    case let (left, .sequence(right)):
        return .sequence([left] + right)
    case let (left, right):
        return .sequence([left, right])
    }
}

/// Creates a zero-or-more rule from a grammar rule.
///
/// Produces:
///
/// ```
/// result:
///   lhs*
/// ```
public postfix func *(lhs: GrammarRule) -> GrammarRule {
    return .zeroOrMore(lhs)
}

/// Creates a zero-or-more rule from an array of grammar rules, automatically creating
/// a sequence from the rules array.
///
/// Produces:
///
/// ```
/// result:
///   (lhs0 lhs1 lhs2 [...] lhsN)*
/// ```
public postfix func *(lhs: Array<GrammarRule>) -> GrammarRule {
    return .zeroOrMore(.sequence(lhs))
}

/// Creates a one-or-more rule from a grammar rule.
///
/// Produces:
///
/// ```
/// result:
///   lhs+
/// ```
public postfix func +(lhs: GrammarRule) -> GrammarRule {
    return .oneOrMore(lhs)
}

/// Creates a one-or-more rule from an array of grammar rules, automatically creating
/// a sequence from the rules array.
///
/// Produces:
///
/// ```
/// result:
///   (lhs0 lhs1 lhs2 [...] lhsN)+
/// ```
public postfix func +(lhs: Array<GrammarRule>) -> GrammarRule {
    return .oneOrMore(.sequence(lhs))
}

/// Concatenates rules such that the resulting rule is an `OR` operation between
/// the two rules.
///
/// Produces:
///
/// ```
/// result:
///   lhs | rhs
/// ```
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

/// Creates a direct sequence rule from two grammar rules.
///
/// Produces:
///
/// ```
/// result:
///   [lhs][rhs]
/// ```
public func +(lhs: GrammarRule, rhs: GrammarRule) -> GrammarRule {
    switch (lhs, rhs) {
    case let (.directSequence(left), .directSequence(right)):
        return .directSequence(left + right)
    case let (.directSequence(left), right):
        return .directSequence(left + [right])
    case let (left, .directSequence(right)):
        return .directSequence([left] + right)
    case let (left, right):
        return .directSequence([left, right])
    }
}
