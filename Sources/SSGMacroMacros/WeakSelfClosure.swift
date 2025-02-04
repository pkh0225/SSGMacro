import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum WeakSelfClosure: ExpressionMacro {
    enum SomeError: Swift.Error, CustomStringConvertible {
        case invalidInputType

        var description: String {
            "@WeakSelfClosure is only Closure"
        }
    }
    public static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> ExprSyntax {
        guard var closure = node.trailingClosure else {
            throw SomeError.invalidInputType
        }
        var signature = closure.signature
        let weakSelfCapture = ClosureCaptureSyntax(
            specifier: .init(specifier: "weak"),
            expression: DeclReferenceExprSyntax(baseName: "self")
        )
        if var signature = closure.signature {
            signature.capture = .init(items: .init {
                for capture in signature.capture?.items ?? [] {
                    capture
                }
                weakSelfCapture
            })
            closure.signature = signature
        } else {
            closure.signature = ClosureSignatureSyntax(capture: .init(items: [weakSelfCapture]))
        }
        closure.statements = .init {
            "guard let self else { return }"
            for stmt in closure.statements {
                stmt
            }
        }
        return ExprSyntax(closure)
    }
}
