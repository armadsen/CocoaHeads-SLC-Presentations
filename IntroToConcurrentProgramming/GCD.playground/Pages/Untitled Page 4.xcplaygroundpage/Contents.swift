//: [Previous](@previous)

import Foundation

let queue = OperationQueue()
queue.name = "MySerialOperationQueue"
queue.maxConcurrentOperationCount = 1

let op1 = BlockOperation {
    print("Do this first")
}

let op2 = BlockOperation {
    print("Do this second")
}

let op3 = BlockOperation {
    print("Do this third")
}

queue.waitUntilAllOperationsAreFinished()

print("Done!")

//: [Next](@next)
