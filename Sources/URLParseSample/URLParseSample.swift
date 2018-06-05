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
            let lexer = Lexer(input: string)
            
            var scheme: Substring?
            var user: Substring?
            var password: Substring?
            var host: Substring?
            var port: Int?
            var path: Substring?
            var query: Substring?
            var fragment: Substring?
            
            // <scheme> := [a-z\+\-\.]+
            scheme = try lexer.consumeString { lexer in
                while true {
                    let peek = try lexer.peek()
                    guard Lexer.isLetter(peek) || peek == "+" || peek == "-" || peek == "." else {
                        if peek == ":" {
                            return
                        }
                        throw lexer.unexpectedCharacterError(char: peek, "Expected Scheme")
                    }
                    
                    try lexer.advance()
                }
            }
            
            // Skip ':'
            try lexer.advance()
            
            // `//<user>:<password>@<host>:<port>/<url-path>`
            
            // Skip '//'
            try lexer.advance(expectingCurrent: "/")
            try lexer.advance(expectingCurrent: "/")
            
            // Check if we have a user:password specifier
            let hasUserPass: Bool = lexer.withTemporaryIndex {
                lexer.advance(until: { $0 == "@" || $0 == "/" })
                
                return lexer.safeIsNextChar(equalTo: "@")
            }
            
            if hasUserPass {
                user = lexer.consume(until: { $0 == "@" || $0 == ":" })
                
                if try lexer.peek() == ":" { // Password
                    try lexer.advance() // Skip ':'
                    password = lexer.consume(until: { $0 == "@" })
                }
                
                try lexer.advance() // Skip '@'
            }
            
            // Detect IPv6 address
            if try lexer.peek() == "[" {
                host = lexer.consume(until: { $0 == "]" })
                try lexer.advance() // Skip ']'
            } else {
                host = lexer.consume(until: { $0 == "/" || $0 == ":" })
            }
            
            // Detect port
            if lexer.safeIsNextChar(equalTo: ":") {
                try lexer.advance() // Skip ':'
                port = Int(try lexer.parse(with: GrammarRule.digit+))
            }
            
            // End here, without path
            if lexer.isEof() {
                return URL(scheme: tostr(scheme), user: tostr(user),
                           password: tostr(password), host: tostr(host),
                           port: port)
            }
            
            // Continue on w/ URL path
            path = lexer.consume(until: { $0 == "#" || $0 == "?" })
            
            // Check query
            if lexer.safeIsNextChar(equalTo: "?") {
                try lexer.advance() // Skip '?'
                query = lexer.consume(until: { $0 == "#" })
            }
            
            // Check fragment
            if lexer.safeIsNextChar(equalTo: "#") {
                try lexer.advance() // Skip '#'
                fragment = lexer.consumeRemaining()
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

public extension Lexer {
    /// ```
    /// URI           = scheme ":" hier-part [ "?" query ] [ "#" fragment ]
    /// ```
    @inlinable
    public func URI() throws -> Substring {
        return try consumeString { lexer in
            try lexer.scheme()
            try lexer.advance(expectingCurrent: ":")
            try lexer.hierPart()
            
            if lexer.safeIsNextChar(equalTo: "?") {
                try lexer.advance() // Skip '?'
                try lexer.query()
            }
            if lexer.safeIsNextChar(equalTo: "#") {
                try lexer.advance() // Skip '#'
                try lexer.fragment()
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
    public func hierPart() throws {
        // Implementation detail: matches rules for relativePart()
        try relativePart()
    }
    
    /// ```
    /// absolute-URI  = scheme ":" hier-part [ "?" query ]
    /// ```
    @inlinable
    public func absoluteURI() throws {
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
    public func relativeRef() throws {
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
    public func relativePart() throws {
        try advance(expectingCurrent: "/")
        
        if safeIsNextChar(equalTo: "/") {
            try advance()
            try authority()
            try pathAbEmpty()
            return
        }
        
        try matchFirst(withEither: { lexer in
            try lexer.pathAbsolute()
        }, { lexer in
            try lexer.pathNoScheme()
        }, { lexer in
            try lexer.pathEmpty()
        })
    }
    
    /// ```
    /// scheme        = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
    /// ```
    @inlinable
    public func scheme() throws {
        try advance(validatingCurrent: Lexer.isLetter)
        
        advance(while: { Lexer.isAlphanumeric($0) || $0 == "+" || $0 == "-" || $0 == "." })
    }
    
    /// ```
    /// authority     = [ userinfo "@" ] host [ ":" port ]
    /// ```
    @inlinable
    public func authority() throws {
        // Try to find '@', then match user info
        if findNext("@") != nil {
            optional { lexer in
                _=try lexer.userinfo()
                try lexer.advance(expectingCurrent: "@")
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
    public func userinfo() throws {
        try expect(atLeast: 0) { lexer in
            let c = try lexer.peek()
            if Lexer.isUnreserved(c) || Lexer.isSubDelim(c) || c == ":" {
                try lexer.advance()
            } else {
                try lexer.pctEncoded()
            }
            
            return true
        }
    }
    
    /// ```
    /// host          = IP-literal / IPv4address / reg-name
    /// ```
    @inlinable
    public func host() throws {
        if optional(using: { lexer -> Bool in
            try lexer.regName()
            return true
        }) {
            return
        }
    
        if optional(using: { lexer -> Bool in
            try lexer.ipv4Address()
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
    public func port() {
        advance(while: Lexer.isDigit)
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
    public func ipLiteral() throws {
        try advance(expectingCurrent: "[")
        
        advance(while: { $0 != "]" })
        
        try advance(expectingCurrent: "]")
    }
    
    /// ```
    /// h16           = 1*4HEXDIG
    /// ```
    @inlinable
    public func h16() throws {
        try expect(between: 1, max: 4) { lexer -> Bool in
            if !lexer.safeNextCharPasses(with: Lexer.isHexdig) {
                return false
            }
            
            try lexer.advance()
            return true
        }
    }
    
    /// ```
    /// ls32          = ( h16 ":" h16 ) / IPv4address
    /// ```
    @inlinable
    public func ls32() throws {
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
    public func ipv4Address() throws {
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
    public func decOctet() throws {
        let i = try parse(with: Int.tokenLexer)
        if i < 0 || i > 255 {
            throw LexerError.miscellaneous("Expected integer between 0 and 255, found \(i) instead.")
        }
    }
    
    /// ```
    /// reg-name      = *( unreserved / pct-encoded / sub-delims )
    /// ```
    @inlinable
    public func regName() throws {
        try expect(atLeast: 0) { (lexer) -> Bool in
            if lexer.safeNextCharPasses(with: Lexer.isUnreserved) ||
                lexer.safeNextCharPasses(with: Lexer.isSubDelim) {
                try lexer.advance()
            } else {
                // Try pct-encoded
                try lexer.pctEncoded()
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
    public func path() throws {
        return try matchFirst(withEither: { lexer in
            try lexer.pathNoScheme()
        }, { lexer in
            try lexer.pathRootless()
        }, { lexer in
            try lexer.pathAbsolute()
        }, { lexer in
            try lexer.pathAbEmpty()
        }, { lexer in
            try lexer.pathEmpty()
        })
    }
    
    /// ```
    /// path-abempty  = *( "/" segment )
    /// ```
    @inlinable
    public func pathAbEmpty() throws {
        try expect(atLeast: 0, of: { (lexer) -> Bool in
            try lexer.advance(expectingCurrent: "/")
            try segment()
            return true
        })
    }
    
    /// ```
    /// path-absolute = "/" [ segment-nz *( "/" segment ) ]
    /// ```
    @inlinable
    public func pathAbsolute() throws {
        try advance(expectingCurrent: "/")
        
        optional { lexer -> Bool in
            try lexer.segmentNz()
            try expect(atLeast: 0, of: { (lexer) -> Bool in
                try lexer.advance(expectingCurrent: "/")
                try lexer.segment()
                return true
            })
            
            return true
        }
    }
    
    /// ```
    /// path-noscheme = segment-nz-nc *( "/" segment )
    /// ```
    @inlinable
    public func pathNoScheme() throws {
        try segmentNzNc()
        try expect(atLeast: 0, of: { (lexer) -> Bool in
            try lexer.advance(expectingCurrent: "/")
            try lexer.segment()
            return true
        })
    }
    
    /// ```
    /// path-rootless = segment-nz *( "/" segment )
    /// ```
    @inlinable
    public func pathRootless() throws {
        try segmentNz()
        try expect(atLeast: 0, of: { (lexer) -> Bool in
            try lexer.advance(expectingCurrent: "/")
            try lexer.segment()
            return true
        })
    }
    
    /// ```
    /// path-empty    = 0<pchar>
    /// ```
    @inlinable
    public func pathEmpty() throws {
        do {
            try pchar()
            
            // Should not have parsed!
            throw LexerError.genericParseError
        } catch {
            // Success!
        }
    }
    
    /// ```
    /// segment       = *pchar
    /// ```
    @inlinable
    public func segment() throws {
        try expect(atLeast: 0, of: { lexer in
            try lexer.pchar()
            return true
        })
    }
    
    /// ```
    /// segment-nz    = 1*pchar
    /// ```
    @inlinable
    public func segmentNz() throws {
        try expect(atLeast: 1, of: { lexer in
            try lexer.pchar()
            return true
        })
    }
    
    /// ```
    /// segment-nz-nc = 1*( unreserved / pct-encoded / sub-delims / "@" )
    /// ; non-zero-length segment without any colon ":"
    /// ```
    @inlinable
    public func segmentNzNc() throws {
        try expect(atLeast: 1, of: { lexer in
            let p = try lexer.consumeString { try $0.pchar() }
            return p != ":"
        })
    }
    
    /// ```
    /// query         = *( pchar / "/" / "?" )
    /// ```
    @inlinable
    public func query() throws {
        // !Implementation detail: Matches 'fragment' rule.
        try fragment()
    }
    
    /// ```
    /// fragment      = *( pchar / "/" / "?" )
    /// ```
    @inlinable
    public func fragment() throws {
        try expect(atLeast: 0) { (lexer) -> Bool in
            let p = try lexer.peek()
            if p == "/" || p == "?" {
                try lexer.advance()
            } else {
                // Try to consume pchar
                try lexer.pchar()
            }
            
            return true
        }
    }
    
    /// ```
    /// pct-encoded   = "%" HEXDIG HEXDIG
    /// ```
    @inlinable
    public func pctEncoded() throws {
        if !safeIsNextChar(equalTo: "%") {
            throw LexerError.genericParseError
        }
        
        try advance() // Skip '%'
        try advance(validatingCurrent: Lexer.isHexdig)
        try advance(validatingCurrent: Lexer.isHexdig)
    }
    
    /// ```
    /// pchar =
    ///     unreserved / pct-encoded / sub-delims / ":" / "@"
    /// ```
    @inlinable
    public func pchar() throws {
        let p = try peek()
        if Lexer.isUnreserved(p) || Lexer.isSubDelim(p) || p == ":" || p == "@" {
            try advance()
        } else {
            try pctEncoded()
        }
    }
}

/// URI syntax atoms
public extension Lexer {
    
    /// ```
    /// unreserved = ALPHA / DIGIT / "-" / "." / "_" / "~"
    /// ```
    @inlinable
    public static func isUnreserved(_ c: Atom) -> Bool {
        return Lexer.isAlphanumeric(c) || c == "-" || c == "." || c == "_" || c == "-"
    }
    
    /// ```
    /// reserved = gen-delims / sub-delims
    /// ```
    @inlinable
    public static func isReserved(_ c: Atom) -> Bool {
        return isGenDelim(c) || isSubDelim(c)
    }
    
    /// ```
    /// gen-delims = ":" / "/" / "?" / "#" / "[" / "]" / "@"
    /// ```
    @inlinable
    public static func isGenDelim(_ c: Atom) -> Bool {
        return
            c == ":" || c == "/" || c == "?" ||
                c == "#" || c == "[" || c == "]" || c == "@"
    }
    
    /// ```
    /// sub-delims = "!" / "$" / "&" / "'" / "(" / ")"
    ///            / "*" / "+" / "," / ";" / "="
    /// ```
    @inlinable
    public static func isSubDelim(_ c: Atom) -> Bool {
        return
            c == "!" || c == "$" || c == "&" || c == "'" || c == "(" ||
                c == ")" || c == "*" || c == "+" || c == "," || c == ";" || c == "="
    }
}

/// RFC Core ABNF rules
public extension Lexer {
    
    /// ```
    /// HEXDIG         =  DIGIT / "A" / "B" / "C" / "D" / "E" / "F"
    /// ```
    @inlinable
    public static func isHexdig(_ c: Atom) -> Bool {
        return Lexer.isDigit(c) || (c >= "a" && c <= "f") || (c >= "A" && c <= "F")
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
