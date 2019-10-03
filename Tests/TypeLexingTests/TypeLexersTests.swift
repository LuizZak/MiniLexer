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
        let lexerInt = Lexer(input: "128")
        let lexerNegativeInt = Lexer(input: "-128")
        let lexerSpaceBetweenSign = Lexer(input: "- 128")
        let lexerNotInt = Lexer(input: "a123")
        let lexerEmpty = Lexer(input: "")
        
        XCTAssertEqual(128, try Int.tokenLexer.consume(from: lexerInt))
        XCTAssertEqual(-128, try Int.tokenLexer.consume(from: lexerNegativeInt))
        XCTAssertThrowsError(try Int.tokenLexer.consume(from: lexerSpaceBetweenSign))
        XCTAssertThrowsError(try Int.tokenLexer.consume(from: lexerNotInt))
        XCTAssertThrowsError(try Int.tokenLexer.consume(from: lexerEmpty))
    }
    
    func testLexInt8() throws {
        let lexerInt = Lexer(input: "128")
        let lexerNegativeInt = Lexer(input: "-128")
        let lexerSpaceBetweenSign = Lexer(input: "- 128")
        let lexerNotInt = Lexer(input: "a123")
        let lexerEmpty = Lexer(input: "")
        
        XCTAssertThrowsError(try Int8.tokenLexer.consume(from: lexerInt))
        XCTAssertEqual(-128, try Int8.tokenLexer.consume(from: lexerNegativeInt))
        XCTAssertThrowsError(try Int8.tokenLexer.consume(from: lexerSpaceBetweenSign))
        XCTAssertThrowsError(try Int8.tokenLexer.consume(from: lexerNotInt))
        XCTAssertThrowsError(try Int8.tokenLexer.consume(from: lexerEmpty))
    }
    
    func testLexUInt8() throws {
        let lexerInt = Lexer(input: "128")
        let lexerNegativeInt = Lexer(input: "-128")
        let lexerOverflow = Lexer(input: "256")
        let lexerSpaceBetweenSign = Lexer(input: "- 128")
        let lexerNotInt = Lexer(input: "a123")
        let lexerEmpty = Lexer(input: "")
        
        XCTAssertEqual(128, try UInt8.tokenLexer.consume(from: lexerInt))
        XCTAssertThrowsError(try UInt8.tokenLexer.consume(from: lexerOverflow))
        XCTAssertThrowsError(try UInt8.tokenLexer.consume(from: lexerNegativeInt))
        XCTAssertThrowsError(try UInt8.tokenLexer.consume(from: lexerSpaceBetweenSign))
        XCTAssertThrowsError(try UInt8.tokenLexer.consume(from: lexerNotInt))
        XCTAssertThrowsError(try UInt8.tokenLexer.consume(from: lexerEmpty))
    }
    
    func testLexFloat() {
        let lexerInt = Lexer(input: "128")
        let lexerNegativeInt = Lexer(input: "-128")
        let lexerDecimalPlace = Lexer(input: "128.5")
        let lexerDecimalPlaceExponent = Lexer(input: "1.5e2")
        let lexerDecimalPlaceExponentCapitalE = Lexer(input: "1.5E2")
        let lexerDecimalPlacePositiveExponent = Lexer(input: "1.5e+2")
        let lexerDecimalPlaceNegativeExponent = Lexer(input: "1.5e-2")
        let lexerLargestPositiveValue = Lexer(input: "3.402823e+38")
        let lexerLargestNegativeValue = Lexer(input: "3.402823e-38")
        let lexerOverflow = Lexer(input: "3.402823e+39")
        let lexerSpaceBetweenSign = Lexer(input: "- 128")
        let lexerNotNumber = Lexer(input: "a123")
        let lexerEmpty = Lexer(input: "")
        
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
        let lexerInt = Lexer(input: "128")
        let lexerNegativeInt = Lexer(input: "-128")
        let lexerDecimalPlace = Lexer(input: "128.5")
        let lexerDecimalPlaceExponent = Lexer(input: "1.5e2")
        let lexerDecimalPlaceExponentCapitalE = Lexer(input: "1.5E2")
        let lexerDecimalPlacePositiveExponent = Lexer(input: "1.5e+2")
        let lexerDecimalPlaceNegativeExponent = Lexer(input: "1.5e-2")
        let lexerLargestPositiveValue = Lexer(input: "1.7976931348623157e+308")
        let lexerLargestNegativeValue = Lexer(input: "1.7976931348623157e-307")
        let lexerOverflow = Lexer(input: "1.7976931348623157e+309")
        let lexerSpaceBetweenSign = Lexer(input: "- 128")
        let lexerNotNumber = Lexer(input: "a123")
        let lexerEmpty = Lexer(input: "")
        
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
}
