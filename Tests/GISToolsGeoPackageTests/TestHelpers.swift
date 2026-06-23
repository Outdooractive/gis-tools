import Foundation

/// Returns the URL of a test fixture in the `TestData` directory.
func testFixture(_ name: String) -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("TestData/\(name)")
}
