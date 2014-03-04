//
//  main.m
//  ISASwizzling
//
//  Created by Andrew Madsen on 3/3/14.
//  Copyright (c) 2014 Open Reel Software. All rights reserved.
//

/* Compile with:
 
 clang ISASwizzling.m -o ISASwizzling -ObjC -std=c99 -fmodules
 
 (Must be compiled without ARC.)
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

@interface ORSCreature : NSObject

+ (NSString *)species;

- (BOOL)evolve; // Returns NO if evolution didn't happen

@end

@implementation ORSCreature

+ (NSString *)species { return nil; }

- (BOOL)evolve
{
	NSArray *evolutionPath = @[@"ORSAmoeba", @"ORSFish", @"ORSLizard", @"ORSApe", @"ORSPerson"];
	Class currentSpeciesClass = [self class];
	NSString *currentSpecies = NSStringFromClass(currentSpeciesClass);
	NSUInteger currentEvolutionaryIndex = [evolutionPath indexOfObject:currentSpecies];
	if (currentEvolutionaryIndex >= [evolutionPath count]-1) return NO; // Can't evolve
	
	Class newSpeciesClass = NSClassFromString(evolutionPath[currentEvolutionaryIndex+1]);
	if (!newSpeciesClass) return NO;
	
	object_setClass(self, newSpeciesClass); // ARC doesn't like this!

	return YES;
}

@end

@interface ORSAmoeba : ORSCreature
@end

@implementation ORSAmoeba
+ (NSString *)species { return @"Amoeba"; }
@end

@interface ORSFish : ORSCreature
@end

@implementation ORSFish
+ (NSString *)species { return @"Fish"; }
@end

@interface ORSLizard : ORSCreature
@end

@implementation ORSLizard
+ (NSString *)species { return @"Lizard"; }
@end

@interface ORSApe : ORSCreature
@end

@implementation ORSApe
+ (NSString *)species { return @"Ape"; }
@end

@interface ORSPerson : ORSCreature

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
		ORSCreature *creature = [[ORSAmoeba alloc] init]; // This is th only assignment of creature!
		NSLog(@"Starting with %p, which is a %@.", creature, [[creature class] species]);
		
		while ([creature evolve]) {
			NSLog(@"Creature %p evolved into a %@!", creature, [[creature class] species]);
		}
		
		[creature release];
	}
}

