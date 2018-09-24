import XCTest

import MiniLexerTests
import TypeLexingTests
import URLParseSampleTests

var tests = [XCTestCaseEntry]()
tests += MiniLexerTests.__allTests()
tests += TypeLexingTests.__allTests()
tests += URLParseSampleTests.__allTests()

XCTMain(tests)
