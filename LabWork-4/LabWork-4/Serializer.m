#import "Serializer.h"

static NSString *const KEY_WRAPPER_SYMBOL = @"\"";
static NSString *const ELEMENTS_SEPARATOR_SYMBOL = @",";
static NSString *const LINE_SEPARATOR = @"\n";
static NSString *const LINE_INDENTATION = @"    ";
static NSString *const CONFIG_LINE_INDENTATION_KEY = @"Line indentation key";
static NSString *const CONFIG_LINE_SEPARATOR_KEY = @"Line separator key";
static NSString *const CONFIG_DEPTH_KEY = @"Depth key";
static NSString *const ERROR_DOMAIN = @"ru.kostya.Serializer";
typedef NS_ENUM(NSInteger, ErrorCode) {
    UNSUPPORTED_PARAMETER = 1, // Passed object is not a dictionary
    OBJECT_OF_INVALID_TYPE = 2, // Passed dictionary contains an object of invalid type
    INVALID_KEY_TYPE = 3, // One of the keys has invalid type
    INVALID_NSVALUE = 4 // NSValue doesn't contain CGRect struct
};

@implementation Serializer

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
    return [self serializeDictionary:dictionary byOneLine:NO error:error];
}

/*!
 * Serializes an object to readable format like json. Handles only NSDictionary objects. 
 * Serializing dictionaries may include one of the following object types: NSDictionary, NSArray, 
 * NSSet, NSNumber, NSNull, CGRect (wrapped in NSValue) but their keys may only be strings or 
 * numbers.
 * Serializing arrays and sets may include one of the following object types: NSDictionary, NSArray, 
 * NSSet, NSNumber, NSNull, CGRect (wrapped in NSValue).
 * Nesting level of data structure is not limited.
 * \param dictionary The NSDicionary object which will be serialixed.
 * \param byOneLine BOOL parameter. If YES then result will be in one line or multilined otherwise.
 * \param error Out parameter containing an NSError object with the error's descrioption. 
 * The error includes error code represented as one items of ErrorCode enum.
 * \returns The string with the result of serialization.
 */
+ (NSString *)serializeDictionary:(id)dictionary
                        byOneLine:(BOOL)isOneLined
                            error:(NSError *__autoreleasing *)error {
    // Setup depth
    [self setDepth:0];
 
    // Configure one line or multiline output option
    [self configureOutputOption:isOneLined];
    
    // Check that passed object is actually NSDictionary
    if ([dictionary isKindOfClass:[NSDictionary class]]) {
        NSMutableString *result = [[NSMutableString alloc] init];
        return [self serializeObject:dictionary result:&result error:error];
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
        [self serializeNSDictionary:(NSDictionary *)object result:result error:error];
    }
    else if ([object isKindOfClass:[NSArray class]]) {
        [self serializeNSArray:(NSArray *)object result:result error:error];
    }
    else if ([object isKindOfClass:[NSSet class]]) {
        [self serializeNSSet:(NSSet *)object result:result error:error];
    }
    else if ([object isKindOfClass:[NSNumber class]]) {
        [self serializeNSNumber:(NSNumber *)object result:result];
    }
    else if ([object isKindOfClass:[NSNull class]]) {
        [self serializeNSNull:(NSNull *)object result:result];
    }
    else if ([object isKindOfClass:[NSValue class]]) {
        [self serializeCGRect:(NSValue *)object result:result error:error];
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
    [*result appendString:[self lineSeparator]];
    [self incrementDepth];
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
            [*result appendString: [self buildLineIndentation]];
            [*result appendFormat:@"%@%@%@: ", KEY_WRAPPER_SYMBOL, key, KEY_WRAPPER_SYMBOL];
            [self serializeObject: dictionary[key] result:result error:error];
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
                [*result appendString:[self lineSeparator]];
            }
        }
    }
    [self decrementDepth];
    [*result appendString:[self lineSeparator]];
    [*result appendString: [self buildLineIndentation]];
    [*result appendString: @"}"];
}

+ (void)serializeNSArray:(NSArray *)array
                  result:(NSMutableString **)result
                   error:(NSError *__autoreleasing *)error {
    [*result appendString: @"["];
    if ([array count] > 0) {
        [*result appendString:[self lineSeparator]];
        [self incrementDepth];
        for (id item in array) {
            [*result appendString: [self buildLineIndentation]];
            [self serializeObject:item result:result error:error];
            // Check if serializeObject method was ended with error and handle it
            if (!!error && *error != nil) {
                *result = nil;
                break;
            }
            if (item != [array lastObject]) {
                [*result appendFormat: @"%@ ", ELEMENTS_SEPARATOR_SYMBOL];
                [*result appendString:[self lineSeparator]];
            }
        }
        [self decrementDepth];
        [*result appendString:[self lineSeparator]];
        [*result appendString: [self buildLineIndentation]];
    }
    [*result appendString: @"]"];
}

+ (void)serializeNSSet:(NSSet *)set
                result:(NSMutableString **)result
                 error:(NSError *__autoreleasing *)error {
    NSArray *tempArray = [set allObjects];
    [self serializeNSArray:tempArray result:result error:error];
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
        NSDictionary *tempDict = @{@"width": @(rect.size.width),
                                   @"height": @(rect.size.height),
                                   @"x": @(rect.origin.x),
                                   @"y": @(rect.origin.y)};
        [self serializeNSDictionary:tempDict result:result error:nil];
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

+ (NSString *)buildLineIndentation {
    NSMutableString *indentation = [[NSMutableString alloc] init];
    NSInteger depth = [self depth];
    for (int i = 0; i < depth; i++) {
        [indentation appendString:[self lineIndentation]];
    }
    return indentation;
}

+ (void)configureOutputOption:(BOOL)isOneLined {
    if (isOneLined) {
        [[[NSThread currentThread] threadDictionary] setValue:@"" forKey:CONFIG_LINE_SEPARATOR_KEY];
        [[[NSThread currentThread] threadDictionary] setValue:@"" forKey:CONFIG_LINE_INDENTATION_KEY];
    }
    else {
        [[[NSThread currentThread] threadDictionary] setValue:LINE_SEPARATOR forKey:CONFIG_LINE_SEPARATOR_KEY];
        [[[NSThread currentThread] threadDictionary] setValue:LINE_INDENTATION forKey:CONFIG_LINE_INDENTATION_KEY];
    }
}

+ (NSString *)lineSeparator {
    return [[[NSThread currentThread] threadDictionary] valueForKey:CONFIG_LINE_SEPARATOR_KEY];
}

+ (NSString *)lineIndentation {
    return [[[NSThread currentThread] threadDictionary] valueForKey:CONFIG_LINE_INDENTATION_KEY];
}

+ (NSInteger)depth {
    return [[[[NSThread currentThread] threadDictionary] valueForKey:CONFIG_DEPTH_KEY] integerValue];
}

+ (void)setDepth:(NSInteger)depthValue {
    [[[NSThread currentThread] threadDictionary] setValue:[NSNumber numberWithInteger:depthValue] forKey:CONFIG_DEPTH_KEY];
}

+ (void)incrementDepth {
    [self setDepth:[self depth] + 1];
}

+ (void)decrementDepth {
    [self setDepth:[self depth] - 1];
}

@end
