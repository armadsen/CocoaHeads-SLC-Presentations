import Foundation

struct PropertyObserver<T> {
	private weak var target: AnyObject?
	private let handler: (T) -> Void
	
	init(target: AnyObject, handler: @escaping (T) -> Void) {
		self.target = target
		self.handler = handler
	}

	func invoke(_ newValue: T) {
		if target != nil { self.handler(newValue) }
	}
}

class PropertyNotification<PropertyType> {
	
	private var observers = [PropertyObserver<PropertyType>]()
	
	func post(newValue: PropertyType) {
		self.observers.forEach {$0.invoke(newValue)}
	}
	
	func add(observer: AnyObject, handler: @escaping (PropertyType) -> Void) {
		observers.append(PropertyObserver(target: observer, handler: handler))
	}
}

class Observable<T> {
	
	init(_ value: T) {
		self.value = value
	}
	
	var value: T {
		didSet {
			changeNotification.post(newValue: value)
		}
	}
	
	func addObserver(_ observer: AnyObject, handler: @escaping (T) -> Void) {
		self.changeNotification.add(observer: observer, handler: handler)
	}
	
	private let changeNotification = PropertyNotification<T>()
}

//: To make your object's properties observable, make them `Observable`s

class Foo {
	var bar = Observable(0)
}

//: Let's try it out

class TestObserver {} // <- Not an NSObject

let foo = Foo()
let testObserver = TestObserver()
foo.bar.addObserver(testObserver) { (newValue) -> Void in
	print("foo.bar changed to \(newValue)")
}

foo.bar.value = 42
foo.bar.value = 27

//: However, we *cannot* use this in a non-ObjC class or struct now:

/*
struct ObserverStruct {
	
	let foo: Foo
	
	init() {
		foo = Foo()
		foo.bar.addObserver(self) { (newValue) -> Void in
			print("foo.bar changed to \(newValue)")
		}
	}
}
*/
