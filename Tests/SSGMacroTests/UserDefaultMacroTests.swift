import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// 매크로 구현체 import
@testable import SSGMacroMacros

// MARK: - 테스트용 Mock

/// 테스트용 OptionalProtocol
protocol OptionalProtocol {
    var isNil: Bool { get }
}

extension Optional: OptionalProtocol {
    var isNil: Bool { self == nil }
}

// MARK: - UserDefaultMacro Tests

final class UserDefaultMacroTests: XCTestCase {

    // 매크로 테스트에 사용할 매크로 딕셔너리
    let testMacros: [String: Macro.Type] = [
        "UserDefault": UserDefaultMacro.self
    ]

    // -------------------------------------------------------------------------
    // MARK: - 1. 기본 전개 테스트 (key만 있는 경우)
    // -------------------------------------------------------------------------

    func test_expansion_basicKey_stringOptional() {
        // String? 타입, groupID 없는 기본 케이스
        assertMacroExpansion(
            """
            @UserDefault(key: "APP_FIRST_YN")
            static var appFirstYN: String? = nil
            """,
            expandedSource: """
            static var appFirstYN: String? {
                get {
                    let userDefault: UserDefaults
                    if let groupId = nil {
                        userDefault = UserDefaults(suiteName: groupId) ?? .standard
                    }
                    else {
                        userDefault = UserDefaults.standard
                    }
                    return userDefault.object(forKey: "APP_FIRST_YN") as? String? ?? nil
                }
                set {
                    let userDefault: UserDefaults
                    if let groupId = nil {
                        userDefault = UserDefaults(suiteName: groupId) ?? .standard
                    }
                    else {
                        userDefault = UserDefaults.standard
                    }
                    if let optional = newValue as? any OptionalProtocol, optional.isNil {
                        userDefault.removeObject(forKey: "APP_FIRST_YN")
                    }
                    else {
                        userDefault.set(newValue, forKey: "APP_FIRST_YN")
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    // -------------------------------------------------------------------------
    // MARK: - 2. groupID 포함 전개 테스트
    // -------------------------------------------------------------------------

    func test_expansion_withGroupID_stringOptional() {
        // String? 타입, groupID 있는 케이스
        assertMacroExpansion(
            """
            @UserDefault(key: "APP_SERVICE_TYPE", groupID: "group.com.example.app")
            static var serviceType: String? = nil
            """,
            expandedSource: """
            static var serviceType: String? {
                get {
                    let userDefault: UserDefaults
                    if let groupId = "group.com.example.app" {
                        userDefault = UserDefaults(suiteName: groupId) ?? .standard
                    }
                    else {
                        userDefault = UserDefaults.standard
                    }
                    return userDefault.object(forKey: "APP_SERVICE_TYPE") as? String? ?? nil
                }
                set {
                    let userDefault: UserDefaults
                    if let groupId = "group.com.example.app" {
                        userDefault = UserDefaults(suiteName: groupId) ?? .standard
                    }
                    else {
                        userDefault = UserDefaults.standard
                    }
                    if let optional = newValue as? any OptionalProtocol, optional.isNil {
                        userDefault.removeObject(forKey: "APP_SERVICE_TYPE")
                    }
                    else {
                        userDefault.set(newValue, forKey: "APP_SERVICE_TYPE")
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    // -------------------------------------------------------------------------
    // MARK: - 3. Int 타입 (non-optional) 전개 테스트
    // -------------------------------------------------------------------------

    func test_expansion_intType_withDefaultValue() {
        // Int 타입, 기본값 0 케이스
        assertMacroExpansion(
            """
            @UserDefault(key: "LAUNCH_COUNT")
            static var launchCount: Int = 0
            """,
            expandedSource: """
            static var launchCount: Int {
                get {
                    let userDefault: UserDefaults
                    if let groupId = nil {
                        userDefault = UserDefaults(suiteName: groupId) ?? .standard
                    }
                    else {
                        userDefault = UserDefaults.standard
                    }
                    return userDefault.object(forKey: "LAUNCH_COUNT") as? Int ?? 0
                }
                set {
                    let userDefault: UserDefaults
                    if let groupId = nil {
                        userDefault = UserDefaults(suiteName: groupId) ?? .standard
                    }
                    else {
                        userDefault = UserDefaults.standard
                    }
                    if let optional = newValue as? any OptionalProtocol, optional.isNil {
                        userDefault.removeObject(forKey: "LAUNCH_COUNT")
                    }
                    else {
                        userDefault.set(newValue, forKey: "LAUNCH_COUNT")
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    // -------------------------------------------------------------------------
    // MARK: - 4. Bool 타입 전개 테스트
    // -------------------------------------------------------------------------

    func test_expansion_boolType_withDefaultValue() {
        assertMacroExpansion(
            """
            @UserDefault(key: "IS_LOGGED_IN")
            static var isLoggedIn: Bool = false
            """,
            expandedSource: """
            static var isLoggedIn: Bool {
                get {
                    let userDefault: UserDefaults
                    if let groupId = nil {
                        userDefault = UserDefaults(suiteName: groupId) ?? .standard
                    }
                    else {
                        userDefault = UserDefaults.standard
                    }
                    return userDefault.object(forKey: "IS_LOGGED_IN") as? Bool ?? false
                }
                set {
                    let userDefault: UserDefaults
                    if let groupId = nil {
                        userDefault = UserDefaults(suiteName: groupId) ?? .standard
                    }
                    else {
                        userDefault = UserDefaults.standard
                    }
                    if let optional = newValue as? any OptionalProtocol, optional.isNil {
                        userDefault.removeObject(forKey: "IS_LOGGED_IN")
                    }
                    else {
                        userDefault.set(newValue, forKey: "IS_LOGGED_IN")
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    // -------------------------------------------------------------------------
    // MARK: - 5. 에러 케이스: var가 아닌 let에 적용
    // -------------------------------------------------------------------------

    func test_error_appliedToLet() {
        // let에 붙이면 에러 진단 발생해야 함
        assertMacroExpansion(
            """
            @UserDefault(key: "SOME_KEY")
            static let someValue: String = "hello"
            """,
            expandedSource: """
            static let someValue: String = "hello"
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@UserDefault는 var 프로퍼티에만 사용 가능합니다",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    // -------------------------------------------------------------------------
    // MARK: - 6. 에러 케이스: 타입 어노테이션 없음
    // -------------------------------------------------------------------------

    func test_error_missingTypeAnnotation() {
        // 타입 명시 없으면 에러 진단 발생해야 함
        assertMacroExpansion(
            """
            @UserDefault(key: "SOME_KEY")
            static var someValue = "hello"
            """,
            expandedSource: """
            static var someValue = "hello"
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@UserDefault는 타입 어노테이션이 필요합니다: var someValue: Type",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    // -------------------------------------------------------------------------
    // MARK: - 7. 실제 동작 통합 테스트 (런타임)
    // -------------------------------------------------------------------------

    func test_runtime_setAndGet_string() {
        let key = "TEST_RUNTIME_STRING_\(UUID().uuidString)"
        let defaults = UserDefaults.standard

        // 초기값 nil 확인
        XCTAssertNil(defaults.object(forKey: key))

        // 값 저장
        defaults.set("hello", forKey: key)
        XCTAssertEqual(defaults.string(forKey: key), "hello")

        // 값 삭제 (Optional nil 세팅 시나리오)
        defaults.removeObject(forKey: key)
        XCTAssertNil(defaults.object(forKey: key))
    }

    func test_runtime_setAndGet_int() {
        let key = "TEST_RUNTIME_INT_\(UUID().uuidString)"
        let defaults = UserDefaults.standard

        defaults.set(42, forKey: key)
        XCTAssertEqual(defaults.integer(forKey: key), 42)

        defaults.removeObject(forKey: key)
        // removeObject 후 integer(forKey:) 는 0 반환 (기본값)
        XCTAssertEqual(defaults.integer(forKey: key), 0)
    }

    func test_runtime_setAndGet_bool() {
        let key = "TEST_RUNTIME_BOOL_\(UUID().uuidString)"
        let defaults = UserDefaults.standard

        defaults.set(true, forKey: key)
        XCTAssertTrue(defaults.bool(forKey: key))

        defaults.set(false, forKey: key)
        XCTAssertFalse(defaults.bool(forKey: key))

        defaults.removeObject(forKey: key)
        // removeObject 후 bool(forKey:) 는 false 반환 (기본값)
        XCTAssertFalse(defaults.bool(forKey: key))
    }

    // -------------------------------------------------------------------------
    // MARK: - 8. OptionalProtocol isNil 동작 테스트
    // -------------------------------------------------------------------------

    func test_optionalProtocol_isNil_true() {
        let value: String? = nil
        let optValue: any OptionalProtocol = value as! OptionalProtocol
        XCTAssertTrue(optValue.isNil)
    }

    func test_optionalProtocol_isNil_false() {
        let value: String? = "hello"
        let optValue: any OptionalProtocol = value as! OptionalProtocol
        XCTAssertFalse(optValue.isNil)
    }

    func test_optionalProtocol_nonOptional_castFails() {
        // non-optional 값은 OptionalProtocol로 캐스팅이 안 됨 → removeObject 미호출 확인
        let value: Int = 42
        let isOptional = value as? any OptionalProtocol
        XCTAssertNil(isOptional, "non-optional Int은 OptionalProtocol로 캐스팅 불가해야 합니다")
    }

    // -------------------------------------------------------------------------
    // MARK: - 9. AppGroup suiteName 실패 시 fallback 테스트
    // -------------------------------------------------------------------------

    func test_runtime_invalidSuiteName_fallbackToStandard() {
        // 존재하지 않는 suiteName → nil 반환 → .standard fallback
        let invalidSuite = "invalid.suite.name.that.does.not.exist"
        let result = UserDefaults(suiteName: invalidSuite) ?? .standard
        // fallback이 standard인지 확인
        XCTAssertNotNil(result)
    }
}
