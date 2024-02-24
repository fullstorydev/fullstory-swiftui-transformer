import Foundation

@main
struct FullStorySourceTransformer {
    static func main() throws {
        if CommandLine.arguments.count == 3 {
            var str = try String(contentsOfFile: CommandLine.arguments[1])
            // TODO: allow whitespace with newlines; preserve newlines
            str = str.replacing(#/import SwiftUI/#, with: "import SwiftUI; import FullStory")
            str = str.replacing(#/var body: some View/#, with: "var originalBody: some View")
            str = str.replacing(#/var body: some View/#, with: "var body: some View { originalBody.fsSelectable() }; var originalBody: some View")
            try str.write(toFile: CommandLine.arguments[2], atomically: true, encoding: String.Encoding.utf8)
        }
    }
}
