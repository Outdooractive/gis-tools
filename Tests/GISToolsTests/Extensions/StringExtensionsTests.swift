import Testing
@testable import GISTools

struct StringExtensionsTests {

    /// Tests that `String.matches(_:)` correctly handles regex patterns,
    /// optional `/` delimiters, case-insensitive `/i` suffix, and
    /// non-matching inputs.
    @Test
    func matchesRegularExpression() {
        #expect("Hello World".matches("/[Hh]ello/"))
        #expect("hello world".matches("/[Hh]ello/"))
        #expect("Hello World".matches("Hello"))
        #expect("Hello World".matches("^Hello"))
        #expect("Hello World".matches("World$"))
        #expect("HELLO".matches("/hello/i"))
        #expect("HELLO".matches("/hello/") == false)
        #expect("abc123".matches("\\d+"))
        #expect("abc".matches("\\d+") == false)
    }

}
