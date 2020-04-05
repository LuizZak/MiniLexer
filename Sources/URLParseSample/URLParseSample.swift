import Foundation
import MiniLexer
import TypeLexing

/**
 Subset of RFC 1738 & 3986 URL implementation
 
         foo://example.com:8042/over/there?name=ferret#nose
         \_/   \______________/\_________/ \_________/ \__/
          |           |            |            |        |
       scheme     authority       path        query   fragment
          |   _____________________|__
         / \ /                        \
         urn:example:animal:ferret:nose
 */
public struct URL: Equatable, Codable {
    public var scheme: String?
    public var user: String?
    public var password: String?
    public var host: String?
    public var port: Int?
    public var path: String?
    public var query: String?
    public var fragment: String?
    
    public init(scheme: String? = nil, user: String? = nil, password: String? = nil,
         host: String? = nil, port: Int? = nil, path: String? = nil,
         query: String? = nil, fragment: String? = nil)
    {
        self.scheme = scheme
        self.user = user
        self.password = password
        self.host = host
        self.port = port
        self.path = path
        self.query = query
        self.fragment = fragment
    }
    
    public static func ==(lhs: URL, rhs: URL) -> Bool {
        return lhs.scheme == rhs.scheme && lhs.user == rhs.user &&
            lhs.password == rhs.password && lhs.host == rhs.host &&
            lhs.port == rhs.port && lhs.path == rhs.path && lhs.query == rhs.query &&
            lhs.fragment == rhs.fragment
    }
}

public class URLParser {
    
    /// RFC 1738 & 3986 URL parser
    public static func parseURL(from string: String) -> URL? {
        func tostr<S: StringProtocol>(_ input: S?) -> String? {
            guard let input = input else {
                return nil
            }
            if let string = input as? String {
                return string
            }
            return String(input)
        }
        
        do {
            let parser = Parser(input: string)
            
            var scheme: Substring?
            var user: Substring?
            var password: Substring?
            var host: Substring?
            var port: Int?
            var path: Substring?
            var query: Substring?
            var fragment: Substring?
            
            // <scheme> := [a-z\+\-\.]+
            scheme = try parser.consumeString { parser in
                while true {
                    let peek = try parser.peek()
                    guard Parser.isLetter(peek) || peek == "+" || peek == "-" || peek == "." else {
                        if peek == ":" {
                            return
                        }
                        throw parser.unexpectedCharacterError(char: peek, "Expected Scheme")
                    }
                    
                    try parser.advance()
                }
            }
            
            // Skip ':'
            try parser.advance()
            
            // `//<user>:<password>@<host>:<port>/<url-path>`
            
            // Skip '//'
            try parser.advance(expectingCurrent: "/")
            try parser.advance(expectingCurrent: "/")
            
            // Check if we have a user:password specifier
            let hasUserPass: Bool = parser.withTemporaryIndex {
                parser.advance(until: { $0 == "@" || $0 == "/" })
                
                return parser.safeIsNextChar(equalTo: "@")
            }
            
            if hasUserPass {
                user = parser.consume(until: { $0 == "@" || $0 == ":" })
                
                if try parser.peek() == ":" { // Password
                    try parser.advance() // Skip ':'
                    password = parser.consume(until: { $0 == "@" })
                }
                
                try parser.advance() // Skip '@'
            }
            
            // Detect IPv6 address
            if try parser.peek() == "[" {
                host = parser.consume(until: { $0 == "]" })
                try parser.advance() // Skip ']'
            } else {
                host = parser.consume(until: { $0 == "/" || $0 == ":" })
            }
            
            // Detect port
            if parser.safeIsNextChar(equalTo: ":") {
                try parser.advance() // Skip ':'
                port = Int(try parser.parse(with: GrammarRule.digit+))
            }
            
            // End here, without path
            if parser.isEof() {
                return URL(scheme: tostr(scheme), user: tostr(user),
                           password: tostr(password), host: tostr(host),
                           port: port)
            }
            
            // Continue on w/ URL path
            path = parser.consume(until: { $0 == "#" || $0 == "?" })
            
            // Check query
            if parser.safeIsNextChar(equalTo: "?") {
                try parser.advance() // Skip '?'
                query = parser.consume(until: { $0 == "#" })
            }
            
            // Check fragment
            if parser.safeIsNextChar(equalTo: "#") {
                try parser.advance() // Skip '#'
                fragment = parser.consumeRemaining()
            }
            
            return URL(scheme: tostr(scheme), user: tostr(user),
                       password: tostr(password), host: tostr(host), port: port,
                       path: tostr(path), query: tostr(query),
                       fragment: tostr(fragment))
        } catch {
            return nil
        }
    }
}

// TODO: All these extensions should be internal, but leaving it public for now
// to allow testing without `@testable import` and consequently allow testing a
// release mode build.

public extension Parser {
    /// ```
    /// URI           = scheme ":" hier-part [ "?" query ] [ "#" fragment ]
    /// ```
    @inlinable
    func URI() throws -> Substring {
        return try consumeString { parser in
            try parser.scheme()
            try parser.advance(expectingCurrent: ":")
            try parser.hierPart()
            
            if parser.safeIsNextChar(equalTo: "?") {
                try parser.advance() // Skip '?'
                try parser.query()
            }
            if parser.safeIsNextChar(equalTo: "#") {
                try parser.advance() // Skip '#'
                try parser.fragment()
            }
        }
    }
    
    /// ```
    /// hier-part     = "//" authority path-abempty
    ///               / path-absolute
    ///               / path-rootless
    ///               / path-empty
    /// ```
    @inlinable
    func hierPart() throws {
        // Implementation detail: matches rules for relativePart()
        try relativePart()
    }
    
    /// ```
    /// absolute-URI  = scheme ":" hier-part [ "?" query ]
    /// ```
    @inlinable
    func absoluteURI() throws {
        try scheme()
        try advance(expectingCurrent: ":")
        try hierPart()
        
        if safeIsNextChar(equalTo: "?") {
            try advance() // Skip "?"
            try query()
        }
    }
    
    /// ```
    /// relative-ref  = relative-part [ "?" query ] [ "#" fragment ]
    /// ```
    @inlinable
    func relativeRef() throws {
        try relativePart()
        
        if safeIsNextChar(equalTo: "?") {
            try advance() // Skip '?'
            try query()
        }
        if safeIsNextChar(equalTo: "#") {
            try advance() // Skip '#'
            try fragment()
        }
    }
    
    /// ```
    /// relative-part = "//" authority path-abempty
    ///               / path-absolute
    ///               / path-noscheme
    ///               / path-empty
    /// ```
    @inlinable
    func relativePart() throws {
        try advance(expectingCurrent: "/")
        
        if safeIsNextChar(equalTo: "/") {
            try advance()
            try authority()
            try pathAbEmpty()
            return
        }
        
        try matchFirst(withEither: { parser in
            try parser.pathAbsolute()
        }, { parser in
            try parser.pathNoScheme()
        }, { parser in
            try parser.pathEmpty()
        })
    }
    
    /// ```
    /// scheme        = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
    /// ```
    @inlinable
    func scheme() throws {
        try advance(validatingCurrent: Parser.isLetter)
        
        advance(while: { Parser.isAlphanumeric($0) || $0 == "+" || $0 == "-" || $0 == "." })
    }
    
    /// ```
    /// authority     = [ userinfo "@" ] host [ ":" port ]
    /// ```
    @inlinable
    func authority() throws {
        // Try to find '@', then match user info
        if findNext("@") != nil {
            optional { parser in
                _=try parser.userinfo()
                try parser.advance(expectingCurrent: "@")
                return true
            }
        }
        
        try host()
        
        if safeIsNextChar(equalTo: ":") {
            try advance() // Skip ':'
            port()
        }
    }
    
    /// ```
    /// userinfo      = *( unreserved / pct-encoded / sub-delims / ":" )
    /// ```
    @inlinable
    func userinfo() throws {
        try expect(atLeast: 0) { parser in
            let c = try parser.peek()
            if Parser.isUnreserved(c) || Parser.isSubDelim(c) || c == ":" {
                try parser.advance()
            } else {
                try parser.pctEncoded()
            }
            
            return true
        }
    }
    
    /// ```
    /// host          = IP-literal / IPv4address / reg-name
    /// ```
    @inlinable
    func host() throws {
        if optional(using: { parser -> Bool in
            try parser.regName()
            return true
        }) {
            return
        }
    
        if optional(using: { parser -> Bool in
            try parser.ipv4Address()
            return true
        }) {
            return
        }
    
        try ipLiteral()
    }
    
    /// ```
    /// port          = *DIGIT
    /// ```
    @inlinable
    func port() {
        advance(while: Parser.isDigit)
    }
    
    /// Here, we abuse the fact we got braces to ease up parsing of the IP literals
    /// and don't break into more granular rules for IPvFuture or IPv6address.
    ///
    /// ```
    /// IP-literal    = "[" ( IPv6address / IPvFuture  ) "]"
    ///
    /// IPvFuture     = "v" 1*HEXDIG "." 1*( unreserved / sub-delims / ":" )
    /// IPv6address   =                            6( h16 ":" ) ls32
    ///               /                       "::" 5( h16 ":" ) ls32
    ///               / [               h16 ] "::" 4( h16 ":" ) ls32
    ///               / [ *1( h16 ":" ) h16 ] "::" 3( h16 ":" ) ls32
    ///               / [ *2( h16 ":" ) h16 ] "::" 2( h16 ":" ) ls32
    ///               / [ *3( h16 ":" ) h16 ] "::"    h16 ":"   ls32
    ///               / [ *4( h16 ":" ) h16 ] "::"              ls32
    ///               / [ *5( h16 ":" ) h16 ] "::"              h16
    ///               / [ *6( h16 ":" ) h16 ] "::"
    /// ```
    @inlinable
    func ipLiteral() throws {
        try advance(expectingCurrent: "[")
        
        advance(while: { $0 != "]" })
        
        try advance(expectingCurrent: "]")
    }
    
    /// ```
    /// h16           = 1*4HEXDIG
    /// ```
    @inlinable
    func h16() throws {
        try expect(between: 1, max: 4) { parser -> Bool in
            if !parser.safeNextCharPasses(with: Parser.isHexdig) {
                return false
            }
            
            try parser.advance()
            return true
        }
    }
    
    /// ```
    /// ls32          = ( h16 ":" h16 ) / IPv4address
    /// ```
    @inlinable
    func ls32() throws {
        do {
            try ipv4Address()
        } catch {
            try h16()
            try advance(expectingCurrent: ":")
            try h16()
        }
    }
    
    /// ```
    /// IPv4address   = dec-octet "." dec-octet "." dec-octet "." dec-octet
    /// ```
    @inlinable
    func ipv4Address() throws {
        for _ in 0..<3 {
            try decOctet()
            try advance(expectingCurrent: ".")
        }
        
        try decOctet()
    }
    
    /// ```
    /// dec-octet     = DIGIT                 ; 0-9
    ///               / %x31-39 DIGIT         ; 10-99
    ///               / "1" 2DIGIT            ; 100-199
    ///               / "2" %x30-34 DIGIT     ; 200-249
    ///               / "25" %x30-35          ; 250-255
    /// ```
    @inlinable
    func decOctet() throws {
        let i = try parse(with: Int.tokenLexer)
        if i < 0 || i > 255 {
            throw ParserError.miscellaneous("Expected integer between 0 and 255, found \(i) instead.")
        }
    }
    
    /// ```
    /// reg-name      = *( unreserved / pct-encoded / sub-delims )
    /// ```
    @inlinable
    func regName() throws {
        try expect(atLeast: 0) { (parser) -> Bool in
            if parser.safeNextCharPasses(with: Parser.isUnreserved) ||
                parser.safeNextCharPasses(with: Parser.isSubDelim) {
                try parser.advance()
            } else {
                // Try pct-encoded
                try parser.pctEncoded()
            }
            
            return true
        }
    }
    
    
    /// ```
    /// path          = path-abempty    ; begins with "/" or is empty
    ///               / path-absolute   ; begins with "/" but not "//"
    ///               / path-noscheme   ; begins with a non-colon segment
    ///               / path-rootless   ; begins with a segment
    ///               / path-empty      ; zero characters
    /// ```
    @inlinable
    func path() throws {
        return try matchFirst(withEither: { parser in
            try parser.pathNoScheme()
        }, { parser in
            try parser.pathRootless()
        }, { parser in
            try parser.pathAbsolute()
        }, { parser in
            try parser.pathAbEmpty()
        }, { parser in
            try parser.pathEmpty()
        })
    }
    
    /// ```
    /// path-abempty  = *( "/" segment )
    /// ```
    @inlinable
    func pathAbEmpty() throws {
        try expect(atLeast: 0, of: { (parser) -> Bool in
            try parser.advance(expectingCurrent: "/")
            try segment()
            return true
        })
    }
    
    /// ```
    /// path-absolute = "/" [ segment-nz *( "/" segment ) ]
    /// ```
    @inlinable
    func pathAbsolute() throws {
        try advance(expectingCurrent: "/")
        
        optional { parser -> Bool in
            try parser.segmentNz()
            try expect(atLeast: 0, of: { (parser) -> Bool in
                try parser.advance(expectingCurrent: "/")
                try parser.segment()
                return true
            })
            
            return true
        }
    }
    
    /// ```
    /// path-noscheme = segment-nz-nc *( "/" segment )
    /// ```
    @inlinable
    func pathNoScheme() throws {
        try segmentNzNc()
        try expect(atLeast: 0, of: { (parser) -> Bool in
            try parser.advance(expectingCurrent: "/")
            try parser.segment()
            return true
        })
    }
    
    /// ```
    /// path-rootless = segment-nz *( "/" segment )
    /// ```
    @inlinable
    func pathRootless() throws {
        try segmentNz()
        try expect(atLeast: 0, of: { (parser) -> Bool in
            try parser.advance(expectingCurrent: "/")
            try parser.segment()
            return true
        })
    }
    
    /// ```
    /// path-empty    = 0<pchar>
    /// ```
    @inlinable
    func pathEmpty() throws {
        do {
            try pchar()
            
            // Should not have parsed!
            throw ParserError.genericParseError
        } catch {
            // Success!
        }
    }
    
    /// ```
    /// segment       = *pchar
    /// ```
    @inlinable
    func segment() throws {
        try expect(atLeast: 0, of: { parser in
            try parser.pchar()
            return true
        })
    }
    
    /// ```
    /// segment-nz    = 1*pchar
    /// ```
    @inlinable
    func segmentNz() throws {
        try expect(atLeast: 1, of: { parser in
            try parser.pchar()
            return true
        })
    }
    
    /// ```
    /// segment-nz-nc = 1*( unreserved / pct-encoded / sub-delims / "@" )
    /// ; non-zero-length segment without any colon ":"
    /// ```
    @inlinable
    func segmentNzNc() throws {
        try expect(atLeast: 1, of: { parser in
            let p = try parser.consumeString { try $0.pchar() }
            return p != ":"
        })
    }
    
    /// ```
    /// query         = *( pchar / "/" / "?" )
    /// ```
    @inlinable
    func query() throws {
        // !Implementation detail: Matches 'fragment' rule.
        try fragment()
    }
    
    /// ```
    /// fragment      = *( pchar / "/" / "?" )
    /// ```
    @inlinable
    func fragment() throws {
        try expect(atLeast: 0) { (parser) -> Bool in
            let p = try parser.peek()
            if p == "/" || p == "?" {
                try parser.advance()
            } else {
                // Try to consume pchar
                try parser.pchar()
            }
            
            return true
        }
    }
    
    /// ```
    /// pct-encoded   = "%" HEXDIG HEXDIG
    /// ```
    @inlinable
    func pctEncoded() throws {
        if !safeIsNextChar(equalTo: "%") {
            throw ParserError.genericParseError
        }
        
        try advance() // Skip '%'
        try advance(validatingCurrent: Parser.isHexdig)
        try advance(validatingCurrent: Parser.isHexdig)
    }
    
    /// ```
    /// pchar =
    ///     unreserved / pct-encoded / sub-delims / ":" / "@"
    /// ```
    @inlinable
    func pchar() throws {
        let p = try peek()
        if Parser.isUnreserved(p) || Parser.isSubDelim(p) || p == ":" || p == "@" {
            try advance()
        } else {
            try pctEncoded()
        }
    }
}

/// URI syntax atoms
public extension Parser {
    
    /// ```
    /// unreserved = ALPHA / DIGIT / "-" / "." / "_" / "~"
    /// ```
    @inlinable
    static func isUnreserved(_ c: Atom) -> Bool {
        return Parser.isAlphanumeric(c) || c == "-" || c == "." || c == "_" || c == "-"
    }
    
    /// ```
    /// reserved = gen-delims / sub-delims
    /// ```
    @inlinable
    static func isReserved(_ c: Atom) -> Bool {
        return isGenDelim(c) || isSubDelim(c)
    }
    
    /// ```
    /// gen-delims = ":" / "/" / "?" / "#" / "[" / "]" / "@"
    /// ```
    @inlinable
    static func isGenDelim(_ c: Atom) -> Bool {
        return
            c == ":" || c == "/" || c == "?" ||
                c == "#" || c == "[" || c == "]" || c == "@"
    }
    
    /// ```
    /// sub-delims = "!" / "$" / "&" / "'" / "(" / ")"
    ///            / "*" / "+" / "," / ";" / "="
    /// ```
    @inlinable
    static func isSubDelim(_ c: Atom) -> Bool {
        return
            c == "!" || c == "$" || c == "&" || c == "'" || c == "(" ||
                c == ")" || c == "*" || c == "+" || c == "," || c == ";" || c == "="
    }
}

/// RFC Core ABNF rules
public extension Parser {
    
    /// ```
    /// HEXDIG         =  DIGIT / "A" / "B" / "C" / "D" / "E" / "F"
    /// ```
    @inlinable
    static func isHexdig(_ c: Atom) -> Bool {
        return Parser.isDigit(c) || (c >= "a" && c <= "f") || (c >= "A" && c <= "F")
    }
}

/*
   URI           = scheme ":" hier-part [ "?" query ] [ "#" fragment ]

   hier-part     = "//" authority path-abempty
                 / path-absolute
                 / path-rootless
                 / path-empty

   URI-reference = URI / relative-ref

   absolute-URI  = scheme ":" hier-part [ "?" query ]

   relative-ref  = relative-part [ "?" query ] [ "#" fragment ]

   relative-part = "//" authority path-abempty
                 / path-absolute
                 / path-noscheme
                 / path-empty

   scheme        = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )

   authority     = [ userinfo "@" ] host [ ":" port ]
   userinfo      = *( unreserved / pct-encoded / sub-delims / ":" )
   host          = IP-literal / IPv4address / reg-name
   port          = *DIGIT

   IP-literal    = "[" ( IPv6address / IPvFuture  ) "]"

   IPvFuture     = "v" 1*HEXDIG "." 1*( unreserved / sub-delims / ":" )

   IPv6address   =                            6( h16 ":" ) ls32
                 /                       "::" 5( h16 ":" ) ls32
                 / [               h16 ] "::" 4( h16 ":" ) ls32
                 / [ *1( h16 ":" ) h16 ] "::" 3( h16 ":" ) ls32
                 / [ *2( h16 ":" ) h16 ] "::" 2( h16 ":" ) ls32
                 / [ *3( h16 ":" ) h16 ] "::"    h16 ":"   ls32
                 / [ *4( h16 ":" ) h16 ] "::"              ls32
                 / [ *5( h16 ":" ) h16 ] "::"              h16
                 / [ *6( h16 ":" ) h16 ] "::"

   h16           = 1*4HEXDIG
   ls32          = ( h16 ":" h16 ) / IPv4address
   IPv4address   = dec-octet "." dec-octet "." dec-octet "." dec-octet
 
   dec-octet     = DIGIT                 ; 0-9
                 / %x31-39 DIGIT         ; 10-99
                 / "1" 2DIGIT            ; 100-199
                 / "2" %x30-34 DIGIT     ; 200-249
                 / "25" %x30-35          ; 250-255

   reg-name      = *( unreserved / pct-encoded / sub-delims )

   path          = path-abempty    ; begins with "/" or is empty
                 / path-absolute   ; begins with "/" but not "//"
                 / path-noscheme   ; begins with a non-colon segment
                 / path-rootless   ; begins with a segment
                 / path-empty      ; zero characters

   path-abempty  = *( "/" segment )
   path-absolute = "/" [ segment-nz *( "/" segment ) ]
   path-noscheme = segment-nz-nc *( "/" segment )
   path-rootless = segment-nz *( "/" segment )
   path-empty    = 0<pchar>

   segment       = *pchar
   segment-nz    = 1*pchar
   segment-nz-nc = 1*( unreserved / pct-encoded / sub-delims / "@" )
                 ; non-zero-length segment without any colon ":"

   pchar         = unreserved / pct-encoded / sub-delims / ":" / "@"

   query         = *( pchar / "/" / "?" )

   fragment      = *( pchar / "/" / "?" )

   pct-encoded   = "%" HEXDIG HEXDIG

   unreserved    = ALPHA / DIGIT / "-" / "." / "_" / "~"
   reserved      = gen-delims / sub-delims
   gen-delims    = ":" / "/" / "?" / "#" / "[" / "]" / "@"
   sub-delims    = "!" / "$" / "&" / "'" / "(" / ")"
                 / "*" / "+" / "," / ";" / "="
 */
