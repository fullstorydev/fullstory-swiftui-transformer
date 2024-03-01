import Foundation

@main
struct FullStorySourceTransformer {
    internal static func transform(_ input: String) -> String {
        // Swift whitespace rules:
        // https://docs.swift.org/swift-book/documentation/the-swift-programming-language/lexicalstructure/#Whitespace-and-Comments
        var str = input
        var containsSwiftUI = false;
        str = str.replacing(#/import([ \t\r\n\f\x0B]+)SwiftUI/#, with: {match in
            containsSwiftUI = true
            return "import\(match.1)SwiftUI; import FullStory"
        })
        if containsSwiftUI {
            let originalStr = str;
            var viewConformanceCount = 0;
            str = str.replacing(#/struct([ \t\r\n\f\x0B]+)([^:\s]*)([ \t\r\n\f\x0B]*):([ \t\r\n\f\x0B]*)View([ \t\r\n\f\x0B]*){/#, with: {match in
                viewConformanceCount += 1
                return "struct\(match.1)\(match.2)\(match.3):\(match.4)FSSelectableView, View\(match.5){"
            })
            var bodyCount = 0;
            str = str.replacing(#/var([ \t\r\n\f\x0B]+)body([ \t\r\n\f\x0B]*):([ \t\r\n\f\x0B]*)some([ \t\r\n\f\x0B]+)View([ \t\r\n\f\x0B]*){/#, with: {match in
                bodyCount += 1;
                return "var\(match.1)body\(match.2):\(match.3)some\(match.4)View\(match.5){ originalBody.fsSelectable() }; var originalBody: some View {"
            })
            if bodyCount != viewConformanceCount {
                NSLog("%@ instrumentation failed! Please contact FullStory support.")
                str = originalStr
            }
        } else {
            NSLog("%@ does not import SwiftUI, skipping instrumentation", CommandLine.arguments[1])
        }
        return str
    }
    static func main() throws {
        if CommandLine.arguments.count == 3 {
            var str = try String(contentsOfFile: CommandLine.arguments[1])
            str = transform(str)
            try str.write(toFile: CommandLine.arguments[2], atomically: true, encoding: String.Encoding.utf8)
        }
    }
}
