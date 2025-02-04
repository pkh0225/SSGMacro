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
                var aaa: Int = 1
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
                var aaa: Int = 1

                func aaa(_ value: Int ) -> Self {
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
                var closuer: ((Int) -> String)?
            }
            """,
            expandedSource: """
            class TestClass {
                var closuer: ((Int) -> String)?

                func closuer(_ value: ((Int) -> String)?) -> Self {
                    self.closuer = value
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
                var tuple: (Int, String) = (123, "123")
                var tuple2: (Int, String)?
                var tuple3: (count: Int, name: String)?
                var tuple4 = (123, "123")
                var tuple5 = (name1: 123, name2: "123")
            }
            """,
            expandedSource: """
            class TestClass {
                var tuple: (Int, String) = (123, "123")
                var tuple2: (Int, String)?
                var tuple3: (count: Int, name: String)?
                var tuple4 = (123, "123")
                var tuple5 = (name1: 123, name2: "123")

                func tuple(_ value: (Int, String) ) -> Self {
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
            }
            """,
            expandedSource: """
            class TestClass {
                var dic = Dictionary<String, Int>()  // 타입이 명시된 빈 딕셔너리
                var dic2 = [String: Int]()  // 타입이 명시된 빈 딕셔너리
                var dic3: [String: Int] = [:]  // 타입이 명시된 빈 딕셔너리
                var dic4 = ["key1": 1, "key2": 2]  // 초기화 값 기반 타입 추론

                func dic(_ value: Dictionary<String, Int>) -> Self {
                    self.dic = value
                    return self
                }

                func dic2(_ value: [String: Int]) -> Self {
                    self.dic2 = value
                    return self
                }

                func dic3(_ value: [String: Int] ) -> Self {
                    self.dic3 = value
                    return self
                }

                func dic4(_ value: [String: Int]) -> Self {
                    self.dic4 = value
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
                var typeAny: Any?
                var viewType: StructSample.Type?
                var actoinClass: ActoinClass?
                var actoinClass2 = StructSample()
            }
            """,
            expandedSource: """
            struct TestStruct {
                var typeAny: Any?
                var viewType: StructSample.Type?
                var actoinClass: ActoinClass?
                var actoinClass2 = StructSample()

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
                var typeAny: Any?
                var viewType: StructSample.Type?
                var actoinClass: ActoinClass?
                var actoinClass2 = StructSample()
            }
            """,
            expandedSource: """
            class TestClass {
                var typeAny: Any?
                var viewType: StructSample.Type?
                var actoinClass: ActoinClass?
                var actoinClass2 = StructSample()

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
                var array = Array<Int>()   // 타입이 명시된 빈 배열
                var array1 = [Int]()   // 타입이 명시된 빈 배열
                var array2: [String] = []  // 타입이 명시된 빈 배열
                var array3 = [1, 2, 3]  // 초기화 값 기반 타입 추론
            //    var mixedArray = [1, "text", true] as [Any]  // 혼합된 타입 배열 지원하지 않음
                var mixedArray2 = [Any]()  // 혼합된 타입 배열
            }
            """,
            expandedSource: """
            class TestClass {
                var array = Array<Int>()   // 타입이 명시된 빈 배열
                var array1 = [Int]()   // 타입이 명시된 빈 배열
                var array2: [String] = []  // 타입이 명시된 빈 배열
                var array3 = [1, 2, 3]  // 초기화 값 기반 타입 추론
            //    var mixedArray = [1, "text", true] as [Any]  // 혼합된 타입 배열 지원하지 않음
                var mixedArray2 = [Any]()  // 혼합된 타입 배열

                func array(_ value: Array<Int>) -> Self {
                    self.array = value
                    return self
                }

                func array1(_ value: [Int]) -> Self {
                    self.array1 = value
                    return self
                }

                func array2(_ value: [String] ) -> Self {
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
                var aaa: Bool = true
                var aaa2: Bool?
                var aaa3 = false
            }
            """,
            expandedSource: """
            class TestClass {
                var aaa: Bool = true
                var aaa2: Bool?
                var aaa3 = false

                func aaa(_ value: Bool ) -> Self {
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
                var aaa: String = "123"
                var aaa2: String?
                var aaa3 = "123"
            }
            """,
            expandedSource: """
            class TestClass {
                var aaa: String = "123"
                var aaa2: String?
                var aaa3 = "123"

                func aaa(_ value: String ) -> Self {
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
                var aaa: Double = 1
                var aaa2: Double?
                var aaa3 = 1.0
            }
            """,
            expandedSource: """
            class TestClass {
                var aaa: Double = 1
                var aaa2: Double?
                var aaa3 = 1.0

                func aaa(_ value: Double ) -> Self {
                    self.aaa = value
                    return self
                }

                func aaa2(_ value: Double?) -> Self {
                    self.aaa2 = value
                    return self
                }

                func aaa3(_ value: Double) -> Self {
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
                var aaa: Int = 1
                var aaa2: Int?
                var aaa3 = 1
            }
            """,
            expandedSource: """
            class TestClass {
                var aaa: Int = 1
                var aaa2: Int?
                var aaa3 = 1

                func aaa(_ value: Int ) -> Self {
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
                var aaa = 1
            }
            """,
            expandedSource: """
            class TestClass {
                var aaa = 1

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
