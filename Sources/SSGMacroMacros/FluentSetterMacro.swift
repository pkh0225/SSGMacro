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
                return (name: name.text, type: inferTypeSyntax(type))
            }

            // 타입이 명시되지 않은 경우, 초기화 값으로 타입 추론(// 다른 타입도 있을텐데... 일단 여기까지)
            if let expr = patternBinding.initializer?.value {
                return (name: name.text, type: inferExprSyntax(expr))
            }
            return nil
        }
    }

    private static func inferTypeSyntax(_ type: TypeSyntax?) -> String {
        guard let type else { return "" }
        if let type = type.as(IdentifierTypeSyntax.self) {
            return type.name.text
        }
        else if let type = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            if let wrappedType = type.wrappedType.as(TupleTypeSyntax.self) {
                return "@escaping \(inferTypeSyntax(type.wrappedType))"
            }
            return inferTypeSyntax(type.wrappedType)
        }
        else if let type = type.as(OptionalTypeSyntax.self) {
            return inferTypeSyntax(type.wrappedType) + type.questionMark.text
        }
        else if let type = type.as(TupleTypeSyntax.self) {
            return type.leftParen.text + type.elements.description + type.rightParen.text
        }
        else if let type = type.as(MetatypeTypeSyntax.self) {
            return inferTypeSyntax(type.baseType) + type.period.text + type.metatypeSpecifier.text
        }
        else if let type = type.as(ArrayTypeSyntax.self) {
            return type.leftSquare.text + type.element.description + type.rightSquare.text
        }
        else if let type = type.as(DictionaryTypeSyntax.self) {
            return type.leftSquare.text + inferTypeSyntax(type.key) + type.colon.text + inferTypeSyntax(type.value) + type.rightSquare.text
        }

        return type.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // 🔍 리터럴 타입 추론 (공통 함수)
    private static func inferExprSyntax(_ expr: ExprSyntax?) -> String {
        guard let expr else { return "" }
        switch expr.syntaxNodeType {
        case is IntegerLiteralExprSyntax.Type:
            return "Int"
        case is FloatLiteralExprSyntax.Type:
            return "CGFloat"
        case is StringLiteralExprSyntax.Type:
            return "String"
        case is BooleanLiteralExprSyntax.Type:
            return "Bool"
        case is ClosureExprSyntax.Type:
            return inferClosureExprSyntax(expr)
        case is ArrayExprSyntax.Type:
            return inferArrayExprSyntax(expr)
        case is DictionaryExprSyntax.Type:
            return inferDictionaryExprSyntax(expr)
        case is TupleExprSyntax.Type:
            return inferTupleExprSyntax(expr)
        case is FunctionCallExprSyntax.Type:
            return inferFunctionCallExprSyntax(expr)
        case is SequenceExprSyntax.Type:
            return inferSequenceExprSyntax(expr)
        case is NilLiteralExprSyntax.Type:
            return "Nil"
        case is KeyPathExprSyntax.Type:
            return "KeyPath"

        default:
            return expr.description.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    // 🔍 배열 타입 추론 함수
    private static func inferArrayExprSyntax(_ expr: ExprSyntax) -> String {
        guard let arrayExpr = expr.as(ArrayExprSyntax.self) else { return "[Any]" }

        let elementTypes = arrayExpr.elements.compactMap { element -> String? in
            return inferExprSyntax(element.expression)
        }

        // 요소들이 모두 같은 타입인지 확인
        if let firstType = elementTypes.first, elementTypes.allSatisfy({ $0 == firstType }) {
            return "[\(firstType)]"
        } else {
            return "[Any]"
        }
    }

    private static func inferSequenceExprSyntax(_ expr: ExprSyntax) -> String {
        guard let sequenceExpr = expr.as(SequenceExprSyntax.self) else { return "[Any]" }

        let elements = sequenceExpr.elements
        for index in elements.indices {
            let element = elements[index]

            if let operatorExpr = element.as(UnresolvedAsExprSyntax.self) {
                if operatorExpr.asKeyword.tokenKind == .keyword(.as) {
                    // ✅ 안전한 인덱스 접근
                    let nextIndex = elements.index(after: index)
                    if nextIndex < elements.endIndex {
                        let nextElement = elements[nextIndex]
                        if let typeExpr = nextElement.as(TypeExprSyntax.self) {
                            return inferTypeSyntax(typeExpr.type)
                        }
                    }
                }
            }
        }

        return "Any" // 기본값
    }

    // 🔑 딕셔너리 타입 추론 함수
    private static func inferDictionaryExprSyntax(_ expr: ExprSyntax) -> String {
        guard let dictExpr = expr.as(DictionaryExprSyntax.self) else { return "[AnyHashable: Any]" }

        var keyTypes: Set<String> = []
        var valueTypes: Set<String> = []

        dictExpr.content.as(DictionaryElementListSyntax.self)?.forEach { element in
            // keyExpression과 valueExpression에 대해 타입 추론
            keyTypes.insert(inferExprSyntax(element.key))
            valueTypes.insert(inferExprSyntax(element.value))
        }

        // 키 타입과 값 타입이 하나만 있으면 해당 타입을 사용, 아니면 Any
        let keyType: String
        if let firstType = keyTypes.first, keyTypes.allSatisfy({ $0 == firstType }) {
            keyType = firstType
        } else {
            keyType = "AnyHashable"
        }

        let valueType: String
        if let firstType = valueTypes.first, valueTypes.allSatisfy({ $0 == firstType }) {
            valueType = firstType
        } else {
            valueType = "Any"
        }

        return "[\(keyType): \(valueType)]"
    }

    private static func inferTupleExprSyntax(_ expr: ExprSyntax) -> String {
        guard let tupleExpr = expr.as(TupleExprSyntax.self) else { return "(name: tuple, type: Any)" }

        let elementTypes = tupleExpr.elements.map { element -> String in
            if let name = element.label?.text, !name.isEmpty {
                return "\(name)\(element.colon?.text ?? ":") \(inferExprSyntax(element.expression))"
            }
            else {
                return inferExprSyntax(element.expression)
            }
        }

        return "(\(elementTypes.joined(separator: ", ")))"
    }

    private static func inferFunctionCallExprSyntax(_ expr: ExprSyntax) -> String {
        guard let funcExpr = expr.as(FunctionCallExprSyntax.self) else { return "FunctionCallExprSyntax none" }
        return funcExpr.calledExpression.description
    }

    private static func inferClosureExprSyntax(_ expr: ExprSyntax) -> String {
        guard let cloExpr = expr.as(ClosureExprSyntax.self) else { return "ClosureExprSyntax none" }
        guard let signature = cloExpr.signature else { return "@escaping () -> ()" }

        var result = ""
        if let parameterClause = signature.parameterClause?.as(ClosureParameterClauseSyntax.self) {
            result = parameterClause.leftParen.text
            let types = parameterClause.parameters.compactMap { parameter in
                inferTypeSyntax(parameter.type) 
            }
            result += types.joined(separator: ", ")
            result += parameterClause.rightParen.text
        }
        if let returnClause = signature.returnClause {
            result += "\(returnClause.arrow.text) "
            let type = inferTypeSyntax(returnClause.type)
            if !type.isEmpty {
                result += type
            }
            else {
                result += "()"
            }
        }
        else {
            result += "-> ()"
        }
        return "@escaping \(result)"
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
