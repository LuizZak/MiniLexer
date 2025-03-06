import XCTest
import MiniLexer

extension XCTestCase {
    func assertThrowsEof<T>(_ block: @autoclosure () throws -> T, file: String = #file, line: Int = #line) {
        do {
            _=try block()
            record(.init(type: .assertionFailure, compactDescription: "Expected function to throw"))
        } catch let error as LexerError {
            switch error {
            case .endOfStringError:
                // Success
                break
            default:
                record(.init(type: .assertionFailure, compactDescription: "Expected function to throw end-of-file error, but received error: '\(error)'"))
            }
        } catch {
            record(.init(type: .assertionFailure, compactDescription: "Expected function to throw 'LexerError', but received: \(error)"))
        }
    }
}
