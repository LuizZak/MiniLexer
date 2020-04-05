//
//  TypeLexersTests.swift
//  TypeLexingTests
//
//  Created by Luiz Fernando Silva on 14/01/18.
//

import XCTest
import MiniLexer
@testable import TypeLexing

class TypeLexersTests: XCTestCase {
    
    func testLexInteger() throws {
        let lexerInt = Parser(input: "128")
        let lexerNegativeInt = Parser(input: "-128")
        let lexerSpaceBetweenSign = Parser(input: "- 128")
        let lexerNotInt = Parser(input: "a123")
        let lexerEmpty = Parser(input: "")
        
        XCTAssertEqual(128, try Int.tokenLexer.consume(from: lexerInt))
        XCTAssertEqual(-128, try Int.tokenLexer.consume(from: lexerNegativeInt))
        XCTAssertThrowsError(try Int.tokenLexer.consume(from: lexerSpaceBetweenSign))
        XCTAssertThrowsError(try Int.tokenLexer.consume(from: lexerNotInt))
        XCTAssertThrowsError(try Int.tokenLexer.consume(from: lexerEmpty))
    }
    
    func testLexInt8() throws {
        let lexerInt = Parser(input: "128")
        let lexerNegativeInt = Parser(input: "-128")
        let lexerSpaceBetweenSign = Parser(input: "- 128")
        let lexerNotInt = Parser(input: "a123")
        let lexerEmpty = Parser(input: "")
        
        XCTAssertThrowsError(try Int8.tokenLexer.consume(from: lexerInt))
        XCTAssertEqual(-128, try Int8.tokenLexer.consume(from: lexerNegativeInt))
        XCTAssertThrowsError(try Int8.tokenLexer.consume(from: lexerSpaceBetweenSign))
        XCTAssertThrowsError(try Int8.tokenLexer.consume(from: lexerNotInt))
        XCTAssertThrowsError(try Int8.tokenLexer.consume(from: lexerEmpty))
    }
    
    func testLexUInt8() throws {
        let lexerInt = Parser(input: "128")
        let lexerNegativeInt = Parser(input: "-128")
        let lexerOverflow = Parser(input: "256")
        let lexerSpaceBetweenSign = Parser(input: "- 128")
        let lexerNotInt = Parser(input: "a123")
        let lexerEmpty = Parser(input: "")
        
        XCTAssertEqual(128, try UInt8.tokenLexer.consume(from: lexerInt))
        XCTAssertThrowsError(try UInt8.tokenLexer.consume(from: lexerOverflow))
        XCTAssertThrowsError(try UInt8.tokenLexer.consume(from: lexerNegativeInt))
        XCTAssertThrowsError(try UInt8.tokenLexer.consume(from: lexerSpaceBetweenSign))
        XCTAssertThrowsError(try UInt8.tokenLexer.consume(from: lexerNotInt))
        XCTAssertThrowsError(try UInt8.tokenLexer.consume(from: lexerEmpty))
    }
    
    func testLexFloat() {
        let lexerInt = Parser(input: "128")
        let lexerNegativeInt = Parser(input: "-128")
        let lexerDecimalPlace = Parser(input: "128.5")
        let lexerDecimalPlaceExponent = Parser(input: "1.5e2")
        let lexerDecimalPlaceExponentCapitalE = Parser(input: "1.5E2")
        let lexerDecimalPlacePositiveExponent = Parser(input: "1.5e+2")
        let lexerDecimalPlaceNegativeExponent = Parser(input: "1.5e-2")
        let lexerLargestPositiveValue = Parser(input: "3.402823e+38")
        let lexerLargestNegativeValue = Parser(input: "3.402823e-38")
        let lexerOverflow = Parser(input: "3.402823e+39")
        let lexerSpaceBetweenSign = Parser(input: "- 128")
        let lexerNotNumber = Parser(input: "a123")
        let lexerEmpty = Parser(input: "")
        
        XCTAssertEqual(128, try Float.tokenLexer.consume(from: lexerInt))
        XCTAssertEqual(-128, try Float.tokenLexer.consume(from: lexerNegativeInt))
        XCTAssertEqual(128.5, try Float.tokenLexer.consume(from: lexerDecimalPlace))
        XCTAssertEqual(1.5e2, try Float.tokenLexer.consume(from: lexerDecimalPlaceExponent))
        XCTAssertEqual(1.5E2, try Float.tokenLexer.consume(from: lexerDecimalPlaceExponentCapitalE))
        XCTAssertEqual(1.5e+2, try Float.tokenLexer.consume(from: lexerDecimalPlacePositiveExponent))
        XCTAssertEqual(1.5e-2, try Float.tokenLexer.consume(from: lexerDecimalPlaceNegativeExponent))
        XCTAssertEqual(3.402823e+38, try Float.tokenLexer.consume(from: lexerLargestPositiveValue))
        XCTAssertEqual(3.402823e-38, try Float.tokenLexer.consume(from: lexerLargestNegativeValue))
        XCTAssertThrowsError(try Float.tokenLexer.consume(from: lexerOverflow))
        XCTAssertThrowsError(try Float.tokenLexer.consume(from: lexerSpaceBetweenSign))
        XCTAssertThrowsError(try Float.tokenLexer.consume(from: lexerNotNumber))
        XCTAssertThrowsError(try Float.tokenLexer.consume(from: lexerEmpty))
    }
    
    func testLexDouble() {
        let lexerInt = Parser(input: "128")
        let lexerNegativeInt = Parser(input: "-128")
        let lexerDecimalPlace = Parser(input: "128.5")
        let lexerDecimalPlaceExponent = Parser(input: "1.5e2")
        let lexerDecimalPlaceExponentCapitalE = Parser(input: "1.5E2")
        let lexerDecimalPlacePositiveExponent = Parser(input: "1.5e+2")
        let lexerDecimalPlaceNegativeExponent = Parser(input: "1.5e-2")
        let lexerLargestPositiveValue = Parser(input: "1.7976931348623157e+308")
        let lexerLargestNegativeValue = Parser(input: "1.7976931348623157e-307")
        let lexerOverflow = Parser(input: "1.7976931348623157e+309")
        let lexerSpaceBetweenSign = Parser(input: "- 128")
        let lexerNotNumber = Parser(input: "a123")
        let lexerEmpty = Parser(input: "")
        
        XCTAssertEqual(128, try Double.tokenLexer.consume(from: lexerInt))
        XCTAssertEqual(-128, try Double.tokenLexer.consume(from: lexerNegativeInt))
        XCTAssertEqual(128.5, try Double.tokenLexer.consume(from: lexerDecimalPlace))
        XCTAssertEqual(1.5e2, try Double.tokenLexer.consume(from: lexerDecimalPlaceExponent))
        XCTAssertEqual(1.5E2, try Double.tokenLexer.consume(from: lexerDecimalPlaceExponentCapitalE))
        XCTAssertEqual(1.5e+2, try Double.tokenLexer.consume(from: lexerDecimalPlacePositiveExponent))
        XCTAssertEqual(1.5e-2, try Double.tokenLexer.consume(from: lexerDecimalPlaceNegativeExponent))
        XCTAssertEqual(1.7976931348623157e+308, try Double.tokenLexer.consume(from: lexerLargestPositiveValue))
        XCTAssertEqual(1.7976931348623157e-307, try Double.tokenLexer.consume(from: lexerLargestNegativeValue))
        XCTAssertThrowsError(try Double.tokenLexer.consume(from: lexerOverflow))
        XCTAssertThrowsError(try Double.tokenLexer.consume(from: lexerSpaceBetweenSign))
        XCTAssertThrowsError(try Double.tokenLexer.consume(from: lexerNotNumber))
        XCTAssertThrowsError(try Double.tokenLexer.consume(from: lexerEmpty))
    }
    
    func testPerformance() {
        let tokenLexer = Double.tokenLexer
        
        measure {
            do {
                for _ in 0..<100 {
                    let lexerInt = Parser(input: "128")
                    let lexerNegativeInt = Parser(input: "-128")
                    let lexerDecimalPlace = Parser(input: "128.5")
                    let lexerDecimalPlaceExponent = Parser(input: "1.5e2")
                    let lexerDecimalPlaceExponentCapitalE = Parser(input: "1.5E2")
                    let lexerDecimalPlacePositiveExponent = Parser(input: "1.5e+2")
                    let lexerDecimalPlaceNegativeExponent = Parser(input: "1.5e-2")
                    let lexerLargestPositiveValue = Parser(input: "1.7976931348623157e+308")
                    let lexerLargestNegativeValue = Parser(input: "1.7976931348623157e-307")
                    
                    _ = try tokenLexer.consume(from: lexerInt)
                    _ = try tokenLexer.consume(from: lexerNegativeInt)
                    _ = try tokenLexer.consume(from: lexerDecimalPlace)
                    _ = try tokenLexer.consume(from: lexerDecimalPlaceExponent)
                    _ = try tokenLexer.consume(from: lexerDecimalPlaceExponentCapitalE)
                    _ = try tokenLexer.consume(from: lexerDecimalPlacePositiveExponent)
                    _ = try tokenLexer.consume(from: lexerDecimalPlaceNegativeExponent)
                    _ = try tokenLexer.consume(from: lexerLargestPositiveValue)
                    _ = try tokenLexer.consume(from: lexerLargestNegativeValue)
                }
            } catch {
                
            }
        }
    }
}
