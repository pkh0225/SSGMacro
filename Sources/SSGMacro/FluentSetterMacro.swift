// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: arbitrary)
public macro fluentSetterMacro(_ accessModifier: String = "") = #externalMacro(module: "SSGMacroMacros", type: "FluentSetterMacro")

