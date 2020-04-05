import XCTest
import MiniLexer

extension XCTestCase {
    func assertThrowsEof<T>(_ block: @autoclosure () throws -> T, file: String = #file, line: Int = #line) {
        do {
            _=try block()
            recordFailure(withDescription: "Expected function to throw",
                          inFile: file, atLine: line, expected: true)
        } catch let error as ParserError {
            switch error {
            case .endOfStringError:
                // Success
                break
            default:
                recordFailure(withDescription: "Expected function to throw end-of-file error, but received error: '\(error)'",
                              inFile: file, atLine: line, expected: true)
            }
        } catch {
            recordFailure(withDescription: "Expected function to throw 'LexerError', but received: \(error)",
                          inFile: file, atLine: line, expected: true)
        }
    }
}
