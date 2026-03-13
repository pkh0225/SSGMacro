//
//  MacroError.swift
//  SSGMacro
//
//  Created by 박길호(팀원) - D/I개발담당App개발팀 on 3/12/26.
//

enum MacroError: Error, CustomStringConvertible {
    case message(String)
    var description: String { switch self { case .message(let m): return m } }
}

public protocol OptionalProtocol {
    var isNil: Bool { get }
}

extension Optional: OptionalProtocol {
    public var isNil: Bool { self == nil }
}
