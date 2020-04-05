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
        let parserInt = Parser(input: "128")
        let parserNegativeInt = Parser(input: "-128")
        let parserSpaceBetweenSign = Parser(input: "- 128")
        let parserNotInt = Parser(input: "a123")
        let parserEmpty = Parser(input: "")
        
        XCTAssertEqual(128, try Int.tokenLexer.consume(from: parserInt))
        XCTAssertEqual(-128, try Int.tokenLexer.consume(from: parserNegativeInt))
        XCTAssertThrowsError(try Int.tokenLexer.consume(from: parserSpaceBetweenSign))
        XCTAssertThrowsError(try Int.tokenLexer.consume(from: parserNotInt))
        XCTAssertThrowsError(try Int.tokenLexer.consume(from: parserEmpty))
    }
    
    func testLexInt8() throws {
        let parserInt = Parser(input: "128")
        let parserNegativeInt = Parser(input: "-128")
        let parserSpaceBetweenSign = Parser(input: "- 128")
        let parserNotInt = Parser(input: "a123")
        let parserEmpty = Parser(input: "")
        
        XCTAssertThrowsError(try Int8.tokenLexer.consume(from: parserInt))
        XCTAssertEqual(-128, try Int8.tokenLexer.consume(from: parserNegativeInt))
        XCTAssertThrowsError(try Int8.tokenLexer.consume(from: parserSpaceBetweenSign))
        XCTAssertThrowsError(try Int8.tokenLexer.consume(from: parserNotInt))
        XCTAssertThrowsError(try Int8.tokenLexer.consume(from: parserEmpty))
    }
    
    func testLexUInt8() throws {
        let parserInt = Parser(input: "128")
        let parserNegativeInt = Parser(input: "-128")
        let parserOverflow = Parser(input: "256")
        let parserSpaceBetweenSign = Parser(input: "- 128")
        let parserNotInt = Parser(input: "a123")
        let parserEmpty = Parser(input: "")
        
        XCTAssertEqual(128, try UInt8.tokenLexer.consume(from: parserInt))
        XCTAssertThrowsError(try UInt8.tokenLexer.consume(from: parserOverflow))
        XCTAssertThrowsError(try UInt8.tokenLexer.consume(from: parserNegativeInt))
        XCTAssertThrowsError(try UInt8.tokenLexer.consume(from: parserSpaceBetweenSign))
        XCTAssertThrowsError(try UInt8.tokenLexer.consume(from: parserNotInt))
        XCTAssertThrowsError(try UInt8.tokenLexer.consume(from: parserEmpty))
    }
    
    func testLexFloat() {
        let parserInt = Parser(input: "128")
        let parserNegativeInt = Parser(input: "-128")
        let parserDecimalPlace = Parser(input: "128.5")
        let parserDecimalPlaceExponent = Parser(input: "1.5e2")
        let parserDecimalPlaceExponentCapitalE = Parser(input: "1.5E2")
        let parserDecimalPlacePositiveExponent = Parser(input: "1.5e+2")
        let parserDecimalPlaceNegativeExponent = Parser(input: "1.5e-2")
        let parserLargestPositiveValue = Parser(input: "3.402823e+38")
        let parserLargestNegativeValue = Parser(input: "3.402823e-38")
        let parserOverflow = Parser(input: "3.402823e+39")
        let parserSpaceBetweenSign = Parser(input: "- 128")
        let parserNotNumber = Parser(input: "a123")
        let parserEmpty = Parser(input: "")
        
        XCTAssertEqual(128, try Float.tokenLexer.consume(from: parserInt))
        XCTAssertEqual(-128, try Float.tokenLexer.consume(from: parserNegativeInt))
        XCTAssertEqual(128.5, try Float.tokenLexer.consume(from: parserDecimalPlace))
        XCTAssertEqual(1.5e2, try Float.tokenLexer.consume(from: parserDecimalPlaceExponent))
        XCTAssertEqual(1.5E2, try Float.tokenLexer.consume(from: parserDecimalPlaceExponentCapitalE))
        XCTAssertEqual(1.5e+2, try Float.tokenLexer.consume(from: parserDecimalPlacePositiveExponent))
        XCTAssertEqual(1.5e-2, try Float.tokenLexer.consume(from: parserDecimalPlaceNegativeExponent))
        XCTAssertEqual(3.402823e+38, try Float.tokenLexer.consume(from: parserLargestPositiveValue))
        XCTAssertEqual(3.402823e-38, try Float.tokenLexer.consume(from: parserLargestNegativeValue))
        XCTAssertThrowsError(try Float.tokenLexer.consume(from: parserOverflow))
        XCTAssertThrowsError(try Float.tokenLexer.consume(from: parserSpaceBetweenSign))
        XCTAssertThrowsError(try Float.tokenLexer.consume(from: parserNotNumber))
        XCTAssertThrowsError(try Float.tokenLexer.consume(from: parserEmpty))
    }
    
    func testLexDouble() {
        let parserInt = Parser(input: "128")
        let parserNegativeInt = Parser(input: "-128")
        let parserDecimalPlace = Parser(input: "128.5")
        let parserDecimalPlaceExponent = Parser(input: "1.5e2")
        let parserDecimalPlaceExponentCapitalE = Parser(input: "1.5E2")
        let parserDecimalPlacePositiveExponent = Parser(input: "1.5e+2")
        let parserDecimalPlaceNegativeExponent = Parser(input: "1.5e-2")
        let parserLargestPositiveValue = Parser(input: "1.7976931348623157e+308")
        let parserLargestNegativeValue = Parser(input: "1.7976931348623157e-307")
        let parserOverflow = Parser(input: "1.7976931348623157e+309")
        let parserSpaceBetweenSign = Parser(input: "- 128")
        let parserNotNumber = Parser(input: "a123")
        let parserEmpty = Parser(input: "")
        
        XCTAssertEqual(128, try Double.tokenLexer.consume(from: parserInt))
        XCTAssertEqual(-128, try Double.tokenLexer.consume(from: parserNegativeInt))
        XCTAssertEqual(128.5, try Double.tokenLexer.consume(from: parserDecimalPlace))
        XCTAssertEqual(1.5e2, try Double.tokenLexer.consume(from: parserDecimalPlaceExponent))
        XCTAssertEqual(1.5E2, try Double.tokenLexer.consume(from: parserDecimalPlaceExponentCapitalE))
        XCTAssertEqual(1.5e+2, try Double.tokenLexer.consume(from: parserDecimalPlacePositiveExponent))
        XCTAssertEqual(1.5e-2, try Double.tokenLexer.consume(from: parserDecimalPlaceNegativeExponent))
        XCTAssertEqual(1.7976931348623157e+308, try Double.tokenLexer.consume(from: parserLargestPositiveValue))
        XCTAssertEqual(1.7976931348623157e-307, try Double.tokenLexer.consume(from: parserLargestNegativeValue))
        XCTAssertThrowsError(try Double.tokenLexer.consume(from: parserOverflow))
        XCTAssertThrowsError(try Double.tokenLexer.consume(from: parserSpaceBetweenSign))
        XCTAssertThrowsError(try Double.tokenLexer.consume(from: parserNotNumber))
        XCTAssertThrowsError(try Double.tokenLexer.consume(from: parserEmpty))
    }
    
    func testPerformance() {
        let tokenLexer = Double.tokenLexer
        
        measure {
            do {
                for _ in 0..<100 {
                    let parserInt = Parser(input: "128")
                    let parserNegativeInt = Parser(input: "-128")
                    let parserDecimalPlace = Parser(input: "128.5")
                    let parserDecimalPlaceExponent = Parser(input: "1.5e2")
                    let parserDecimalPlaceExponentCapitalE = Parser(input: "1.5E2")
                    let parserDecimalPlacePositiveExponent = Parser(input: "1.5e+2")
                    let parserDecimalPlaceNegativeExponent = Parser(input: "1.5e-2")
                    let parserLargestPositiveValue = Parser(input: "1.7976931348623157e+308")
                    let parserLargestNegativeValue = Parser(input: "1.7976931348623157e-307")
                    
                    _ = try tokenLexer.consume(from: parserInt)
                    _ = try tokenLexer.consume(from: parserNegativeInt)
                    _ = try tokenLexer.consume(from: parserDecimalPlace)
                    _ = try tokenLexer.consume(from: parserDecimalPlaceExponent)
                    _ = try tokenLexer.consume(from: parserDecimalPlaceExponentCapitalE)
                    _ = try tokenLexer.consume(from: parserDecimalPlacePositiveExponent)
                    _ = try tokenLexer.consume(from: parserDecimalPlaceNegativeExponent)
                    _ = try tokenLexer.consume(from: parserLargestPositiveValue)
                    _ = try tokenLexer.consume(from: parserLargestNegativeValue)
                }
            } catch {
                
            }
        }
    }
}
