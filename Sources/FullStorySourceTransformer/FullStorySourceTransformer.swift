import Foundation

@main
struct FullStorySourceTransformer {
    static func main() throws {
        NSLog("arguments: %@", CommandLine.arguments)
        if CommandLine.arguments.count == 3 {
            let str = try String(contentsOfFile: CommandLine.arguments[1])
            NSLog("file: %@", str)
        }
    }
}
