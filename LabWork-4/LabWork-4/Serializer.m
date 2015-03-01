#import "Serializer.h"

static NSString *const KEY_WRAPPER_SYMBOL = @"\"";
static NSString *const ELEMENTS_SEPARATOR_SYMBOL = @",";
static NSString *const ERROR_DOMAIN = @"ru.kostya.Serializer";
enum ErrorCode {
    UNSUPPORTED_PARAMETER = 1, // Passed object is not a dictionary
    OBJECT_OF_INVALID_TYPE = 2, // Passed dictionary contains an object of invalid type
    INVALID_KEY_TYPE = 3, // One of the keys has invalid type
    INVALID_NSVALUE = 4 // NSValue doesn't contain CGRect struct
};


@implementation Serializer

// The only public method
/*!
 * Serializes an object to readable format like json. Handles only NSDictionary objects. 
 * Serializing dictionaries may include one of the following object types: NSDictionary, NSArray, 
 * NSSet, NSNumber, NSNull, CGRect (wrapped in NSValue) but their keys may only be strings or 
 * numbers.
 * Serializing arrays and sets may include one of the following object types: NSDictionary, NSArray, 
 * NSSet, NSNumber, NSNull, CGRect (wrapped in NSValue).
 * Nesting level of data structure is not limited.
 * \param dictionary The NSDicionary object which will be serialixed.
 * \param error Out parameter containing an NSError object with the error's descrioption. 
 * The error includes error code represented as one items of ErrorCode enum.
 * \returns The string with the result of serialization.
 */
+ (NSString *)serializeDictionary:(id)dictionary error:(NSError *__autoreleasing *)error {
    // Check that passed object is actually NSDictionary
    if ([dictionary isKindOfClass:[NSDictionary class]]) {
        NSMutableString *result = [[NSMutableString alloc] init];
        return [[self class] serializeObject:dictionary result:&result error:&*error];
    }
    else { // If not a dictionary then return error
        if (!!error) {
            NSString *const failureReason =
            [NSString stringWithFormat:
             @"Expected NSDictionary class as method's parameter but %@ class was received.",
             [dictionary className]];
            NSDictionary *const userInfo = @{NSLocalizedDescriptionKey:
                                                 NSLocalizedString(failureReason, nil)};
            *error = [NSError errorWithDomain:ERROR_DOMAIN
                                         code:UNSUPPORTED_PARAMETER
                                     userInfo:userInfo];
        }
        return nil;
    }
}

+ (NSString *)serializeObject:(id)object
                       result:(NSMutableString **)result
                        error:(NSError *__autoreleasing *)error {
    // Check that passed object has one of the supperted types and handle it appropriately
    if ([object isKindOfClass:[NSDictionary class]]) {
        [[self class] serializeNSDictionary:(NSDictionary *)object result:&*result error:&*error];
    }
    else if ([object isKindOfClass:[NSArray class]]) {
        [[self class] serializeNSArray:(NSArray *)object result:&*result error:&*error];
    }
    else if ([object isKindOfClass:[NSSet class]]) {
        [[self class] serializeNSSet:(NSSet *)object result:&*result error:&*error];
    }
    else if ([object isKindOfClass:[NSNumber class]]) {
        [[self class] serializeNSNumber:(NSNumber *)object result:&*result];
    }
    else if ([object isKindOfClass:[NSNull class]]) {
        [[self class] serializeNSNull:(NSNull *)object result:&*result];
    }
    else if ([object isKindOfClass:[NSValue class]]) {
        [[self class] serializeCGRect:(NSValue *)object result:&*result error:&*error];
    }
    else { // If the received object has unsupported type then return error
        if (!!error) {
            NSString *const failureReason = [NSString stringWithFormat:
                                             @"Received an object of invalid type: %@.",
                                             [object className]];
            NSDictionary *const userInfo = @{NSLocalizedDescriptionKey:
                                                 NSLocalizedString(failureReason, nil)};
            *error = [NSError errorWithDomain:ERROR_DOMAIN
                                         code:OBJECT_OF_INVALID_TYPE
                                     userInfo:userInfo];
        }
        return nil;
    }
    return *result;
}

+ (void)serializeNSDictionary:(NSDictionary *)dictionary
                       result:(NSMutableString **)result
                        error:(NSError *__autoreleasing *)error {
    [*result appendString: @"{"];
    NSArray *dictionaryKeys = [dictionary allKeys];
    for (id key in dictionaryKeys) {
        // Check that key of dictionary has supported type and return error if not
        if (![key isKindOfClass:[NSNumber class]] && ![key isKindOfClass:[NSString class]]) {
            NSString *const failureReason =
            [NSString stringWithFormat:
             @"One of the keys of the dictionary has invalid type: %@.", [key className]];
            NSDictionary *const userInfo = @{NSLocalizedDescriptionKey:
                                                 NSLocalizedString(failureReason, nil)};
            if (!!error) {
                *error = [NSError errorWithDomain:ERROR_DOMAIN
                                             code:INVALID_KEY_TYPE
                                         userInfo:userInfo];
            }
            *result = nil;
            break;
        }
        else {
            [*result appendFormat:@"%@%@%@: ", KEY_WRAPPER_SYMBOL, key, KEY_WRAPPER_SYMBOL];
            [[self class] serializeObject: dictionary[key] result:&*result error:&*error];
            // Check if serializeObject method was ended with error and handle it
            if (!!error && *error != nil) {
                NSString *const failureReason =
                [[*error localizedDescription]
                 stringByAppendingFormat:@" The key of the invalid object is '%@'.", key];
                NSDictionary *const userInfo = @{NSLocalizedDescriptionKey:
                                                     NSLocalizedString(failureReason, nil)};
                *error = [NSError errorWithDomain:[*error domain]
                                             code:[*error code]
                                         userInfo:userInfo];
                *result = nil;
                break;
            }
            if (key != [dictionaryKeys lastObject]) {
                [*result appendFormat: @"%@ ", ELEMENTS_SEPARATOR_SYMBOL];
            }
        }
    }
    [*result appendString: @"}"];
}

+ (void)serializeNSArray:(NSArray *)array
                  result:(NSMutableString **)result
                   error:(NSError *__autoreleasing *)error {
    [*result appendString: @"["];
    for (id item in array) {
        [[self class] serializeObject:item result:&*result error:&*error];
        // Check if serializeObject method was ended with error and handle it
        if (!!error && *error != nil) {
            *result = nil;
            break;
        }
        if (item != [array lastObject]) {
            [*result appendFormat: @"%@ ", ELEMENTS_SEPARATOR_SYMBOL];
        }
    }
    [*result appendString: @"]"];
}

+ (void)serializeNSSet:(NSSet *)set
                result:(NSMutableString **)result
                 error:(NSError *__autoreleasing *)error {
    NSArray *tempArray = [set allObjects];
    [[self class] serializeNSArray:tempArray result:&*result error:&*error];
}

+ (void)serializeNSNumber:(NSNumber *)number result:(NSMutableString **)result {
    [*result appendString: [number stringValue]];
}

+ (void)serializeNSNull:(NSNull *)null result:(NSMutableString **)result {
    [*result appendString: @"null"];
}

+ (void)serializeCGRect:(NSValue *)value
                 result:(NSMutableString **)result
                  error:(NSError *__autoreleasing *)error {
    // Check that NSValue actualy contains CGRect
    if (strcmp([value objCType], @encode(CGRect)) == 0) {
        CGRect rect = [value rectValue];
        NSDictionary *tempDict = @{@"width": [NSNumber numberWithFloat:rect.size.width],
                                   @"height": [NSNumber numberWithFloat:rect.size.height],
                                   @"x": [NSNumber numberWithFloat:rect.origin.x],
                                   @"y": [NSNumber numberWithFloat:rect.origin.y]};
        [[self class] serializeNSDictionary:tempDict result:&*result error:nil];
    }
    else {
        if (!!error) {
            NSString *const failureReason =
            @"Received NSValue object doesn't contain CGRect structure.";
            NSDictionary *const userInfo = @{NSLocalizedDescriptionKey:
                                                 NSLocalizedString(failureReason, nil)};
            *error = [NSError errorWithDomain:ERROR_DOMAIN code:INVALID_NSVALUE userInfo:userInfo];
        }
    }
    
}

@end
