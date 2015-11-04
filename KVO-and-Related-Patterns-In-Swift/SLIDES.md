
# KVO and Related Techniques in Swift  
### Andrew Madsen
### @armadsen
### SLC CocoaHeads, November 3, 2015  

---

# What is Key-Value Observing (KVO)?

From the [documentation](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html):

"Key-value observing is a mechanism that allows objects to be notified of changes to specified properties of other objects."

^KVO provides a way for one object to be notified when the value of another object's property changes. This is useful in all kinds of scenarios. It allows loose coupling. Unlike a delegate, the observed object doesn't need to know that the observer exists at all. Unlike NSNotifications, the observing object needn't do anything special to make itself observable. In some sense, it's the best of both of these worlds. Of course, there are some disadvantages. We'll get to those later.

---

# A Little History

KVO was introduced in Mac OS X 10.3 Panther, in 2003. While it is useful -- and commonly used -- as a standalone API, it was introduced to make Cocoa Bindings possible. 

^KVO is to Cocoa Bindings as blocks are to GCD.

Unlike Cocoa Bindings, KVO is available on iOS.

---

# How Does KVO work?

- As long as you're using properties (not bare ivars), you get KVO support for free.

^KVO is implemented using dynamic subclasses created at runtime and isa-swizzling. The setter for each property is overridden in this subclass, and the appropriate notification methods are called. However, you can opt out of this and/or call these notification methods manually if you wish.

- Sign up to be notified of changes by calling `-addObserver:forKeyPath:options:context:`. Receive change notifications by implementing `-observeValueForKeyPath:ofObject:change:context:`.  

---

# Gotchas

- Must ensure that you remove observer before either object is deallocated.
- Subclasses can easily break KVO for their superclasses.
- API is stringly-typed
- Relies on ObjC runtime features. Will not work for non-@objc Swift objects.

---

#[fit]Demo Time

---

#[fit]KVO in Swift

---

#KVO in Swift

KVO in available in Swift, but only for classes inheriting from NSObject.

To make your objects observable, inherit from an ObjC class, and mark observable properties `dynamic`:

```
class Foo : NSObject {
	dynamic var bar = 0
}
```

---

#KVO in Swift 2: The Bad Parts

- Only for ObjC-compatible classes. Can't observe structs, enums, generic classes, etc. 
- Managing registration/deregistration is harder than in ObjC.

^Property observers aren't called when properties are changed from `init`/`deinit`, so you can't fully implement observation management in `willSet`/`didSet`.

- All the same cons as KVO in Objective-C

---

#So, what do we do?

Three options:

- Use KVO in Swift as described earlier.
- Write some code to improve KVO.
- Come up with a pure Swift approach.

^Each has advantages and disadvantages. Option 2 maintains compatibility with ObjC code (including framework code that requires the use of KVO). Option 3 breaks ObjC compatibility, and requires some gross syntax compromises, but can work with structs, enums, generics, etc.

---

#[fit]More Demos

---

#[fit]NOTHING IS PERFECT

---

#More

- [KVO Programming Guide](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html)
- [KVO in Swift with Cocoa and Objective-C book](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/AdoptingCocoaDesignPatterns.html#//apple_ref/doc/uid/TP40014216-CH7-ID12)
- [Observable-Swift](https://github.com/slazyk/Observable-Swift)
- Scott Logic: [Exploring KVO alternatives with Swift](http://blog.scottlogic.com/2015/02/11/swift-kvo-alternatives.html)
- [Intro to Arduino](https://github.com/armadsen/IntroToArduino/) (source for some demos)