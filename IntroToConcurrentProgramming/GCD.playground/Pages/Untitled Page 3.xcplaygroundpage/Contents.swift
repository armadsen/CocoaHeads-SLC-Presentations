//: [Previous](@previous)

import Foundation

let queue = OperationQueue()
queue.name = "MyOperationQueue"
queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount

let op1 = BlockOperation { 
    print("Do this")
}

let op2 = BlockOperation {
    print("Do this at the same time")
}

let op3 = BlockOperation {
    print("Do this when both of those are done")
}
op3.addDependency(op1)
op3.addDependency(op2)

//: [Next](@next)
