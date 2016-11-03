//: [Previous](@previous)

import Foundation

class ThreadSafeThing {
    
    private let queue = DispatchQueue(label: "com.DevMountain.ThreadSafeThingQueue")
    
    private var _foo = "" // Internal property
    
    var foo: String {
        get {
            var result: String?
            queue.sync {
                result = _foo
            }
            return result!
        }
        set {
            queue.sync {
                _foo = newValue
            }
        }
    }
}

//: [Next](@next)
