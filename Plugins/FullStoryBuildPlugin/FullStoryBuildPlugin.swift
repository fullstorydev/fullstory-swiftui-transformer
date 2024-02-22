import Foundation
import PackagePlugin

@main
struct FullStoryBuildPlugin: BuildToolPlugin {

    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        guard let target = target as? any SourceModuleTarget else { return [] }
        let inputFiles = target.sourceFiles.filter({ $0.path.extension == "swift" })
        return try inputFiles.map {
            let inputFile = $0
            let inputPath = inputFile.path
            let outputName = inputPath.stem + "-copy.swift"
            let outputPath = context.pluginWorkDirectory.appending(outputName)
            return .buildCommand(
                displayName: "Generating \(outputName) from \(inputPath.lastComponent)",
                executable: try context.tool(named: "cp").path,
                arguments: [ "\(inputPath)", "\(outputPath)" ],
                inputFiles: [ inputPath, ],
                outputFiles: [ outputPath ]
            )
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension FullStoryBuildPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        guard let target = target as? any SourceModuleTarget else { return [] }
        let inputFiles = target.sourceFiles.filter({ $0.path.extension == "swift" })
        return try inputFiles.map {
            let inputFile = $0
            let inputPath = inputFile.path
            let outputName = inputPath.stem + "-copy.swift"
            let outputPath = context.pluginWorkDirectory.appending(outputName)
            return .buildCommand(
                displayName: "Generating \(outputName) from \(inputPath.lastComponent)",
                executable: try context.tool(named: "cp").path,
                arguments: [ "\(inputPath)", "\(outputPath)" ],
                inputFiles: [ inputPath, ],
                outputFiles: [ outputPath ]
            )
        }
    }
}
#endif
