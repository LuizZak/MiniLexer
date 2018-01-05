## MiniLexer

A tiny-teeny-weeny lexer written in Swift available as a Swift Package.

Sample usage:

```swift
let text = "123 test"
let lexer = Lexer(input: text)

do {
    let oneTwoThree = try lexer.parseInt()
    let test = try lexer.nextIdent()
    
    print("\(oneTwoThree) \(test)")
} catch {
    print("Oopsie! Error: \(error)")
}
```