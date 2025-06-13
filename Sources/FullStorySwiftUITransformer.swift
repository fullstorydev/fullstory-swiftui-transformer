import Foundation
import SwiftSyntax
import SwiftParser
import ArgumentParser

// Without this, get: Instance method 'visit' requires that 'ClosureExprSyntax' conform to 'SyntaxChildChoices'
// Note: @retroactive keyword suppresses warning, but invalid on Swift used in CI
extension ClosureExprSyntax : SyntaxChildChoices {

}

class ImportFinder: SyntaxVisitor {
    public var importSwiftUI : Int? = nil
    public var importFullstory : Bool = false
    override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.path.trimmedDescription == "SwiftUI" {
            importSwiftUI = node.positionAfterSkippingLeadingTrivia.utf8Offset
        }
        else if node.path.trimmedDescription == "FullStory" {
            importFullstory = true
        }
        return .visitChildren
    }
}

// idea: identify the locations of the struct declarations and modify them using simple String insert(contentsOf:at:)
class ViewModifierFinder: SyntaxVisitor {
    public var bodyAndConformanceLocations : [(body: Int, conformance: Int, bodyType: String)] = []
    override func visit(_ structDecl: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let inheritanceClause = structDecl.inheritanceClause,
              inheritanceClause.inheritedTypes.contains(where: { type in
                  type.type.trimmedDescription == "View" || type.type.trimmedDescription == "SwiftUI.View"
              }) == true else {
            return .visitChildren
        }
        // Only dealing with View implementations which must contain a var body
        // Views must be a struct declaration with the following syntax structure:
        // StructDecl -> MemberBlock -> MemberBlockItemList -> MemberBlockItem -> VariableDecl
        for item in structDecl.memberBlock.members {
            if let node = item.decl.as(VariableDeclSyntax.self) {
                // Only process body declarations with an accessor block, since we will be substituting in a new accessor block (computed property)
                guard let firstBinding = node.bindings.first,
                      let accessorBlock = firstBinding.accessorBlock,
                      let identifier = firstBinding.pattern.as(IdentifierPatternSyntax.self),
                      identifier.identifier.text == "body" else {
                    continue
                }

                // Only one member can be declared with the name "body", so at this point we don't need to
                // continue iterating over struct members to look for a "body"

                // The binding type doesn't have to be View - it can be any type that conforms to View
                // The type must be var body : some View if it has an accessor block, but for non-closures,
                // Swift even allows let body = Text("Hello, World") or
                // let body : some View = Text("Hello, World").shadow(radius: 5) (but it can't/won't infer the type in that case)
                // It won't allow let body : some View { ... } ('let' declarations cannot be computed properties)
                // However, because of where we write the transform, we require the type be some View.
                // We could alter the transform a bit to allow supporting any "var body" declaration,
                // but Swift does allow "let body" for non-closures.
                // Otherwise, we need to change declarations around - either change let to var or change body to originalBody - simple insertion of tokens won't work, and the simple removal directions no longer work.
                guard let typeAnnotation = firstBinding.typeAnnotation,
                      typeAnnotation.type.trimmedDescription.hasPrefix("some") &&
                        typeAnnotation.type.trimmedDescription.hasSuffix("View") else {
                    print("Skipping transformation of \(structDecl.name.trimmedDescription) - body must be declared as var body : some View")
                    return .visitChildren
                }

                bodyAndConformanceLocations.append((
                    body: accessorBlock.leftBrace.endPositionBeforeTrailingTrivia.utf8Offset,
                    conformance: inheritanceClause.colon.endPositionBeforeTrailingTrivia.utf8Offset,
                    bodyType: typeAnnotation.type.trimmedDescription
                ))
                return .visitChildren
            }
        }
        return .visitChildren
    }
}

class PackageDependenciesFinder: SyntaxVisitor {
    public var failedReason: String? = nil
    public var forceSkip: Bool = false
    public var foundDependencies : Bool = false
    public var targetsLocation : Int? = nil
    public var inserts: [(String, Int)] = []
    override func visit(_ functionCall: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if failedReason != nil || forceSkip {
            return .skipChildren
        }
        if functionCall.calledExpression.trimmedDescription == "Package" || functionCall.calledExpression.trimmedDescription == "PackageDescription.Package" {
            var isIosDependency: Bool = false
            for argument in functionCall.arguments {
                switch argument.label?.trimmedDescription {
                case "platforms":
                    if argument.expression.description.contains(".iOS") {
                        isIosDependency = true
                    }
                case "dependencies":
                    foundDependencies = true
                    if let arrayExpr = argument.expression.as(ArrayExprSyntax.self) {
                        inserts.append(("/*Fullstory_XFORM_start*/.package(url: \"https://github.com/fullstorydev/fullstory-swift-package-ios\", \"1.0.0\"..<\"2.0.0\"),/*Fullstory_XFORM_end*/", arrayExpr.leftSquare.endPositionBeforeTrailingTrivia.utf8Offset))
                    } else {
                        inserts.append(("/*Fullstory_XFORM_start*/(/*Fullstory_XFORM_end*/", argument.expression.positionAfterSkippingLeadingTrivia.utf8Offset))
                        inserts.append(("/*Fullstory_XFORM_start*/+ [.package(url: \"https://github.com/fullstorydev/fullstory-swift-package-ios\", \"1.0.0\"..<\"2.0.0\")])/*Fullstory_XFORM_end*/", argument.expression.endPositionBeforeTrailingTrivia.utf8Offset))
                    }
                case "targets":
                    // If dependencies doesn't exist, we insert dependency here
                    targetsLocation = argument.positionAfterSkippingLeadingTrivia.utf8Offset
                    if let arrayExpr = argument.expression.as(ArrayExprSyntax.self) {
                        for target in arrayExpr.elements {
                            if let targetConstructor = target.expression.as(FunctionCallExprSyntax.self) {
                                // In practice, "dependencies" is always the second argument after name
                                if !targetConstructor.calledExpression.trimmedDescription.lowercased().contains("target") {
                                    // Skip targets not named "target", e.g. "plugin" which doesn't follow the pattern
                                    continue;
                                }
                                var nameLocation: Int? = nil
                                var dependenciesLocation: Int? = nil
                                var dependenciesPreLocation: Int? = nil
                                var dependenciesPostLocation: Int? = nil
                                for (offset, argument) in targetConstructor.arguments.enumerated() {
                                    switch argument.label?.trimmedDescription {
                                    case "name":
                                        if offset != 0 {
                                            failedReason = "Unknown argument order (offset \(offset)) for name in Package.swift target: \(targetConstructor.description)"
                                            return .skipChildren
                                        }
                                        if argument.expression.trimmedDescription == "\"FullStory\"" {
                                            print("Skipping transform of FullStory Package.swift")
                                            forceSkip = true
                                            return .skipChildren
                                        }
                                        nameLocation = argument.expression.endPositionBeforeTrailingTrivia.utf8Offset
                                    case "dependencies":
                                        if offset != 1 {
                                            failedReason = "Unknown argument order (offset \(offset)) for dependencies in Package.swift target: \(targetConstructor.description)"
                                            return .skipChildren
                                        }
                                        if let arrayExpr = argument.expression.as(ArrayExprSyntax.self) {
                                            dependenciesLocation = arrayExpr.leftSquare.endPositionBeforeTrailingTrivia.utf8Offset
                                        } else {
                                            dependenciesPreLocation = argument.expression.positionAfterSkippingLeadingTrivia.utf8Offset
                                            dependenciesPostLocation = argument.expression.endPositionBeforeTrailingTrivia.utf8Offset
                                        }
                                    default: // Required because switches must be exhaustive
                                        // this breaks the switch block, not the loop
                                        // See https://docs.swift.org/swift-book/documentation/the-swift-programming-language/statements/#Switch-Statement
                                        break
                                    }
                                }
                                if let dependenciesPreLocation = dependenciesPreLocation, let dependenciesPostLocation = dependenciesPostLocation {
                                    inserts.append(("/*Fullstory_XFORM_start*/(/*Fullstory_XFORM_end*/",  dependenciesPreLocation))
                                    inserts.append(("/*Fullstory_XFORM_start*/+ [.product(name: \"FullStory\", package: \"fullstory-swift-package-ios\")])/*Fullstory_XFORM_end*/",  dependenciesPostLocation))
                                } else if let dependenciesLocation = dependenciesLocation {
                                    inserts.append(("/*Fullstory_XFORM_start*/.product(name: \"FullStory\", package: \"fullstory-swift-package-ios\"),/*Fullstory_XFORM_end*/",  dependenciesLocation))
                                } else if let nameLocation = nameLocation {
                                    inserts.append(("/*Fullstory_XFORM_start*/,dependencies: [.product(name: \"FullStory\", package: \"fullstory-swift-package-ios\")]/*Fullstory_XFORM_end*/", nameLocation))
                                }
                            } else {
                                // Don't know what to do for an element that isn't a function call :(
                                failedReason = "Couldn't parse Package.swift targets expression at byte position \(functionCall.positionAfterSkippingLeadingTrivia.utf8Offset) syntax: \(target.expression.description)"
                                return .skipChildren
                            }
                        }
                    } else {
                        // we can't evaluate an arbitrary expression to insert our package dependency
                        failedReason = "Couldn't parse Package.swift targets expression at byte position \(functionCall.positionAfterSkippingLeadingTrivia.utf8Offset) syntax: \(argument.expression.description)"
                        return .skipChildren
                    }
                default: // Required because switches must be exhaustive
                    // this breaks the switch block, not the loop
                    // See https://docs.swift.org/swift-book/documentation/the-swift-programming-language/statements/#Switch-Statement
                    break
                }
            }
            if !isIosDependency || targetsLocation == nil {
                // No iOS dependency or no targets - no need to transform
                foundDependencies = false
                return .skipChildren
            } else {
                if !foundDependencies {
                    // checked that targetsLocation != nil above
                    inserts.append(("/*Fullstory_XFORM_start*/dependencies: [.package(url: \"https://github.com/fullstorydev/fullstory-swift-package-ios\", \"1.0.0\"..<\"2.0.0\")],/*Fullstory_XFORM_end*/", targetsLocation!))
                }
            }
            // Doesn't have a dependencies argument - we need to add one in the appropriate place (because argument labels are ordered)
        }
        return .visitChildren
    }
}

@main
struct FullStorySwiftUITransformer: ParsableCommand {
    struct TransformError : LocalizedError, Equatable {
        let message: String
        var errorDescription: String? {
            message
        }
        init(_ message: String) {
            self.message = message
        }
    }

    internal static func transform(_ originalSource: String, file: String = "File", transformPackageSwift: Bool = true, verbose: Bool = false) throws -> String {

        if originalSource.contains("//Fullstory_XFORM_disable") {
            return originalSource
        }
        if file == "Package.swift" || file.hasSuffix("/Package.swift") {
            if !transformPackageSwift {
                return originalSource
            }
        } else {
            if !originalSource.contains("SwiftUI") {
                // No reference to SwiftUI and not a Package.swift file - we can skip instrumentation
                return originalSource
            }
        }

#if DEBUG
        // pre-untransform validation check
        try validate(originalSource, file: file, context: "original")
#endif

        var source = try untransform(originalSource, file: file)

#if DEBUG
        // post-untransform/pre-transform validation check
        try validate(originalSource, file: file, context: "untransformed")
#endif

        let preTransformParsed = Parser.parse(source: source)

        if file == "Package.swift" || file.hasSuffix("/Package.swift") {
            // If the file already contains a reference to our package, do not transform it
            if source.contains("https://github.com/fullstorydev/fullstory-swift-package-ios") {
                return originalSource
            }
            let dependenciesFinder = PackageDependenciesFinder(viewMode: .sourceAccurate)
            dependenciesFinder.walk(preTransformParsed)
            if let failReason = dependenciesFinder.failedReason {
                throw TransformError("Failed to parse \(file): \(failReason)\nAdd //Fullstory_XFORM_disable to the file to skip transformation")
            }
            if dependenciesFinder.forceSkip {
                return originalSource
            }
            if dependenciesFinder.targetsLocation != nil {
                // All modifications to the original source must be from end to beginning in order to preserve the
                // locations of earlier modifications. We sort in *reverse* order here.
                dependenciesFinder.inserts.sort { a, b in return a.1 > b.1 }

                var data = Data(source.utf8)
                for (str, loc) in dependenciesFinder.inserts { // iterate forward in the reverse sorted array
                    data.insert(contentsOf: str.utf8, at: loc)
                }
                if verbose {
                    print("Transforming Swift package description \(file)...")
                }
                source = try String(data: data, encoding: .utf8) ?? { throw TransformError("Could not convert import transform back to string") }()
            }
            return source
        }

        var inserts: [(String, Int)] = []

        let importFinder = ImportFinder(viewMode: .sourceAccurate)
        importFinder.walk(preTransformParsed)
        if let importSwiftUI = importFinder.importSwiftUI {
            if !importFinder.importFullstory {
                inserts.append(("/*Fullstory_XFORM_start*/import FullStory;/*Fullstory_XFORM_end*/", importSwiftUI))
            }
        } else {
            return originalSource
        }

        let viewModifierFinder = ViewModifierFinder(viewMode: .sourceAccurate)
        viewModifierFinder.walk(preTransformParsed)
        if viewModifierFinder.bodyAndConformanceLocations.isEmpty {
            // No view structs - don't transform imports
            return originalSource
        }
        for (bodyLocation, conformanceLocation, bodyType) in viewModifierFinder.bodyAndConformanceLocations {
            assert(bodyLocation > conformanceLocation)

            inserts.append(("/*Fullstory_XFORM_start*/ originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody: \(bodyType) {/*Fullstory_XFORM_end*/", bodyLocation))
            inserts.append(("/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/", conformanceLocation))
        }

        // All modifications to the original source must be from end to beginning in order to preserve the
        // locations of earlier modifications. We sort in *reverse* order here.
        inserts.sort { a, b in return a.1 > b.1 }

        var data = Data(source.utf8)
        for (str, loc) in inserts { // iterate forward in the reverse sorted array
            data.insert(contentsOf: str.utf8, at: loc)
        }
        if verbose {
            print("Transforming SwiftUI file \(file)...")
        }

        let transformedSource = try String(data: data, encoding: .utf8) ?? { throw TransformError("Could not convert View transform back to string") }()

#if DEBUG
        // post-transform validation check
        try validate(transformedSource, file: file, context: "transformed")
#endif

        return transformedSource
    }

    // check that the XFORM start/end comments are balanced and unnested
    internal static func validate(_ input: String, file: String = "File", context: String = "") throws {
        for (index, line) in input.split(separator: "\n").enumerated() {
            // search for all /*Fullstory_XFORM_start*/ and /*Fullstory_XFORM_end*/ comments in the line (one pair cannot span multiple lines)
            var inXform = false
            let matches = try NSRegularExpression(pattern: "/\\*Fullstory_XFORM_(start|end)\\*/")
                .matches(in: String(line),
                  range: NSRange(location:0, length:String(line).utf16.count))
            for match in matches {
                let isStart = match.numberOfRanges > 1 && String(line)[String(line).index(String(line).startIndex, offsetBy: match.range(at: 1).lowerBound)..<String(line).index(String(line).startIndex, offsetBy: match.range(at: 1).upperBound)] == "start"
                // handle the happy cases first
                if (isStart && !inXform) {
                    inXform = true
                }
                else if (!isStart && inXform) {
                    inXform = false
                }
                // now for the errors
                else if (!isStart && !inXform) {
                    throw TransformError("Unexpected /*Fullstory_XFORM_end*/ comment in \(context) source at line \(index+1) in \(file).")
                }
                else if (isStart && inXform) {
                    throw TransformError("Nested /*Fullstory_XFORM_start*/ comment in \(context) source at line \(index+1) in \(file).")
                }
            }
            // finally ensure the line didn't end with an open transform.
            if inXform {
                throw TransformError("Unclosed /*Fullstory_XFORM_start*/ comment in \(context) source at line \(index+1) in \(file).")
            }
        }
        // Success! If we get this far without throwing, then the file doesn't have any detected errors!
    }

    internal static func untransform(_ input: String, file: String = "File") throws -> String {
        let str = NSMutableString(string:input)
        let removeTransformCount = try NSRegularExpression(pattern: "\\/\\*Fullstory_XFORM_start\\*\\/.*?\\/\\*Fullstory_XFORM_end\\*\\/").replaceMatches(in: str, range: NSRange(location:0, length:str.length), withTemplate:"")
        return str as String
    }

    static let configuration = CommandConfiguration(commandName: "FullStorySwiftUITransformer")

    @Argument(help: "The input file to transform.")
    var inputFile: String

    @Argument(help: "The transformed output file. Overwrite input file by specifying the same file.")
    var outputFile: String

    @Flag(help: "If specified, warnings will be emitted instead of errors.")
    var warnOnError: Bool = false

    @Flag(help: "If specified, print additional information such as name of transformed file.")
    var verbose: Bool = false

    @Flag(help: "If specified, transform Package.swift files to add FullStory dependency.")
    var transformPackageSwift: Bool = false

    mutating func run() throws {
        var str = try String(contentsOfFile: inputFile)
        let origStr = str
        do {
            try str = FullStorySwiftUITransformer.transform(str, file: inputFile, transformPackageSwift: transformPackageSwift, verbose: verbose)
        } catch {
            if warnOnError {
                print("warning: \(error.localizedDescription) Skipping instrumentation for this file.")
            } else {
                print("error: \(error.localizedDescription) Add --warn-on-error option to make this error a warning, skip instrumentation for this file, and allow the build to continue.")
                throw ExitCode(1)
            }
        }
        if (origStr != str || inputFile != outputFile) {
            try str.write(toFile: outputFile, atomically: true, encoding: String.Encoding.utf8)
        }
    }
}
