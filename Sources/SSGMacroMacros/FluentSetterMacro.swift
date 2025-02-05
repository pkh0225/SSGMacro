import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct FluentSetterMacro: MemberMacro {

    enum Errors: Swift.Error, CustomStringConvertible {
        case invalidInputType

        var description: String {
            "@FluentSetterMacro is only applicable to structs or classes"
        }
    }

    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let storedProperties = try? storedProperties(from: declaration) else {
            throw Errors.invalidInputType
        }

        let accessModifier = accessModifier(from: attribute)
        let properties = properties(from: storedProperties)

        if isStructDecl(from: declaration) {
            return properties.compactMap { (name, type) in
                return """
                \(raw: accessModifier) func \(raw: name)(_ value: \(raw: type)) -> Self {
                    var copy = self
                    copy.\(raw: name) = value
                    return copy
                }
                """
            }
        }
        else {
            return properties.compactMap { (name, type) in
                return """
                \(raw: accessModifier) func \(raw: name)(_ value: \(raw: type)) -> Self {
                    self.\(raw: name) = value
                    return self
                }
                """
            }
        }
    }

    private static func accessModifier(from attribute: AttributeSyntax) -> String {
        if let argumentList = attribute.arguments?.as(LabeledExprListSyntax.self),
           let firstArgument = argumentList.first?.expression.as(StringLiteralExprSyntax.self) {
            return firstArgument.segments.first?.description.trimmingCharacters(in: .init(charactersIn: "\"")) ?? ""
        }
        return ""
    }

    private static func storedProperties(from declaration: DeclGroupSyntax) throws -> [VariableDeclSyntax] {
        if let classDeclaration = declaration.as(ClassDeclSyntax.self) {
            return classDeclaration.storedProperties()
        } else if let structDeclaration = declaration.as(StructDeclSyntax.self) {
            // struct의 경우 mutating 처리가 필요하다면 추가
            return structDeclaration.storedProperties()
        } else {
            throw Errors.invalidInputType
        }
    }

    private static func isStructDecl(from declaration: DeclGroupSyntax) -> Bool {
        return declaration.as(StructDeclSyntax.self) != nil
    }

    private static func properties(from storedProperties: [VariableDeclSyntax]) -> [(name: String, type: String)] {
        storedProperties.compactMap { property -> (name: String, type: String)? in
            guard let patternBinding = property.bindings.first else { return nil }
            // 변수 이름 추출
            guard let name = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
                return nil
            }

            // 명시된 타입이 있는 경우 처리
            if let type = patternBinding.typeAnnotation?.type {
                if let typeName = type.as(IdentifierTypeSyntax.self)?.name {
                    return (name: name.text, type: typeName.text)
                }
                if let typeName = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self)?.wrappedType.as(IdentifierTypeSyntax.self)?.name {
                    return (name: name.text, type: typeName.text)
                }
                if let typeName = type.as(OptionalTypeSyntax.self)?.wrappedType.as(IdentifierTypeSyntax.self)?.name,
                   let questionMark = type.as(OptionalTypeSyntax.self)?.questionMark.text {
                    return (name: name.text, type: typeName.text + questionMark)
                }

                return (name: name.text, type: type.description)
            }

            // 타입이 명시되지 않은 경우, 초기화 값으로 타입 추론(// 다른 타입도 있을텐데... 일단 여기까지)
            if let initializer = patternBinding.initializer?.value {
                switch initializer.syntaxNodeType {
                case is IntegerLiteralExprSyntax.Type:
                    return (name: name.text, type: "Int")
                case is FloatLiteralExprSyntax.Type:
                    return (name: name.text, type: "CGFloat")
                case is StringLiteralExprSyntax.Type:
                    return (name: name.text, type: "String")
                case is BooleanLiteralExprSyntax.Type:
                    return (name: name.text, type: "Bool")
                case is ArrayExprSyntax.Type:
                    return (name: name.text, type: inferArrayType(initializer))
                case is SequenceExprSyntax.Type:
                    return (name: name.text, type: inferSequenceType(initializer))
                case is DictionaryExprSyntax.Type:
                    return (name: name.text, type: inferDictionaryType(initializer))
                case is ClosureExprSyntax.Type:
                    return (name: name.text, type: "ClosureExprSyntax none")
                case is TupleExprSyntax.Type:
                    return (name: name.text, type: inferTupleType(initializer))
                case is FunctionCallExprSyntax.Type:
                    return (name: name.text, type: initializer.as(FunctionCallExprSyntax.self)?.calledExpression.description ?? "FunctionCallExprSyntax none")
                default:
                    return (name: name.text, type: "default none")
                }
            }

            return nil
        }
    }

    // 🔍 배열 타입 추론 함수
    private static func inferArrayType(_ initializer: ExprSyntax) -> String {
        guard let arrayExpr = initializer.as(ArrayExprSyntax.self) else { return "[Any]" }

        let elementTypes = arrayExpr.elements.compactMap { element -> String? in
            return inferLiteralType(element.expression)
        }

        // 요소들이 모두 같은 타입인지 확인
        if let firstType = elementTypes.first, elementTypes.allSatisfy({ $0 == firstType }) {
            return "[\(firstType)]"
        } else {
            return "[Any]"
        }
    }

    private static func inferSequenceType(_ initializer: ExprSyntax) -> String {
        guard let sequenceExpr = initializer.as(SequenceExprSyntax.self) else { return "[Any]" }

        let elements = sequenceExpr.elements
        for index in elements.indices {
            let element = elements[index]

            if let operatorExpr = element.as(UnresolvedAsExprSyntax.self) {
                if operatorExpr.asKeyword.tokenKind == .keyword(.as) {
                    // ✅ 안전한 인덱스 접근
                    let nextIndex = elements.index(after: index)
                    if nextIndex < elements.endIndex {
                        let nextElement = elements[nextIndex]

//                        // TypeExprSyntax로 시도
                        if let typeExpr = nextElement.as(TypeExprSyntax.self) {
                            if let arrayType = typeExpr.type.as(ArrayTypeSyntax.self) {
                                if let elementType = arrayType.element.as(IdentifierTypeSyntax.self) {
                                    return "[\(elementType.name.text)]"
                                }
                            }
                        }

                        // 다른 타입도 있을텐데... 일단 여기까지
                    }
                }
            }
        }

        return "Any" // 기본값
    }

    // 🔍 리터럴 타입 추론 (공통 함수)
    private static func inferLiteralType(_ expr: ExprSyntax?) -> String? {
        guard let expr = expr else { return nil }

        switch expr.syntaxNodeType {
        case is IntegerLiteralExprSyntax.Type:
            return "Int"
        case is FloatLiteralExprSyntax.Type:
            return "CGFloat"
        case is StringLiteralExprSyntax.Type:
            return "String"
        case is BooleanLiteralExprSyntax.Type:
            return "Bool"
        case is ArrayExprSyntax.Type:
            return "[Any]"
        case is DictionaryExprSyntax.Type:
            return "[AnyHashable: Any]"
        case is NilLiteralExprSyntax.Type:
            return "Nil"
        case is TupleExprSyntax.Type:
            return "(Any, Any)" // 튜플의 경우 요소를 상세히 분석할 수 있음
        case is KeyPathExprSyntax.Type:
            return "KeyPath"
        case is ClosureExprSyntax.Type:
            return "() -> Void" // 기본적으로 클로저 타입, 파라미터 및 반환값 분석 가능
        default:
            return "Any"
        }
    }

    // 🔑 딕셔너리 타입 추론 함수
    private static func inferDictionaryType(_ initializer: ExprSyntax) -> String {
        guard let dictExpr = initializer.as(DictionaryExprSyntax.self) else { return "[AnyHashable: Any]" }

        var keyTypes: Set<String> = []
        var valueTypes: Set<String> = []

        dictExpr.content.as(DictionaryElementListSyntax.self)?.forEach { element in
            // keyExpression과 valueExpression에 대해 타입 추론
            if let keyType = inferLiteralType(element.key) {
                keyTypes.insert(keyType)
            }
            if let valueType = inferLiteralType(element.value) {
                valueTypes.insert(valueType)
            }
        }

        // 키 타입과 값 타입이 하나만 있으면 해당 타입을 사용, 아니면 Any
        let keyType = keyTypes.count == 1 ? keyTypes.first! : "AnyHashable"
        let valueType = valueTypes.count == 1 ? valueTypes.first! : "Any"

        return "[\(keyType): \(valueType)]"
    }

    private static func inferTupleType(_ initializer: ExprSyntax) -> String {
        guard let tupleExpr = initializer.as(TupleExprSyntax.self) else { return "(name: tuple, type: Any)" }

        let elementTypes = tupleExpr.elements.map { element -> String in
            let name = element.label?.text ?? "_"
            let type = inferLiteralType(element.expression) ?? "Any"
            if name == "_" {
                return "\(type)"
            }
            else {
                return "\(name): \(type)"
            }
        }

        return "(\(elementTypes.joined(separator: ", ")))"
    }
}

extension VariableDeclSyntax {
    /// Check if this variable has the syntax of a stored property.
    var isStoredProperty: Bool {
        guard !isLazyProperty, !isLetProperty, !isPrivateProperty, !isComputedProperty, !isStaticProperty else { return false }

        return true
    }

    var isStaticProperty: Bool {
        modifiers.contains { $0.name.tokenKind == .keyword(Keyword.static) }
    }

    /// 연산 프로퍼티인지 확인 (get-only인지 포함)
    var isComputedProperty: Bool {
        return bindings.contains { $0.accessorBlock != nil }
    }

    var isLazyProperty: Bool {
        modifiers.contains { $0.name.tokenKind == .keyword(Keyword.lazy) }
    }

    var isLetProperty: Bool {
        bindingSpecifier.tokenKind == .keyword(Keyword.let)
    }

    var isPrivateProperty: Bool {
        modifiers.contains { $0.name.tokenKind == .keyword(Keyword.private) }
    }
}


extension DeclGroupSyntax {
    /// Get the stored properties from the declaration based on syntax.
    func storedProperties() -> [VariableDeclSyntax] {
        return memberBlock.members.compactMap { member in
            guard let variable = member.decl.as(VariableDeclSyntax.self),
                  variable.isStoredProperty else {
                return nil
            }

            return variable
        }
    }
}
