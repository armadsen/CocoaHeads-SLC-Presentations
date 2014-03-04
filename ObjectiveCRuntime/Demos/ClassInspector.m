//
//  main.m
//  Class Inspector
//
//  Created by Andrew Madsen on 3/3/14.
//  Copyright (c) 2014 Open Reel Software. All rights reserved.
//

/* Compile with:
 
 clang ClassInspector.m -o ClassInspectorClassInspector -ObjC -std=c99 -fmodules
 
 (Can be compiled with or without ARC.)
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

@interface ORSCreature : NSObject

+ (NSString *)species;

@end

@implementation ORSCreature

+ (NSString *)species { return nil; }

@end

@interface ORSPerson : ORSCreature

- (void)walk;
- (void)eat:(NSString *)foodName;
- (void)sleepFrom:(NSDate *)bedtime until:(NSDate *)wakeupTime;
- (NSString *)favoriteColor;

@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, readonly) NSString *fullName;
@property NSUInteger age;
@property (nonatomic, strong) NSArray *friends;

@end

@implementation ORSPerson

+ (NSString *)species { return @"Human"; }

- (void)walk
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)eat:(NSString *)foodName
{
	NSLog(@"%s %@", __PRETTY_FUNCTION__, foodName);
}

- (void)sleepFrom:(NSDate *)bedtime until:(NSDate *)wakeupTime
{
	NSLog(@"Going to bed at %@ until %@", bedtime, wakeupTime);
}

- (NSColor *)favoriteColor
{
	return [NSColor greenColor];
}

- (NSString *)fullName
{
	return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
}

@end

Boolean IsSystemClass(Class class)
{
	const char *className = class_getName(class);
	return (strncmp(className, "ORS", 2));
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

int main(int argc, const char * argv[])
{
	// Note, no "traditional" Objective-C (bracket syntax or @property dot-notation) here, it's all C.
	
	// Quick and dirty options parsing from arguments
	BOOL shouldShowSystemClasses = NO;
	for (int i=1; i<argc; i++) {
		const char *argument = argv[i];
		printf("%s\n", argument);
		if (!strcmp(argument, "-print-system-classes")) {
			shouldShowSystemClasses = YES;
			continue;
		}
	}
	
	// Get classes in program
	int numClasses = objc_getClassList(NULL, 0);
	Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
	numClasses = objc_getClassList(classes, numClasses);
	
	for (int i=0; i<numClasses; i++) {
		Class eachClass = classes[i];
		
		if (!shouldShowSystemClasses && IsSystemClass(eachClass)) continue;
		
		PrintClassHierarchy(eachClass);
		PrintInstanceMethods(eachClass);
		PrintProperties(eachClass);
		printf("\n\n\n");
		
	}
	free(classes);
    return 0;
}

