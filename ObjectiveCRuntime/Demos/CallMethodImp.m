//
//  main.m
//  CallMethodImp
//
//  Created by Andrew Madsen on 3/3/14.
//  Copyright (c) 2014 Open Reel Software. All rights reserved.
//

/* Compile with:
 
 clang CallMethodImp.m -o CallMethodImp -ObjC -std=c99 -fmodules
 
 (Must be compiled without ARC.)
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface ORSPerson : NSObject

- (void)walk;
- (void)speak:(NSString *)stringToSpeak;
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

- (void)speak:(NSString *)stringToSpeak
{
	NSLog(@"%@", stringToSpeak);
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

int main(int argc, const char * argv[])
{
	@autoreleasepool {
		ORSPerson *person = [[[ORSPerson alloc] init] autorelease];
	
		IMP walk = class_getMethodImplementation([ORSPerson class], @selector(walk));
		walk(person, @selector(walk));
		
		IMP sleep = class_getMethodImplementation([ORSPerson class], @selector(sleepFrom:until:));
		sleep(person, @selector(sleepFrom:until:), [NSDate distantPast], [NSDate distantFuture]);
		
		NSColor *favoriteColor = objc_msgSend(person, @selector(favoriteColor));
		NSLog(@"favorite color: %@", favoriteColor);
		
		objc_msgSend(person, @selector(eat:), @"vegetables");
	}
}

