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
	
	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		guard let keyPath = keyPath, object = object else { return }
		
		// Make sure the notification is intended for us, and not a superclass
		if context != &ObserverKVOContext {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
			return
		}
		
		print("\(object)'s \(keyPath) changed to \(object.valueForKeyPath(keyPath)!)")
	}
}

// Let's try it out

let observer = Observer()
let foo = observer.foo

foo.bar = 42
foo.bar = 27
