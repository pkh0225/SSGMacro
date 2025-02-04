import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct PublicMemeberwiseInitMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FluentSetterMacro.self,
        WeakSelfClosure.self
    ]
}
