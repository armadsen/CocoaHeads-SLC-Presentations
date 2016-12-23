import Foundation

class Observe : NSObject {
	
	init(_ objectToObserve: NSObject, keyPath: String, observationBlock: @escaping (AnyObject?) -> Void) {
		self.objectToObserve = objectToObserve
		self.keyPath = keyPath
		self.observationBlock = observationBlock
		
		super.init()
		
		objectToObserve.addObserver(self, forKeyPath: keyPath, options: [], context: &KVOContext)
	}
	
	deinit {
		self.objectToObserve.removeObserver(self, forKeyPath: self.keyPath, context: &KVOContext)
	}
	
	override func observeValue(forKeyPath keyPath: String?,
	                           of object: Any?,
	                           change: [NSKeyValueChangeKey : Any]?,
	                           context: UnsafeMutableRawPointer?) {
		guard let keyPath = keyPath, let object = object else { return }
		
		// Make sure the notification is intended for us, and not a superclass
		if context != &KVOContext {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
			return
		}
		
		let newValue = (object as AnyObject).value(forKeyPath: keyPath)
		self.observationBlock(newValue as AnyObject?)
	}
	
	let objectToObserve: NSObject
	let keyPath: String
	let observationBlock: (AnyObject?) -> Void
	
	fileprivate var KVOContext = 1
}

//: To make your objects observable, inherit from an ObjC class, and mark observable properties `dynamic`:

class Foo : NSObject {
	dynamic var bar = 0
}

//: Let's try it out

let foo = Foo()
let observer = Observe(foo, keyPath: "bar") { (newValue) -> Void in
	print("foo.bar changed to \(newValue)")
}

foo.bar = 42
foo.bar = 27

//: Of course, we can use this in a non-ObjC class or struct now too:

struct ObserverStruct {
	
	let foo: Foo
	let observation: Observe
	
	init() {
		foo = Foo()
		observation = Observe(foo, keyPath: "bar") { (newValue) -> Void in
			print("foo.bar changed to \(newValue)")
		}
	}
}

let observerStruct = ObserverStruct()
let foo2 = observerStruct.foo

foo2.bar = 1
foo2.bar = 1000000
