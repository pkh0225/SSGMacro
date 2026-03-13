//
//  UserDefaultMacroImpl.swift
//  SSGMacro
//
//  Created by 박길호(팀원) - D/I개발담당App개발팀 on 3/12/26.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

public struct UserDefaultMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {

        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            throw MacroError.message("@UserDefault는 var 프로퍼티에만 사용 가능합니다")
        }

        let propertyName = identifier.identifier.text

        guard let typeAnnotation = binding.typeAnnotation else {
            throw MacroError.message("@UserDefault는 타입 어노테이션이 필요합니다: var \(propertyName): Type")
        }

        guard case .argumentList(let args) = node.arguments else {
            throw MacroError.message("@UserDefault 인자를 파싱할 수 없습니다")
        }

        let argDict = Dictionary(
            uniqueKeysWithValues: args.compactMap { arg -> (String, String)? in
                guard let label = arg.label?.text else { return nil }
                return (label, arg.expression.description)
            }
        )

        guard let key = argDict["key"] else {
            throw MacroError.message("key 인자가 필요합니다")
        }

        let groupID = argDict["groupID"]

        let defaultValue: String
        if let initializer = binding.initializer {
            defaultValue = initializer.value.description
        }
        else {
            defaultValue = "nil"
        }

        let typeName = typeAnnotation.type.description.trimmingCharacters(in: .whitespaces)

        // ✅ Optional 타입이면 ? 제거해서 캐스팅에 사용
        let castTypeName = typeName.hasSuffix("?") ? String(typeName.dropLast()) : typeName

        let userDefaultInit: String
        if let groupID = groupID {
            userDefaultInit = "let userDefault = UserDefaults(suiteName: \(groupID)) ?? .standard"
        }
        else {
            userDefaultInit = "let userDefault = UserDefaults.standard"
        }

        let getter: AccessorDeclSyntax = """
        get {
            \(raw: userDefaultInit)
            return userDefault.object(forKey: \(raw: key)) as? \(raw: castTypeName) ?? \(raw: defaultValue)
        }
        """

        let isOptionalType = typeName.hasSuffix("?")

        let setter: AccessorDeclSyntax
        if isOptionalType {
            setter = """
            set {
                \(raw: userDefaultInit)
                if newValue == nil {
                    userDefault.removeObject(forKey: \(raw: key))
                }
                else {
                    userDefault.set(newValue, forKey: \(raw: key))
                }
            }
            """
        }
        else {
            // non-optional은 nil이 될 수 없으므로 바로 set
            setter = """
            set {
                \(raw: userDefaultInit)
                userDefault.set(newValue, forKey: \(raw: key))
            }
            """
        }

        return [getter, setter]
    }
}
