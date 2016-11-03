//: Playground - noun: a place where people can play

import Cocoa

let serialQueue = DispatchQueue(label: "MySerialQueue")

serialQueue.async {
	print("Do this first")
}

serialQueue.async {
	print("Do this second")
}

serialQueue.sync {
	print("Do this third waiting until the first two are done")
}

print("Done!")

let concurrentQueue = DispatchQueue.global()

concurrentQueue.async {
	print("Do this")
}

concurrentQueue.async {
	print("Do this at the same time")
}
