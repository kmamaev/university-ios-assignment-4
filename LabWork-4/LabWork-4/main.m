#import <Foundation/Foundation.h>
#import "Serializer.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Test case 1: Positive.
        NSLog(@"Test case 1: Positive.");
        NSError *__autoreleasing error = nil;
        CGRect testRect = CGRectMake(1.1, 2.2, 3.3, 4.4);
        NSDictionary *testDictionary = @{@"CGRect1": [NSValue valueWithRect: testRect],
                                         @"isAlive": @1,
                                         @"age": @25,
                                         @"height_cm": @167.6,
                                         @"address": @{@"streetAddress": @21,
                                                       @"postalCode": @100213100},
                                         @"phoneNumbers": @[@{@"type": @1, @"number": @2125551234},
                                                            @{@"type": @2, @"number": @6465554567}],
                                         @"children": @[],
                                         @"spouse": [NSNull null]};
        NSString *serializedDictionary = [Serializer serializeDictionary:testDictionary
                                                                   error:&error];
        if (!error) {
            NSLog(@"Serialized dictionary: %@", serializedDictionary);
        }
        else {
            NSLog(@"Error: %@", error);
        }
        NSLog(@"--------------------");
        
        // Test case 2: Passed object is not a dictionary.
        NSLog(@"Test case 2: Passed object is not a dictionary.");
        NSError *__autoreleasing error2 = nil;
        NSString *testDictionary2 = @"Not a dictionary";
        NSString *serializedDictionary2 = [Serializer serializeDictionary:testDictionary2
                                                                    error:&error2];
        if (!error2) {
            NSLog(@"Serialized dictionary: %@", serializedDictionary2);
        }
        else {
            NSLog(@"Error: %@", error2);
        }
        NSLog(@"--------------------");
        
        // Test case 3: Passed dictionary contains an object of invalid type.
        NSLog(@"Test case 3: Passed dictionary contains an object of invalid type.");
        NSError *__autoreleasing error3 = nil;
        NSDictionary *testDictionary3 = @{@1: @1, @2: @2, @3: @"Three"};
        NSString *serializedDictionary3 = [Serializer serializeDictionary:testDictionary3
                                                                    error:&error3];
        if (!error3) {
            NSLog(@"Serialized dictionary: %@", serializedDictionary3);
        }
        else {
            NSLog(@"Error: %@", error3);
        }
        NSLog(@"--------------------");
        
        // Test case 4: One of the keys has invalid type.
        NSLog(@"Test case 4: One of the keys has invalid type.");
        NSError *__autoreleasing error4 = nil;
        NSDictionary *testDictionary4 = @{@1: @1, @2: @2, [NSDate date]: @3};
        NSString *serializedDictionary4 = [Serializer serializeDictionary:testDictionary4
                                                                    error:&error4];
        if (!error4) {
            NSLog(@"Serialized dictionary: %@", serializedDictionary4);
        }
        else {
            NSLog(@"Error: %@", error4);
        }
        NSLog(@"--------------------");
        
        // Test case 5: NSValue doesn't contain CGRect.
        NSLog(@"Test case 5: NSValue doesn't contain CGRect.");
        NSError *__autoreleasing error5 = nil;
        CGPoint testPoint = CGPointMake(1.1, 2.2);
        NSDictionary *testDictionary5 = @{@"CGRect1": [NSValue valueWithPoint:testPoint]};
        NSString *serializedDictionary5 = [Serializer serializeDictionary:testDictionary5
                                                                    error:&error5];
        if (!error5) {
            NSLog(@"Serialized dictionary: %@", serializedDictionary5);
        }
        else {
            NSLog(@"Error: %@", error5);
        }
        NSLog(@"--------------------");

    }
    return 0;
}