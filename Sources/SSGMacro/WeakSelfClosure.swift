// The Swift Programming Language
// https://docs.swift.org/swift-book

@freestanding(expression)
public macro WeakSelfClosure<each P>(
    _ closure: (repeat each P) -> Void
) -> (repeat each P) -> Void = #externalMacro(module: "SSGMacroMacros", type: "WeakSelfClosure")
