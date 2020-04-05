## MiniLexer

[![Build Status](https://dev.azure.com/luiz-fs/MiniLexer/_apis/build/status/LuizZak.MiniLexer?branchName=master)](https://dev.azure.com/luiz-fs/MiniLexer/_build/latest?definitionId=2&branchName=master)

A teeny-tiny-weeny parser-lexer written in Swift available as a Swift Package.  
Should be present in any programmer-who-likes-to-write-quick-script's toolbelt.

Sample usage:

```swift
let text = "123 test"
let parser = Lexer(input: text)

do {
    let oneTwoThree = try parser.parseInt()
    parser.skipWhitespace()
    let test = try parser.nextIdent()
    
    print("\(oneTwoThree) \(test)")
} catch {
    print("Oopsie! Error: \(error)")
}
```

There's also a sample URL-parsing example under Sources/URLParseSample, with tests over at Tests/URLParseSampleTests.
