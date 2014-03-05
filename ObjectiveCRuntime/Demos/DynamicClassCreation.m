//
//  main.m
//  DynamicClassCreation
//
//  Created by Andrew Madsen on 3/3/14.
//  Copyright (c) 2014 Open Reel Software. All rights reserved.
//

/* Compile with:
 
 clang DynamicClassCreation.m -o DynamicClassCreation -ObjC -std=c99 -fmodules
 
 (Must be compiled without ARC.)
 */

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NSArray *SubclassesOfClass(Class parentClass);
void PrintInformationForClass(Class class);
void PrintAllClassesAndMethods(void);

@interface DynamicClassCreationController : NSObject

@property (nonatomic, strong) NSMutableDictionary *classInstances;

@end

@implementation DynamicClassCreationController

- (id)init
{
    self = [super init];
    if (self) {
        _classInstances = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma - UI

- (void)printIntroduction
{
	printf("This program demonstrates dynamic class creation, along with dynamic method resolution in Objective-C.\n\n");
	printf("Commands:\n");
	
	Class class = [self class];
	unsigned int numInstanceMethods = 0;
	Method *instanceMethodList = class_copyMethodList(class, &numInstanceMethods);
	for (unsigned int i=0; i<numInstanceMethods; i++) {
		Method method = instanceMethodList[i];
		SEL methodSelector = method_getName(method);
		NSString *methodName = [NSString stringWithUTF8String:sel_getName(methodSelector)];
		if ([methodName rangeOfString:@"perform"].location == 0 &&
			[methodName rangeOfString:@"Command"].location != NSNotFound) {
			[self performSelector:methodSelector withObject:nil]; // Prints usage
		}
	}
	free(instanceMethodList);
}

- (void)printPrompt
{
	printf("\n> ");
}

#pragma mark - Command Handlers

- (void)performAddCommand:(NSArray *)arguments
{
	if ([arguments count] < 2) {
		printf("add <method_name> <class> [<string_method_prints>] - Generates an instance method named <method_name> and adds it to <class>. " \
			   "<string_method_prints> is an optional string printed by the method when it is called\n");
		return;
	}
	
	NSString *methodName = arguments[0];
	NSString *className = arguments[1];
	NSString *stringToPrint = [arguments count] > 2 ? arguments[2] : @"";
	
	Class class = objc_getClass([className UTF8String]);
	if (!class) {
		printf("Class %s doesn't exist. Create it with the subclass command first.\n", [className UTF8String]);
		return;
	}
	
	if ([class instancesRespondToSelector:NSSelectorFromString(methodName)]) return; // Already done
	
	IMP implementation = imp_implementationWithBlock(^(id _self){
		printf("-[%s<%p> %s] %s\n", class_getName([_self class]), _self, [methodName UTF8String], [stringToPrint UTF8String]);
	});
	class_addMethod(class, NSSelectorFromString(methodName), implementation, "v@:");
}

- (void)performAddcCommand:(NSArray *)arguments
{
	if ([arguments count] < 2) {
		printf("addc <method_name> <class> [<string_method_prints>] - Generates a class method named <method_name> and adds it to <class>. " \
			   "<string_method_prints> is an optional string printed by the method when it is called\n");
		return;
	}
	
	NSString *methodName = arguments[0];
	NSString *className = arguments[1];
	NSString *stringToPrint = [arguments count] > 2 ? arguments[2] : @"";
	
	Class class = objc_getClass([className UTF8String]);
	if (!class) {
		printf("Class %s doesn't exist. Create it with the subclass command first.\n", [className UTF8String]);
		return;
	}
	
	if ([class instancesRespondToSelector:NSSelectorFromString(methodName)]) return; // Already done
	
	IMP implementation = imp_implementationWithBlock(^(id _self){
		printf("+[%s<%p> %s] %s\n", class_getName([_self class]), _self, [methodName UTF8String], [stringToPrint UTF8String]);
	});
	class_addMethod(object_getClass(class), NSSelectorFromString(methodName), implementation, "v@:");
}

- (void)performCallCommand:(NSArray *)arguments
{
	if ([arguments count] < 2) {
		printf("call <method_name> <class> - Calls method named <method_name> on <class>. A new instance of <class>"\
			   "is created if necessary.\n");
		return;
	}
	
	NSString *methodName = arguments[0];
	NSString *className = arguments[1];
	Class class = objc_getClass([className UTF8String]);
	if (!class) {
		printf("Class %s doesn't exist. Create it with the subclass command first.\n", [className UTF8String]);
		return;
	}
	if (![class instancesRespondToSelector:NSSelectorFromString(methodName)]) {
		printf("%s doesn't implement %s. Add it using the add command first.\n", [className UTF8String], [methodName UTF8String]);
		return;
	}
	
	id instance = self.classInstances[className];
	if (!instance) {
		instance = [[class alloc] init];
		self.classInstances[className] = instance;
	}
	[instance performSelector:NSSelectorFromString(methodName)];
}

- (void)performCallcCommand:(NSArray *)arguments
{
	if ([arguments count] < 2) {
		printf("callc <method_name> <class> - Calls class method named <method_name> on <class>.\n");
		return;
	}
	
	NSString *methodName = arguments[0];
	NSString *className = arguments[1];
	Class class = objc_getClass([className UTF8String]);
	if (!class) {
		printf("Class %s doesn't exist. Create it with the subclass command first.\n", [className UTF8String]);
		return;
	}
	if (![class respondsToSelector:NSSelectorFromString(methodName)]) {
		printf("%s doesn't implement %s. Add it using the addc command first.\n", [className UTF8String], [methodName UTF8String]);
		return;
	}
	
	[class performSelector:NSSelectorFromString(methodName)];
}

- (void)performSubclassCommand:(NSArray *)arguments
{
	if ([arguments count] < 1) {
		printf("subclass <subclass_name> [<superclass>] - Creates a new subclass. If <superclass> is not specified, NSObject is assumed.\n");
		return;
	}
	
	NSString *subclassName = arguments[0];
	if (NSClassFromString(subclassName)) {
		printf("class %s already exists", [subclassName UTF8String]);
		return;
	}
	NSString *superClassName = [arguments count] > 1 ? arguments[1] : @"NSObject";
	
	Class superclass = NSClassFromString(superClassName);
	if (!superclass) superclass = [NSObject class];
	Class subclass = objc_allocateClassPair(superclass, [subclassName UTF8String], 0);
	objc_registerClassPair(subclass);
	
	printf("Created class:\n");
	PrintInformationForClass(subclass);
}

- (void)destroySubclassesOf:(Class)class
{
	NSArray *subclasses = SubclassesOfClass(class);
	for (Class subclass in subclasses) {
		[self destroySubclassesOf:subclass];
	}
	[self.classInstances removeObjectForKey:NSStringFromClass(class)];
	objc_disposeClassPair(class);
}

- (void)performDestroyCommand:(NSArray *)arguments
{
	if ([arguments count] < 1) {
		printf("destroy <subclass_name> - Destroys an existing class, along with all its subclasses.\n");
		return;
	}
	
	NSString *className = arguments[0];
	if (!NSClassFromString(className)) {
		printf("class %s doesn't exist", [className UTF8String]);
		return;
	}
	
	Class classToDestroy = NSClassFromString(className);
	[self destroySubclassesOf:classToDestroy];
	printf("Removed class %s.", [className UTF8String]);
}

- (void)performListCommand:(NSArray *)arguments
{
	if (!arguments) {
		printf("list [<class>] - Prints metadata information about class. If class is not specified, all current classes are listed.\n");
		return;
	}
	PrintAllClassesAndMethods();
}

- (void)performExitCommand:(NSArray *)arguments
{
	if (!arguments) {
		printf("exit, quit - Terminates the program.\n");
		return;
	}
	
	exit(0);
}

- (void)performQuitCommand:(NSArray *)arguments
{
	if (!arguments) return;
	[self performExitCommand:arguments];
}

@end

int main(int argc, const char * argv[])
{
	@autoreleasepool {
		
		DynamicClassCreationController *controller = [[DynamicClassCreationController alloc] init];
		[controller printIntroduction];
		[controller printPrompt];
		
		NSFileHandle *standardInputHandle = [NSFileHandle fileHandleWithStandardInput];
		standardInputHandle.readabilityHandler = ^(NSFileHandle *fileHandle) {
			NSData *data = fileHandle.availableData;
			
			NSString *inputString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			NSArray *inputArguments = [inputString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			if (![inputArguments count] || ![[inputArguments firstObject] length]) return; // No usable data
			
			NSString *commandName = inputArguments[0];
			NSString *command = [NSString stringWithFormat:@"perform%@Command:", [commandName capitalizedString]];
			inputArguments = [inputArguments subarrayWithRange:NSMakeRange(1, [inputArguments count]-1)];
			SEL commandSelector = NSSelectorFromString(command);
			if (![controller respondsToSelector:commandSelector]) {
				printf("%s is an unrecognized command.\n", [commandName UTF8String]);
				[controller printIntroduction];
				[controller printPrompt];
				return;
			}
			[controller performSelector:commandSelector withObject:inputArguments];
			[controller printPrompt];
		};
		
		[[NSRunLoop currentRunLoop] run]; // Required to receive data from ORSSerialPort and to process user input
		
		// Cleanup
		standardInputHandle.readabilityHandler = nil;
		
		[controller release];
	}
}







#pragma mark - Runtime Metadata

Boolean IsSystemClass(Class class)
{
	const char *className = class_getName(class);
	return (!strncmp(className, "NS", 2) ||
			!strncmp(className, "_", 1) ||
			!strncmp(className, "__", 2) ||
			!strncmp(className, "OS", 2) ||
			!strncmp(className, "CF", 2) ||
			!strncmp(className, "DD", 2) ||
			!strncmp(className, "XNS", 3) ||
			!strncmp(className, "MDS", 3) ||
			!strcmp(className, "RecvList") ||
			!strcmp(className, "MsgList") ||
			!strcmp(className, "Object") ||
			!strcmp(className, "Protocol"));
}

// From http://www.cocoawithlove.com/2010/01/getting-subclasses-of-objective-c-class.html
NSArray *SubclassesOfClass(Class parentClass)
{
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
	
    classes = malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
	
    NSMutableArray *result = [NSMutableArray array];
    for (NSInteger i = 0; i < numClasses; i++)
    {
        Class superClass = classes[i];
        do {
            superClass = class_getSuperclass(superClass);
        } while(superClass && superClass != parentClass);
		
        if (superClass == nil) continue;
		
        [result addObject:classes[i]];
    }
	
    free(classes);
	
    return result;
}

void PrintClassHierarchy(Class class)
{
	const char *classname = class_getName(class);
	printf("%s", classname);
	
	Class superclass = class_getSuperclass(class);
	while (superclass != Nil) {
		printf(" : %s", class_getName(superclass));
		superclass = class_getSuperclass(superclass);
	}
	printf("\n\n");
}

void PrintMethodArguments(Method method)
{
	unsigned numArguments = method_getNumberOfArguments(method);
	if (!numArguments) return;
	
	printf("\t\tArguments:\n");
	for (unsigned i=2; i<numArguments; i++) { // Skip self and _cmd
		char *argumentType = method_copyArgumentType(method, i);
		printf("\t\t\t%s\n", argumentType);
		free(argumentType);
	}
}

void PrintInstanceMethods(Class class)
{
	// Get class's methods and information about them.
	unsigned int numClassMethods = 0;
	Method *classMethodList = class_copyMethodList(object_getClass(class), &numClassMethods);
	unsigned int numInstanceMethods = 0;
	Method *instanceMethodList = class_copyMethodList(class, &numInstanceMethods);
	
	if (numClassMethods) {
		printf("\t----Class Methods----\n\n");
		for (unsigned int i=0; i<numClassMethods; i++) {
			Method method = classMethodList[i];
			SEL methodSelector = method_getName(method);
			const char *methodName = sel_getName(methodSelector);
			printf("\tMethod: %s\n", methodName);
			
			const char *methodType = method_getTypeEncoding(method);
			printf ("\t\tType: %s\n", methodType);
			
			PrintMethodArguments(method);
			printf("\n");
		}
	}
	
	if (numInstanceMethods) {
		printf("\t----Instance Methods----\n\n");
		for (unsigned int i=0; i<numInstanceMethods; i++) {
			Method method = instanceMethodList[i];
			SEL methodSelector = method_getName(method);
			const char *methodName = sel_getName(methodSelector);
			printf("\tMethod: %s\n", methodName);
			
			const char *methodType = method_getTypeEncoding(method);
			printf ("\t\tType: %s\n", methodType);
			
			PrintMethodArguments(method);
			printf("\n");
		}
	}
	
	free(classMethodList);
	free(instanceMethodList);
}

void PrintPropertyAttributes(objc_property_t property)
{
	/* Legend:
	 
	 R - The property is read-only (readonly).
	 C - The property is a copy of the value last assigned (copy).
	 & - The property is a reference to the value last assigned (retain).
	 N - The property is non-atomic (nonatomic).
	 G<name> - The property defines a custom getter selector name. The name follows the G (for example, GcustomGetter,).
	 S<name> - The property defines a custom setter selector name. The name follows the S (for example, ScustomSetter:,).
	 D - The property is dynamic (@dynamic).
	 W - The property is a weak reference (__weak).
	 P - The property is eligible for garbage collection.
	 t<encoding> - Specifies the type using old-style encoding.
	 
	 */
	
	// Get attributes
	const char *attributeString = property_getAttributes(property);
	printf("\t\tAttributes (%s):\n", attributeString);
	unsigned int numAttributes = 0;
	objc_property_attribute_t *attributes = property_copyAttributeList(property, &numAttributes);
	for (unsigned int i=0; i<numAttributes; i++) {
		objc_property_attribute_t attribute = attributes[i];
		if (strlen(attribute.value)) printf("\t\t\t%s: %s\n", attribute.name, attribute.value);
	}
	
	free(attributes);
}

void PrintProperties(Class class)
{
	// Get class's properties
	unsigned int numProperties = 0;
	objc_property_t *propertyList = class_copyPropertyList(class, &numProperties);
	if (!numProperties) return;
	
	printf("\t----Properties----\n\n");
	
	for (unsigned int i=0; i<numProperties; i++) {
		objc_property_t property = propertyList[i];
		const char *propertyName = property_getName(property);
		printf("\tProperty: %s\n", propertyName);
		
		PrintPropertyAttributes(property);
	}
	
	free(propertyList);
}

void PrintInformationForClass(Class class)
{
	PrintClassHierarchy(class);
	PrintInstanceMethods(class);
	PrintProperties(class);
}

void PrintAllClassesAndMethods(void)
{
	// Get classes in program
	int numClasses = objc_getClassList(NULL, 0);
	Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
	numClasses = objc_getClassList(classes, numClasses);
	
	unsigned int numClassesPrinted = 0;
	for (int i=0; i<numClasses; i++) {
		if (IsSystemClass(classes[i])) continue;
		if (classes[i] == [DynamicClassCreationController class]) continue;
		PrintInformationForClass(classes[i]);
		printf("\n");
		numClassesPrinted++;
	}
	
	if (!numClassesPrinted) {
		printf("There are no non system classes in the program.\n");
	}
	
	free(classes);
}