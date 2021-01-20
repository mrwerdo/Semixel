import XCTest
@testable import ProjectSync

final class ProjectSyncTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ProjectSync().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
