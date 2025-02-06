import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(SSGMacroMacros)
import SSGMacroMacros

let testMacros: [String: Macro.Type] = [
    "WeakSelfClosure": WeakSelfClosure.self,
    "fluentSetterMacro": FluentSetterMacro.self
]
#endif

final class MyMacroTests: XCTestCase {

    func testEnumFluentSetterMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            @fluentSetterMacro()
            class TestClass {
                var aaa: CGRect // 주석
            }
            """,
            expandedSource: """
            class TestClass {
                var aaa: CGRect // 주석
            
                func aaa(_ value: CGRect) -> Self {
                    self.aaa = value
                    return self
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testCGFloatFluentSetterMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            @fluentSetterMacro()
            class TestClass {
                var aaa = 0.1 // 주석
                var bbb = CGFloat(0.1) // 주석
                var ccc = Double(0.1) // 주석
            }
            """,
            expandedSource: """
            class TestClass {
                var aaa = 0.1 // 주석
                var bbb = CGFloat(0.1) // 주석
                var ccc = Double(0.1) // 주석
            
                func aaa(_ value: CGFloat) -> Self {
                    self.aaa = value
                    return self
                }

                func bbb(_ value: CGFloat) -> Self {
                    self.bbb = value
                    return self
                }
            
                func ccc(_ value: Double) -> Self {
                    self.ccc = value
                    return self
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }


    func testTypeMarkFluentSetterMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            @fluentSetterMacro()
            class TestClass {
                var aaa: Int // 주석
                var bbb: Int! // 주석
                var ccc: Int? // 주석
            }
            """,
            expandedSource: """
            class TestClass {
                var aaa: Int // 주석
                var bbb: Int! // 주석
                var ccc: Int? // 주석

                func aaa(_ value: Int) -> Self {
                    self.aaa = value
                    return self
                }

                func bbb(_ value: Int) -> Self {
                    self.bbb = value
                    return self
                }

                func ccc(_ value: Int?) -> Self {
                    self.ccc = value
                    return self
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testSequenceFluentSetterMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            @fluentSetterMacro()
            class TestClass {
                var mixedArray = [1, "text", true] as [Any]  // 혼합된 타입 배열
            }
            """,
            expandedSource: """
            class TestClass {
                var mixedArray = [1, "text", true] as [Any]  // 혼합된 타입 배열

                func mixedArray(_ value: [Any]) -> Self {
                    self.mixedArray = value
                    return self
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testExceptionFluentSetterMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            @fluentSetterMacro()
            class TestClass {
                // 제외되어야 하는 속성  
                static var sss: String = ""
                
                let xxx: Double = 0.0
                private var yyy: Int = 1
                lazy var zzz: Int = {
                    return 1
                }()
                var ggg: Int {
                    return aaa
                }
            
                // 나와야 하는 속성
                var aaa: Int = 1 // 주석
            }
            """,
            expandedSource: """
            class TestClass {
                // 제외되어야 하는 속성  
                static var sss: String = ""
                
                let xxx: Double = 0.0
                private var yyy: Int = 1
                lazy var zzz: Int = {
                    return 1
                }()
                var ggg: Int {
                    return aaa
                }

                // 나와야 하는 속성
                var aaa: Int = 1 // 주석

                func aaa(_ value: Int) -> Self {
                    self.aaa = value
                    return self
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testClosuerFluentSetterMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            @fluentSetterMacro()
            class TestClass {
                var closuer: ((Int) -> String)? // 주석
                var closuer2: ((Int) -> String)! // 주석
                var closuer3: ((Int) -> String) // 주석
            
                var closure4 = { (v: Int) -> String in
                    return "123"
                }
                var closure5 = { () -> String in
                    return "123"
                }
                var closure6 = { (v: Int) in
                    print("123")
                }
                var closure7 = { (v: Int) -> (String) in
                    return "123"
                }
                var closure8 = { (v: Int, v2: String) -> (String) in
                    return "123"
                }
                var closure9 = { () in
                    print("123")
                }
                var closure10 = {
                    print("123")
                }
                var closure11 = { () -> String? in
                    return "123"
                }
                var closure12 = { (v: Int?) in
                    print("123")
                }
            }
            """,
            expandedSource: """
            class TestClass {
                var closuer: ((Int) -> String)? // 주석
                var closuer2: ((Int) -> String)! // 주석
                var closuer3: ((Int) -> String) // 주석

                var closure4 = { (v: Int) -> String in
                    return "123"
                }
                var closure5 = { () -> String in
                    return "123"
                }
                var closure6 = { (v: Int) in
                    print("123")
                }
                var closure7 = { (v: Int) -> (String) in
                    return "123"
                }
                var closure8 = { (v: Int, v2: String) -> (String) in
                    return "123"
                }
                var closure9 = { () in
                    print("123")
                }
                var closure10 = {
                    print("123")
                }
                var closure11 = { () -> String? in
                    return "123"
                }
                var closure12 = { (v: Int?) in
                    print("123")
                }

                func closuer(_ value: ((Int) -> String)?) -> Self {
                    self.closuer = value
                    return self
                }

                func closuer2(_ value: @escaping ((Int) -> String)) -> Self {
                    self.closuer2 = value
                    return self
                }

                func closuer3(_ value: ((Int) -> String)) -> Self {
                    self.closuer3 = value
                    return self
                }

                func closure4(_ value: @escaping (Int) -> String) -> Self {
                    self.closure4 = value
                    return self
                }

                func closure5(_ value: @escaping () -> String) -> Self {
                    self.closure5 = value
                    return self
                }

                func closure6(_ value: @escaping (Int) -> ()) -> Self {
                    self.closure6 = value
                    return self
                }

                func closure7(_ value: @escaping (Int) -> (String)) -> Self {
                    self.closure7 = value
                    return self
                }

                func closure8(_ value: @escaping (Int, String) -> (String)) -> Self {
                    self.closure8 = value
                    return self
                }

                func closure9(_ value: @escaping () -> ()) -> Self {
                    self.closure9 = value
                    return self
                }

                func closure10(_ value: @escaping () -> ()) -> Self {
                    self.closure10 = value
                    return self
                }

                func closure11(_ value: @escaping () -> String?) -> Self {
                    self.closure11 = value
                    return self
                }

                func closure12(_ value: @escaping (Int?) -> ()) -> Self {
                    self.closure12 = value
                    return self
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testTupleFluentSetterMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            @fluentSetterMacro()
            class TestClass {
                var tuple: (Int, String) = (123, "123") // 주석
                var tuple2: (Int, String)? // 주석
                var tuple3: (count: Int, name: String)? // 주석
                var tuple4 = (123, "123") // 주석
                var tuple5 = (name1: 123, name2: "123") // 주석
            }
            """,
            expandedSource: """
            class TestClass {
                var tuple: (Int, String) = (123, "123") // 주석
                var tuple2: (Int, String)? // 주석
                var tuple3: (count: Int, name: String)? // 주석
                var tuple4 = (123, "123") // 주석
                var tuple5 = (name1: 123, name2: "123") // 주석

                func tuple(_ value: (Int, String)) -> Self {
                    self.tuple = value
                    return self
                }

                func tuple2(_ value: (Int, String)?) -> Self {
                    self.tuple2 = value
                    return self
                }

                func tuple3(_ value: (count: Int, name: String)?) -> Self {
                    self.tuple3 = value
                    return self
                }
            
                func tuple4(_ value: (Int, String)) -> Self {
                    self.tuple4 = value
                    return self
                }
            
                func tuple5(_ value: (name1: Int, name2: String)) -> Self {
                    self.tuple5 = value
                    return self
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDictionaryFluentSetterMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            @fluentSetterMacro()
            class TestClass {
                var dic = Dictionary<String, Int>()  // 타입이 명시된 빈 딕셔너리
                var dic2 = [String: Int]()  // 타입이 명시된 빈 딕셔너리
                var dic3: [String: Int] = [:]  // 타입이 명시된 빈 딕셔너리
                var dic4 = ["key1": 1, "key2": 2]  // 초기화 값 기반 타입 추론
                var dic5 = ["key1": 1, 123: "2"]  // 초기화 값 기반 타입 추론
            }
            """,
            expandedSource: """
            class TestClass {
                var dic = Dictionary<String, Int>()  // 타입이 명시된 빈 딕셔너리
                var dic2 = [String: Int]()  // 타입이 명시된 빈 딕셔너리
                var dic3: [String: Int] = [:]  // 타입이 명시된 빈 딕셔너리
                var dic4 = ["key1": 1, "key2": 2]  // 초기화 값 기반 타입 추론
                var dic5 = ["key1": 1, 123: "2"]  // 초기화 값 기반 타입 추론

                func dic(_ value: Dictionary<String, Int>) -> Self {
                    self.dic = value
                    return self
                }

                func dic2(_ value: [String: Int]) -> Self {
                    self.dic2 = value
                    return self
                }

                func dic3(_ value: [String: Int]) -> Self {
                    self.dic3 = value
                    return self
                }

                func dic4(_ value: [String: Int]) -> Self {
                    self.dic4 = value
                    return self
                }

                func dic5(_ value: [AnyHashable: Any]) -> Self {
                    self.dic5 = value
                    return self
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testStructFluentSetterMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            @fluentSetterMacro()
            struct TestStruct {
                var typeAny: Any? // 주석
                var viewType: StructSample.Type? // 주석
                var actoinClass: ActoinClass? // 주석
                var actoinClass2 = StructSample() // 주석
            }
            """,
            expandedSource: """
            struct TestStruct {
                var typeAny: Any? // 주석
                var viewType: StructSample.Type? // 주석
                var actoinClass: ActoinClass? // 주석
                var actoinClass2 = StructSample() // 주석

                func typeAny(_ value: Any?) -> Self {
                    var copy = self
                    copy.typeAny = value
                    return copy
                }

                func viewType(_ value: StructSample.Type?) -> Self {
                    var copy = self
                    copy.viewType = value
                    return copy
                }

                func actoinClass(_ value: ActoinClass?) -> Self {
                    var copy = self
                    copy.actoinClass = value
                    return copy
                }

                func actoinClass2(_ value: StructSample) -> Self {
                    var copy = self
                    copy.actoinClass2 = value
                    return copy
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testClassFluentSetterMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            @fluentSetterMacro()
            class TestClass {
                var typeAny: Any? // 주석
                var viewType: StructSample.Type? // 주석
                var actoinClass: ActoinClass? // 주석
                var actoinClass2 = StructSample() // 주석
            }
            """,
            expandedSource: """
            class TestClass {
                var typeAny: Any? // 주석
                var viewType: StructSample.Type? // 주석
                var actoinClass: ActoinClass? // 주석
                var actoinClass2 = StructSample() // 주석

                func typeAny(_ value: Any?) -> Self {
                    self.typeAny = value
                    return self
                }

                func viewType(_ value: StructSample.Type?) -> Self {
                    self.viewType = value
                    return self
                }

                func actoinClass(_ value: ActoinClass?) -> Self {
                    self.actoinClass = value
                    return self
                }

                func actoinClass2(_ value: StructSample) -> Self {
                    self.actoinClass2 = value
                    return self
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testArrayFluentSetterMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            @fluentSetterMacro()
            class TestClass {
                var array = Array<Int>()// 타입이 명시된 빈 배열
                var array1 = [Int]() // 타입이 명시된 빈 배열
                var array2: [String] = []  // 타입이 명시된 빈 배열
                var array3 = [1, 2, 3]  // 초기화 값 기반 타입 추론
                var mixedArray2 = [Any]()  // 혼합된 타입 배열
            }
            """,
            expandedSource: """
            class TestClass {
                var array = Array<Int>()// 타입이 명시된 빈 배열
                var array1 = [Int]() // 타입이 명시된 빈 배열
                var array2: [String] = []  // 타입이 명시된 빈 배열
                var array3 = [1, 2, 3]  // 초기화 값 기반 타입 추론
                var mixedArray2 = [Any]()  // 혼합된 타입 배열

                func array(_ value: Array<Int>) -> Self {
                    self.array = value
                    return self
                }

                func array1(_ value: [Int]) -> Self {
                    self.array1 = value
                    return self
                }

                func array2(_ value: [String]) -> Self {
                    self.array2 = value
                    return self
                }

                func array3(_ value: [Int]) -> Self {
                    self.array3 = value
                    return self
                }

                func mixedArray2(_ value: [Any]) -> Self {
                    self.mixedArray2 = value
                    return self
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testBoolFluentSetterMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            @fluentSetterMacro()
            class TestClass {
                var aaa: Bool = true // 주석
                var aaa2: Bool? // 주석
                var aaa3 = false // 주석
            }
            """,
            expandedSource: """
            class TestClass {
                var aaa: Bool = true // 주석
                var aaa2: Bool? // 주석
                var aaa3 = false // 주석

                func aaa(_ value: Bool) -> Self {
                    self.aaa = value
                    return self
                }

                func aaa2(_ value: Bool?) -> Self {
                    self.aaa2 = value
                    return self
                }

                func aaa3(_ value: Bool) -> Self {
                    self.aaa3 = value
                    return self
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testStringFluentSetterMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            @fluentSetterMacro()
            class TestClass {
                var aaa: String = "123" // 주석
                var aaa2: String? // 주석
                var aaa3 = "123" // 주석
            }
            """,
            expandedSource: """
            class TestClass {
                var aaa: String = "123" // 주석
                var aaa2: String? // 주석
                var aaa3 = "123" // 주석

                func aaa(_ value: String) -> Self {
                    self.aaa = value
                    return self
                }

                func aaa2(_ value: String?) -> Self {
                    self.aaa2 = value
                    return self
                }

                func aaa3(_ value: String) -> Self {
                    self.aaa3 = value
                    return self
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDoubleFluentSetterMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            @fluentSetterMacro()
            class TestClass {
                var aaa: Double = 1 // 주석
                var aaa2: Double? // 주석
                var aaa3 = 1.0 // 주석
            }
            """,
            expandedSource: """
            class TestClass {
                var aaa: Double = 1 // 주석
                var aaa2: Double? // 주석
                var aaa3 = 1.0 // 주석

                func aaa(_ value: Double) -> Self {
                    self.aaa = value
                    return self
                }

                func aaa2(_ value: Double?) -> Self {
                    self.aaa2 = value
                    return self
                }

                func aaa3(_ value: CGFloat) -> Self {
                    self.aaa3 = value
                    return self
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testIntFluentSetterMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            @fluentSetterMacro()
            class TestClass {
                var aaa: Int = 1 // 주석
                var aaa2: Int? // 주석
                var aaa3 = 1 // 주석
            }
            """,
            expandedSource: """
            class TestClass {
                var aaa: Int = 1 // 주석
                var aaa2: Int? // 주석
                var aaa3 = 1 // 주석

                func aaa(_ value: Int) -> Self {
                    self.aaa = value
                    return self
                }

                func aaa2(_ value: Int?) -> Self {
                    self.aaa2 = value
                    return self
                }

                func aaa3(_ value: Int) -> Self {
                    self.aaa3 = value
                    return self
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testPublicFluentSetterMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            @fluentSetterMacro("public")
            class TestClass {
                var aaa = 1 // 주석
            }
            """,
            expandedSource: """
            class TestClass {
                var aaa = 1 // 주석

                public func aaa(_ value: Int) -> Self {
                    self.aaa = value
                    return self
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testWeaSelfMacro() throws {
        #if canImport(SSGMacroMacros)
        assertMacroExpansion(
            """
            let action = #WeakSelfClosure {
                print("run")
            }
            """,
            expandedSource: """
            let action = { [weak self] in
                guard let self else {
                    return
                }
                    print("run")
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
