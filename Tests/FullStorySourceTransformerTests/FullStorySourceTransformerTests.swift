import XCTest
@testable import FullStorySourceTransformer

final class FullStorySourceTransformerTests: XCTestCase {
    func testTransform() throws {
        let example1 = """
import SwiftUI

struct MyView: View {
    var body: some View {
        Text("Hello, World!")
    }
}
"""
        let example1Expected = """
import SwiftUI; import FullStory

struct MyView: FSSelectableView, View {
    var body: some View { originalBody.fsSelectable() }; var originalBody: some View {
        Text("Hello, World!")
    }
}
"""
        let example1Transformed = FullStorySourceTransformer.transform(example1)
        XCTAssertEqual(example1Transformed, example1Expected)
    }
}
