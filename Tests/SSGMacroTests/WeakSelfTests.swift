import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(SSGMacroMacros)
import SSGMacroMacros

let weakSelfMacros: [String: Macro.Type] = [
    "WeakSelfClosure": WeakSelfClosure.self,
]
#endif

final class WeakSelfMacroTests: XCTestCase {

    func testWeaSelfMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            let action = #WeakSelfClosure {
                print("run")
            }
            """,
            expandedSource: """
            let action = { [weak self] in
                guard let self else {
                    return
                }
                    print("run")
            }
            """,
            macros: weakSelfMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
