import XCTest

extension URLParseSampleTests {
    static let __allTests = [
        ("testEdgeCases", testEdgeCases),
        ("testGeneratedURLs", testGeneratedURLs),
        ("testParseIPV4", testParseIPV4),
        ("testParsePath", testParsePath),
        ("testParseURI", testParseURI),
        ("testParseURIFull", testParseURIFull),
        ("testParseURIPerformance", testParseURIPerformance),
        ("testParseURIPerformance_FoundationURL", testParseURIPerformance_FoundationURL),
        ("testSimpleParse", testSimpleParse),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(URLParseSampleTests.__allTests),
    ]
}
#endif
