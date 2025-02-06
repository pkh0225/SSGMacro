import SSGMacro
import Foundation

@fluentSetterMacro("public")
class ActoinClass {
    var cgFloat: CGFloat = 0

    var aaa = 1
    var aaa2: Int?
    var bbb: Int = 0
    var ccc = ""
    var ccc2: String?
    var ccc3: String = ""
    var ddd: Bool = false
    var ddd2 = false

    var array = Array<Int>()   // 타입이 명시된 빈 배열
    var array1 = [Int]()   // 타입이 명시된 빈 배열
    var array2: [String] = []  // 타입이 명시된 빈 배열
    var array3 = [1, 2, 3]  // 초기화 값 기반 타입 추론
    var mixedArray = [1, "text", true] as [Any]  // 혼합된 타입 배열
    var mixedArray2 = [Any]()  // 혼합된 타입 배열

    var dic = Dictionary<String, Int>()  // 타입이 명시된 빈 딕셔너리
    var dic2 = [String: Int]()  // 타입이 명시된 빈 딕셔너리
    var dic3: [String: Int] = [:]  // 타입이 명시된 빈 딕셔너리
    var dic4 = ["key1": 123, "key2": 123]  // 초기화 값 기반 타입 추론


    var tuple: (Int, String) = (123, "123")
    var tuple2: (Int, String)?
    var tuple3: (count: Int, name: String)?
    var tuple4 = (123, "123")
    var tuple5 = (name1: 123, name2: "123")

    var action: ((Int) -> Void)?
    var action2: ((Int, String) -> String?)?
    var closure = { (value: Int) -> String in
        return "\(value)"
    }

    var closuer2: ((Int) -> String)! // 주석

    var typeAny: Any?
    var viewType: StructSample.Type?
    var actoinClass: ActoinClass?
    var actoinClass2 = StructSample()


    // 제외되어야 하는 속성
    let xxx: Double = 0.0
    private var yyy: Int = 1
    lazy var zzz: Int = {
        return 1
    }()
    var ggg: Int {
        return aaa
    }

    static var sss: String = ""


    func run1() {
        self.action?(123)
    }

    func run2() {
        self.action = #WeakSelfClosure { value in
            print(self.aaa + value)
        }
        self.action?(123)
    }

}

var actionClass = ActoinClass()
    .aaa(555)
    .ccc("123")
    .ccc2("123")
    .action { value in
        print(value)
    }
    .array([1, 2, 3])
    .tuple4((123, "123"))

actionClass.run1()
actionClass.run2()
print("11")




@fluentSetterMacro("public")
struct StructSample {
    var first: Bool = false
    var second: String = ""
    var action: (() -> Void)?
    var ppp: (Int, String) = (123, "")



    // 제외되어야 하는 속성
    let yyy: Double = 0
    private var aaa: Int = 1
    lazy var bbb: Int = 1
    var ccc: Int {
        return aaa
    }


}

let sample2 = StructSample()
    .first(true)
    .second("Hello")
    .ppp((555, "555"))

print("firstProp: \(sample2.first), secondProp: \(sample2.second), ppp: \(sample2.ppp)")



