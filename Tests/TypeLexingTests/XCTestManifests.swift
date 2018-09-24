import XCTest

extension TypeLexersTests {
    static let __allTests = [
        ("testLexDouble", testLexDouble),
        ("testLexFloat", testLexFloat),
        ("testLexInt8", testLexInt8),
        ("testLexInteger", testLexInteger),
        ("testLexUInt8", testLexUInt8),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(TypeLexersTests.__allTests),
    ]
}
#endif
