//
//  UserDefaultMacro.swift
//  SSGMacro
//
//  Created by 박길호(팀원) - D/I개발담당App개발팀 on 3/12/26.
//

import Foundation

/// UserDefaults 접근을 자동으로 생성하는 매크로
/// - Parameters:
///   - key: UserDefaults 저장 키
///   - groupID: App Group ID (없으면 UserDefaults.standard 사용)
@attached(accessor, names: named(get), named(set))
public macro UserDefault(
    key: String,
    groupID: String? = nil
) = #externalMacro(module: "SSGMacroMacros", type: "UserDefaultMacro")
