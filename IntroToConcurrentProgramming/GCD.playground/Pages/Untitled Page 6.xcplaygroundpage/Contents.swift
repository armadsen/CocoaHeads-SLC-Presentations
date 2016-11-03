//: [Previous](@previous)

import Foundation

let queue = DispatchQueue(label: "SerialQueue")
queue.async {
    // Do some stuff
    print("Starting some work")
    queue.sync {
        print("Do this synchronously")
    }
    print("Done")
}

//: [Next](@next)
