import Foundation

// To make your objects observable, inherit from an ObjC class, and mark observable properties `dynamic`:

class Foo : NSObject {
	dynamic var bar = 0
}

// To observe using KVO, the observer must also inherit from an ObjC class.

class Observer : NSObject {
	
	var ObserverKVOContext: Int = 0
	let foo: Foo
	
	override init() {
		foo = Foo()
		super.init()
		foo.addObserver(self, forKeyPath: "bar", options: [], context: &ObserverKVOContext)
	}
	
	// You must remove yourself as an observer before being deallocated
	deinit {
		foo.removeObserver(self, forKeyPath: "bar")
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard let keyPath = keyPath, let object = object else { return }
		
		// Make sure the notification is intended for us, and not a superclass
		if context != &ObserverKVOContext {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
			return
		}
		
		print("\(object)'s \(keyPath) changed to \((object as AnyObject).value(forKeyPath: keyPath)!)")
	}
}

// Let's try it out

let observer = Observer()
let foo = observer.foo

foo.bar = 42
foo.bar = 27
