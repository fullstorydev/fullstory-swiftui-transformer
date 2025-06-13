import Foundation
import Testing
import ArgumentParser
// upgrade Package.swift to swift-tools-version: 5.10 to run these tests!
@testable import FullStorySwiftUITransformer

struct FullStorySwiftUITransformerTests {
    @Test func Transform() throws {
        let example1 = """
import SwiftUI
struct MyView: View {
    var body: some View {
        Text("Hello, World!")
    }
}
"""
        let example1Expected = """
/*Fullstory_XFORM_start*/import FullStory;/*Fullstory_XFORM_end*/import SwiftUI
struct MyView:/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/ View {
    var body: some View {/*Fullstory_XFORM_start*/ originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody: some View {/*Fullstory_XFORM_end*/
        Text("Hello, World!")
    }
}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1Expected)
        let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed)
        #expect(example1TransformedAgain == example1Expected)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1)
    }

    @Test func Disable() throws {
        let example1 = """
import SwiftUI
//Fullstory_XFORM_disable
struct MyView: View {
    var body: some View {
        Text("Hello, World!")
    }
}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1)
    }

    @Test func PartiallyTransformed() throws {
        let example1 = """
// random comment
/*Fullstory_XFORM_start*/import FullStory;/*Fullstory_XFORM_end*/import SwiftUI
struct MyView:/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/ View {
    var body: some View {/*Fullstory_XFORM_start*/ originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody: some View {/*Fullstory_XFORM_end*/
        Text("Hello, World!")
    }
}

struct MyView2: View {
    var body: some View {
        Text("Hello, World!")
    }
}
"""
        let example1Expected = """
// random comment
/*Fullstory_XFORM_start*/import FullStory;/*Fullstory_XFORM_end*/import SwiftUI
struct MyView:/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/ View {
    var body: some View {/*Fullstory_XFORM_start*/ originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody: some View {/*Fullstory_XFORM_end*/
        Text("Hello, World!")
    }
}

struct MyView2:/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/ View {
    var body: some View {/*Fullstory_XFORM_start*/ originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody: some View {/*Fullstory_XFORM_end*/
        Text("Hello, World!")
    }
}
"""

        let example1Untransformed = """
// random comment
import SwiftUI
struct MyView: View {
    var body: some View {
        Text("Hello, World!")
    }
}

struct MyView2: View {
    var body: some View {
        Text("Hello, World!")
    }
}
"""

        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1Expected)
        let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed)
        #expect(example1TransformedAgain == example1Expected)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1Untransformed)
    }

    @Test func NonViewBuilderTransform() throws {
        let example1 = """
import SwiftUI
struct NonViewBuilder: View {
    var body: some View {
        if (Bool.random()) {
            return Text("Hello, World!")
        } else {
            return Text("World, Hello!")
        }
    }
}
"""
        let example1Expected = """
/*Fullstory_XFORM_start*/import FullStory;/*Fullstory_XFORM_end*/import SwiftUI
struct NonViewBuilder:/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/ View {
    var body: some View {/*Fullstory_XFORM_start*/ originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody: some View {/*Fullstory_XFORM_end*/
        if (Bool.random()) {
            return Text("Hello, World!")
        } else {
            return Text("World, Hello!")
        }
    }
}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1Expected)
        let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed)
        #expect(example1TransformedAgain == example1Expected)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1)

    }

    @Test func NonViewBuilderTransform2() throws {
        let example1 = """
import SwiftUI
struct NonViewBuilder: View {
    var body: Text {
        if (Bool.random()) {
            return Text("Hello, World!")
        } else {
            return Text("World, Hello!")
        }
    }
}
"""
        let example1Expected = """
/*Fullstory_XFORM_start*/import FullStory;/*Fullstory_XFORM_end*/import SwiftUI
struct NonViewBuilder:/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/ View {
    var body/*Fullstory_XFORM_start*/: some View { originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody/*Fullstory_XFORM_end*/: Text {
        if (Bool.random()) {
            return Text("Hello, World!")
        } else {
            return Text("World, Hello!")
        }
    }
}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1) // TODO: allow transformation to work, remove this
        #expect(example1Transformed != example1Expected) // TODO: make equal, uncomment below
        //let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed)
        //#expect(example1TransformedAgain == example1Expected)
        //let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        //#expect(example1Restored == example1)
    }

    @Test func NonViewBuilderTransform3a() throws {
        let example1 = """
import SwiftUI
struct NonViewBuilder: View {
    let body: Text = Text("Hello, World")
}
"""
        let example1Expected = """
/*Fullstory_XFORM_start*/import FullStory;/*Fullstory_XFORM_end*/import SwiftUI
struct NonViewBuilder:/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/ View {
    /*Fullstory_letvar*/var body/*Fullstory_XFORM_start*/: some View { originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody/*Fullstory_XFORM_end*/: Text = Text("Hello, World"
    }
}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1) // TODO: allow transformation to work, remove this
        #expect(example1Transformed != example1Expected) // TODO: make equal, uncomment below
        //let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed)
        //#expect(example1TransformedAgain == example1Expected)
        //let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        //#expect(example1Restored == example1)
    }

    @Test func NonViewBuilderTransform3b() throws {
        let example1 = """
import SwiftUI
struct NonViewBuilder: View {
    let body: some View = Text("Hello, World")
}
"""
        let example1Expected = """
/*Fullstory_XFORM_start*/import FullStory;/*Fullstory_XFORM_end*/import SwiftUI
struct NonViewBuilder:/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/ View {
    /*Fullstory_letvar*/var body/*Fullstory_XFORM_start*/: some View { originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody/*Fullstory_XFORM_end*/: some View = Text("Hello, World")
    }
}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1) // TODO: allow transformation to work, remove this
        #expect(example1Transformed != example1Expected) // TODO: make equal, uncomment below
        //let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed)
        //#expect(example1TransformedAgain == example1Expected)
        //let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        //#expect(example1Restored == example1)
    }

    @Test func NonViewBuilderTransform4() throws {
        let example1 = """
import SwiftUI
struct NonViewBuilder: View {
    let body = Text("Hello, World")
}
"""
        let example1Expected = """
/*Fullstory_XFORM_start*/import FullStory;/*Fullstory_XFORM_end*/import SwiftUI
struct NonViewBuilder:/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/ View {
    /*Fullstory_letvar*/var body/*Fullstory_XFORM_start*/: some View { originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody/*Fullstory_XFORM_end*/ = Text("Hello, World")
    }
}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1) // TODO: allow transformation to work, remove this
        #expect(example1Transformed != example1Expected) // TODO: make equal, uncomment below
        //let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed)
        //#expect(example1TransformedAgain == example1Expected)
        //let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        //#expect(example1Restored == example1)
    }

    @Test func NonViewBuilderTransform5() throws {
        let example1 = """
import SwiftUI
struct NonViewBuilder: View {
    let body = VStack() {
        Text("Hello World")
        Text("Goodbye World")
    }
}
"""
        let example1Expected = """
/*Fullstory_XFORM_start*/import FullStory;/*Fullstory_XFORM_end*/import SwiftUI
struct NonViewBuilder:/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/ View {
    /*Fullstory_letvar*/var body/*Fullstory_XFORM_start*/: some View { originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody/*Fullstory_XFORM_end*/ = VStack() {
        Text("Hello World")
        Text("Goodbye World")
    }
}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1) // TODO: allow transformation to work, remove this
        #expect(example1Transformed != example1Expected) // TODO: make equal, uncomment below
        //let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed)
        //#expect(example1TransformedAgain == example1Expected)
        //let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        //#expect(example1Restored == example1)
    }

    @Test func NoBodiesTransform() throws {
        let example1 = """
import SwiftUI
struct MyView: View {
    var nobody: some View {
        Text("Hello, World!")
    }
}
"""
        var didFail = false;
        do {
            let transformed = try FullStorySwiftUITransformer.transform(example1)
            #expect(transformed == example1)
            // Return value can never be nil, but we can never reach the next
            // line because we'll throw. We don't want to trigger
            // the warning for an ignored return value. This assert can be
            // updated if the compiler starts warning for nil check on a value
            // that cannot be nil.
        } catch {
            didFail = false
        }
        #expect(!didFail)
    }

    @Test func GenericTransform() throws {
        let example1 = """
import SwiftUI
public struct GenericView<Label: View>: View {
    @ViewBuilder public var label: () -> Label

    public var body: some View { }
}
"""
        let example1Expected =
        """
/*Fullstory_XFORM_start*/import FullStory;/*Fullstory_XFORM_end*/import SwiftUI
public struct GenericView<Label: View>:/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/ View {
    @ViewBuilder public var label: () -> Label

    public var body: some View {/*Fullstory_XFORM_start*/ originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody: some View {/*Fullstory_XFORM_end*/ }
}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1Expected)
        let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed)
        #expect(example1TransformedAgain == example1Expected)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1)
    }

    @Test func TransformMultipleProtocolsNoView() throws {
        let example1 = """
import SwiftUI
struct MyView: NotAView,ViewNope,_View_ {
}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1)
    }

    @Test func TransformMultipleProtocols() throws {
        let example1 = """
import SwiftUI
struct MyView: FooView,SwiftUI.View,ViewThingy {
    var body: some View {
        Text("Hello, World!")
    }
}
"""
        let example1Expected = """
/*Fullstory_XFORM_start*/import FullStory;/*Fullstory_XFORM_end*/import SwiftUI
struct MyView:/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/ FooView,SwiftUI.View,ViewThingy {
    var body: some View {/*Fullstory_XFORM_start*/ originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody: some View {/*Fullstory_XFORM_end*/
        Text("Hello, World!")
    }
}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1Expected)
        let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed)
        #expect(example1TransformedAgain == example1Expected)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1)
    }

    @Test func TransformWhereClause() throws {
        let example1 = """
import SwiftUI
import FullStory

public struct MyContentActionView<Content>: View where Content: View {
    private let content: () -> Content
    private let action: () async -> Void

    public init(action: @escaping () async -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.content = content
    }

    public var body: some View {
        content.task(action)
    }
}
"""
        let example1Expected = """
import SwiftUI
import FullStory

public struct MyContentActionView<Content>:/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/ View where Content: View {
    private let content: () -> Content
    private let action: () async -> Void

    public init(action: @escaping () async -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.content = content
    }

    public var body: some View {/*Fullstory_XFORM_start*/ originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody: some View {/*Fullstory_XFORM_end*/
        content.task(action)
    }
}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1Expected)
        let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed)
        #expect(example1TransformedAgain == example1Expected)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1)
    }

    @Test func TransformWhereClauses() throws {
        let example1 = """
import SwiftUI

public struct MyLabelActionView<Title, Icon>: View where Title: View, Icon: View {
    private let title: () -> Content
    private let icon: () -> Content
    private let action: () async -> Void

    public init(action: @escaping () async -> Void, @ViewBuilder title: @escaping () -> Content, icon: @escaping () -> Content) {
        self.action = action
        self.title = title
        self.icon = icon
    }

    public var body: some View {
        Label(title: title, icon: icon).task(action)
    }
}
"""
        let example1Expected = """
/*Fullstory_XFORM_start*/import FullStory;/*Fullstory_XFORM_end*/import SwiftUI

public struct MyLabelActionView<Title, Icon>:/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/ View where Title: View, Icon: View {
    private let title: () -> Content
    private let icon: () -> Content
    private let action: () async -> Void

    public init(action: @escaping () async -> Void, @ViewBuilder title: @escaping () -> Content, icon: @escaping () -> Content) {
        self.action = action
        self.title = title
        self.icon = icon
    }

    public var body: some View {/*Fullstory_XFORM_start*/ originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody: some View {/*Fullstory_XFORM_end*/
        Label(title: title, icon: icon).task(action)
    }
}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1Expected)
        let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed)
        #expect(example1TransformedAgain == example1Expected)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1)
    }

    @Test func TransformWhereClauseNotView() throws {
        let example1 = """
import SwiftUI

public struct MyLabelActionView<Title> where Title: View {
    private let title: () -> Content
    private let icon: () -> Content
    private let action: () async -> Void

    public init(action: @escaping () async -> Void, @ViewBuilder title: @escaping () -> Content, icon: @escaping () -> Content) {
        self.action = action
        self.title = title
        self.icon = icon
    }

}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1)
    }


    @Test func TransformWhereClausesNotView() throws {
        let example1 = """
import SwiftUI

public struct MyLabelActionView<Title, Icon> where Title: View, Icon: View {
    private let title: () -> Content
    private let icon: () -> Content
    private let action: () async -> Void

    public init(action: @escaping () async -> Void, @ViewBuilder title: @escaping () -> Content, icon: @escaping () -> Content) {
        self.action = action
        self.title = title
        self.icon = icon
    }

}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1)
    }

    @Test func TransformMultipleLines() throws {
        let example1 = """
import
SwiftUI
struct
MyView:
View {
var
body:
some View
{
Text("Hello, World!")
}
}
"""
        let example1Expected = """
/*Fullstory_XFORM_start*/import FullStory;/*Fullstory_XFORM_end*/import
SwiftUI
struct
MyView:/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/
View {
var
body:
some View
{/*Fullstory_XFORM_start*/ originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody: some View {/*Fullstory_XFORM_end*/
Text("Hello, World!")
}
}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1Expected)
        let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed)
        #expect(example1TransformedAgain == example1Expected)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1)
    }

    @Test func TransformViewNamedView() throws {
        let example1 = """
import SwiftUI
struct View: SwiftUI.View {
    var body: some SwiftUI.View {
        Text("Hello, World!")
    }
}
"""
        let example1Expected = """
/*Fullstory_XFORM_start*/import FullStory;/*Fullstory_XFORM_end*/import SwiftUI
struct View:/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/ SwiftUI.View {
    var body: some SwiftUI.View {/*Fullstory_XFORM_start*/ originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody: some SwiftUI.View {/*Fullstory_XFORM_end*/
        Text("Hello, World!")
    }
}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1Expected)
        let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed)
        #expect(example1TransformedAgain == example1Expected)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1)
    }

    @Test func TransformWithThirdPartySwiftUIFramework() throws {
        let example1 = """
import SwiftUI
import SwiftUIFlubber

struct ThingyList: View {
    @EnvironmentObject private var store: Store<AppState>

    var body: some View {
        List {
            ForEach(store.state.thingyState.stuff) { thing in
                NavigationLink(destination: SpecificThingyList(stuff: stuff)) {
                    Text(stuff.name)
                }
            }
        }
    }
}
"""
        let example1Expected = """
/*Fullstory_XFORM_start*/import FullStory;/*Fullstory_XFORM_end*/import SwiftUI
import SwiftUIFlubber

struct ThingyList:/*Fullstory_XFORM_start*/ FSSelectableView,/*Fullstory_XFORM_end*/ View {
    @EnvironmentObject private var store: Store<AppState>

    var body: some View {/*Fullstory_XFORM_start*/ originalBody.fsSelectable(String(reflecting: Swift.type(of: self))) }; @ViewBuilder @MainActor @usableFromInline var originalBody: some View {/*Fullstory_XFORM_end*/
        List {
            ForEach(store.state.thingyState.stuff) { thing in
                NavigationLink(destination: SpecificThingyList(stuff: stuff)) {
                    Text(stuff.name)
                }
            }
        }
    }
}
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1)
        #expect(example1Transformed == example1Expected)
        let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed)
        #expect(example1TransformedAgain == example1Expected)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1)
    }

    @Test func SkipTransformerWithFullstory() throws {
        let example1 = """
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FullStorySwiftUITransformer",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from:Version("600.0.1")),
        .package(url: "https://github.com/fullstorydev/fullstory-swift-package-ios", from:Version("1.58.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "FullStorySwiftUITransformer",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]),
        .testTarget(name: "FullStorySwiftUITransformerTests",
                    dependencies: ["FullStorySwiftUITransformer"]),
    ]
)
"""

        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1, file: "Package.swift")
        #expect(example1Transformed == example1)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1)
    }

    @Test func TransformerWithPackage() throws {
        let example1 = """
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FullStorySwiftUITransformer",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from:Version("600.0.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "FullStorySwiftUITransformer",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]),
        .testTarget(name: "FullStorySwiftUITransformerTests",
                    dependencies: ["FullStorySwiftUITransformer"]),
    ]
)
"""
        let example1Expected = """
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FullStorySwiftUITransformer",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    dependencies: [/*Fullstory_XFORM_start*/.package(url: "https://github.com/fullstorydev/fullstory-swift-package-ios", "1.0.0"..<"2.0.0"),/*Fullstory_XFORM_end*/
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from:Version("600.0.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "FullStorySwiftUITransformer",
            dependencies: [/*Fullstory_XFORM_start*/.product(name: "FullStory", package: "fullstory-swift-package-ios"),/*Fullstory_XFORM_end*/
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]),
        .testTarget(name: "FullStorySwiftUITransformerTests",
                    dependencies: [/*Fullstory_XFORM_start*/.product(name: "FullStory", package: "fullstory-swift-package-ios"),/*Fullstory_XFORM_end*/"FullStorySwiftUITransformer"]),
    ]
)
"""

        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1, file: "Package.swift")
        #expect(example1Transformed == example1Expected)
        let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed, file: "Package.swift")
        #expect(example1TransformedAgain == example1Expected)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1)
    }

    @Test func TransformerNoDependencies() throws {
        let example1 = """
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FullStorySwiftUITransformer",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "FullStorySwiftUITransformer",
            packageAccess: true),
        .testTarget(name: "FullStorySwiftUITransformerTests"),
    ]
)
"""
        let example1Expected = """
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FullStorySwiftUITransformer",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    /*Fullstory_XFORM_start*/dependencies: [.package(url: "https://github.com/fullstorydev/fullstory-swift-package-ios", "1.0.0"..<"2.0.0")],/*Fullstory_XFORM_end*/targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "FullStorySwiftUITransformer"/*Fullstory_XFORM_start*/,dependencies: [.product(name: "FullStory", package: "fullstory-swift-package-ios")]/*Fullstory_XFORM_end*/,
            packageAccess: true),
        .testTarget(name: "FullStorySwiftUITransformerTests"/*Fullstory_XFORM_start*/,dependencies: [.product(name: "FullStory", package: "fullstory-swift-package-ios")]/*Fullstory_XFORM_end*/),
    ]
)
"""

        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1, file: "Package.swift")
        #expect(example1Transformed == example1Expected)
        let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed, file: "Package.swift")
        #expect(example1TransformedAgain == example1Expected)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1)
    }

    @Test func TransformerNoPackageDependencies() throws {
        let example1 = """
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FullStorySwiftUITransformer",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "FullStorySwiftUITransformer",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]),
        .testTarget(name: "FullStorySwiftUITransformerTests",
                    dependencies: ["FullStorySwiftUITransformer"]),
        .plugin(
            name: "GenerateManual",
            capability: .command(
                intent: .custom(
                    verb: "generate-manual",
                    description: "Generate a manual entry for a specified target.")),
            dependencies: ["generate-manual"]),
    ]
)
"""
        let example1Expected = """
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FullStorySwiftUITransformer",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    /*Fullstory_XFORM_start*/dependencies: [.package(url: "https://github.com/fullstorydev/fullstory-swift-package-ios", "1.0.0"..<"2.0.0")],/*Fullstory_XFORM_end*/targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "FullStorySwiftUITransformer",
            dependencies: [/*Fullstory_XFORM_start*/.product(name: "FullStory", package: "fullstory-swift-package-ios"),/*Fullstory_XFORM_end*/
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]),
        .testTarget(name: "FullStorySwiftUITransformerTests",
                    dependencies: [/*Fullstory_XFORM_start*/.product(name: "FullStory", package: "fullstory-swift-package-ios"),/*Fullstory_XFORM_end*/"FullStorySwiftUITransformer"]),
        .plugin(
            name: "GenerateManual",
            capability: .command(
                intent: .custom(
                    verb: "generate-manual",
                    description: "Generate a manual entry for a specified target.")),
            dependencies: ["generate-manual"]),
    ]
)
"""

        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1, file: "Package.swift")
        #expect(example1Transformed == example1Expected)
        let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed, file: "Package.swift")
        #expect(example1TransformedAgain == example1Expected)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1)
    }

    @Test func TransformerNoExecutableTargetDependencies() throws {
        let example1 = """
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FullStorySwiftUITransformer",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from:Version("600.0.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(name: "FullStorySwiftUITransformer"),
        .testTarget(name: "FullStorySwiftUITransformerTests",
                    dependencies: ["FullStorySwiftUITransformer"]),
    ]
)
"""
        let example1Expected = """
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FullStorySwiftUITransformer",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    dependencies: [/*Fullstory_XFORM_start*/.package(url: "https://github.com/fullstorydev/fullstory-swift-package-ios", "1.0.0"..<"2.0.0"),/*Fullstory_XFORM_end*/
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from:Version("600.0.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(name: "FullStorySwiftUITransformer"/*Fullstory_XFORM_start*/,dependencies: [.product(name: "FullStory", package: "fullstory-swift-package-ios")]/*Fullstory_XFORM_end*/),
        .testTarget(name: "FullStorySwiftUITransformerTests",
                    dependencies: [/*Fullstory_XFORM_start*/.product(name: "FullStory", package: "fullstory-swift-package-ios"),/*Fullstory_XFORM_end*/"FullStorySwiftUITransformer"]),
    ]
)
"""

        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1, file: "Package.swift")
        #expect(example1Transformed == example1Expected)
        let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed, file: "Package.swift")
        #expect(example1TransformedAgain == example1Expected)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1)
    }

    @Test func SkipTransformerOnFullStory () {
        let example1 = """
// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "FullStory",
    products: [
        .library(
            name: "FullStory",
            targets: ["FullStory"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "FullStory",
            url: "https://ios-releases.fullstory.com/fullstory-1.59.1-xcframework.zip",
            checksum: "db4be60b997dbc98010d92ca9131e067e8afdf0f905188e7d2f510f256066dae"
        ),
    ]
)
"""
        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1, file: "Package.swift")
        #expect(example1Transformed == example1)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1)
    }

    @Test func TransformerWithVariableDependencies() throws {
        let example1 = """
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let packageDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from:Version("600.0.1")),
]

let package = Package(
    name: "FullStorySwiftUITransformer",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    dependencies: packageDependencies,
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "FullStorySwiftUITransformer",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]),
        .testTarget(name: "FullStorySwiftUITransformerTests",
                    dependencies: ["FullStorySwiftUITransformer"]),
    ]
)
"""
        let example1Expected = """
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let packageDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from:Version("600.0.1")),
]

let package = Package(
    name: "FullStorySwiftUITransformer",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    dependencies: /*Fullstory_XFORM_start*/(/*Fullstory_XFORM_end*/packageDependencies/*Fullstory_XFORM_start*/+ [.package(url: "https://github.com/fullstorydev/fullstory-swift-package-ios", "1.0.0"..<"2.0.0")])/*Fullstory_XFORM_end*/,
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "FullStorySwiftUITransformer",
            dependencies: [/*Fullstory_XFORM_start*/.product(name: "FullStory", package: "fullstory-swift-package-ios"),/*Fullstory_XFORM_end*/
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]),
        .testTarget(name: "FullStorySwiftUITransformerTests",
                    dependencies: [/*Fullstory_XFORM_start*/.product(name: "FullStory", package: "fullstory-swift-package-ios"),/*Fullstory_XFORM_end*/"FullStorySwiftUITransformer"]),
    ]
)
"""

        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1, file: "Package.swift")
        #expect(example1Transformed == example1Expected)
        let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed, file: "Package.swift")
        #expect(example1TransformedAgain == example1Expected)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1)
    }

    @Test func TransformerWithDoubleVariableDependencies() throws {
        let example1 = """
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let packageDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from:Version("600.0.1")),
]
let targetDependencies: [Target.Dependency] = [
    .product(name: "SwiftSyntax", package: "swift-syntax"),
    .product(name: "SwiftParser", package: "swift-syntax")
]

let package = Package(
    name: "FullStorySwiftUITransformer",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    dependencies: packageDependencies,
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "FullStorySwiftUITransformer",
            dependencies: targetDependencies),
        .testTarget(name: "FullStorySwiftUITransformerTests",
                    dependencies: ["FullStorySwiftUITransformer"]),
    ]
)
"""
        let example1Expected = """
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let packageDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from:Version("600.0.1")),
]
let targetDependencies: [Target.Dependency] = [
    .product(name: "SwiftSyntax", package: "swift-syntax"),
    .product(name: "SwiftParser", package: "swift-syntax")
]

let package = Package(
    name: "FullStorySwiftUITransformer",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    dependencies: /*Fullstory_XFORM_start*/(/*Fullstory_XFORM_end*/packageDependencies/*Fullstory_XFORM_start*/+ [.package(url: "https://github.com/fullstorydev/fullstory-swift-package-ios", "1.0.0"..<"2.0.0")])/*Fullstory_XFORM_end*/,
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "FullStorySwiftUITransformer",
            dependencies: /*Fullstory_XFORM_start*/(/*Fullstory_XFORM_end*/targetDependencies/*Fullstory_XFORM_start*/+ [.product(name: \"FullStory\", package: \"fullstory-swift-package-ios\")])/*Fullstory_XFORM_end*/),
        .testTarget(name: "FullStorySwiftUITransformerTests",
                    dependencies: [/*Fullstory_XFORM_start*/.product(name: "FullStory", package: "fullstory-swift-package-ios"),/*Fullstory_XFORM_end*/"FullStorySwiftUITransformer"]),
    ]
)
"""

        let example1Transformed = try! FullStorySwiftUITransformer.transform(example1, file: "Package.swift")
        #expect(example1Transformed == example1Expected)
        let example1TransformedAgain = try! FullStorySwiftUITransformer.transform(example1Transformed, file: "Package.swift")
        #expect(example1TransformedAgain == example1Expected)
        let example1Restored = try! FullStorySwiftUITransformer.untransform(example1Transformed)
        #expect(example1Restored == example1)
    }

    @Test func UnexpectedEndComment() throws {
        let example1 = """
import SwiftUI
struct MyView: /*Fullstory_XFORM_end*/ View {
    var nobody: some View {
        Text("Hello, World!")
    }
}
"""
        #expect(throws: FullStorySwiftUITransformer.TransformError("Unexpected /*Fullstory_XFORM_end*/ comment in  source at line 2 in File.")){
            try FullStorySwiftUITransformer.validate(example1)
          }
    }

    @Test func UnclosedStartComment() throws {
        let example1 = """
import SwiftUI
struct MyView: /*Fullstory_XFORM_start*/ View {
    var nobody: some View {
        Text("Hello, World!")
    }
}
"""
        #expect(throws: FullStorySwiftUITransformer.TransformError("Unclosed /*Fullstory_XFORM_start*/ comment in  source at line 2 in File.")){
            try FullStorySwiftUITransformer.validate(example1)
          }
    }

    @Test func NestedTransformComment() throws {
        let example1 = """
import SwiftUI
struct MyView: /*Fullstory_XFORM_start*//*Fullstory_XFORM_start*//*Fullstory_XFORM_end*//*Fullstory_XFORM_end*/ View {
    var nobody: some View {
        Text("Hello, World!")
    }
}
"""
        #expect(throws: FullStorySwiftUITransformer.TransformError("Nested /*Fullstory_XFORM_start*/ comment in  source at line 2 in File.")){
            try FullStorySwiftUITransformer.validate(example1)
          }
    }
}


