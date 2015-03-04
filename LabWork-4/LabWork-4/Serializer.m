#import "Serializer.h"

static NSString *const KEY_WRAPPER_SYMBOL = @"\"";
static NSString *const ELEMENTS_SEPARATOR_SYMBOL = @",";
static NSString *const DEFAULT_LINE_SEPARATOR = @"\n";
static NSString *const DEFAULT_LINE_INDENTATION = @"    ";
static NSString *const ERROR_DOMAIN = @"ru.kostya.Serializer";
typedef NS_ENUM(NSInteger, ErrorCode) {
    UNSUPPORTED_PARAMETER = 1, // Passed object is not a dictionary
    OBJECT_OF_INVALID_TYPE = 2, // Passed dictionary contains an object of invalid type
    INVALID_KEY_TYPE = 3, // One of the keys has invalid type
    INVALID_NSVALUE = 4 // NSValue doesn't contain CGRect struct
};

@implementation Serializer

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _singleLineIndentation = DEFAULT_LINE_INDENTATION;
        _lineIndentation = @"";
        _lineSeparator = DEFAULT_LINE_SEPARATOR;
        _depth = 0;
    }
    return self;
}

// Set depth value and recalculate line total indentation
- (void)setDepth:(NSInteger)depth {
    _depth = depth;
    _lineIndentation = [self buildLineIndentation];
}

+ (NSString *)serializeDictionary:(id)dictionary error:(NSError *__autoreleasing *)error {
    return [self serializeDictionary:dictionary byOneLine:NO error:error];
}

+ (NSString *)serializeDictionary:(id)dictionary
                        byOneLine:(BOOL)isOneLined
                            error:(NSError *__autoreleasing *)error {
    // Initialize serializer instance and configure it if output option set to 'one lined'
    Serializer *serializer = [[self alloc] init];
    if (isOneLined) {
        serializer.singleLineIndentation = @"";
        serializer.lineSeparator = @"";
    }
    
    // Check that passed object is actually NSDictionary
    if ([dictionary isKindOfClass:[NSDictionary class]]) {
        return [serializer serializeObject:dictionary error:error];
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

- (NSString *)serializeObject:(id)object
                        error:(NSError *__autoreleasing *)error {
    NSMutableString *result = [[NSMutableString alloc] init];
    NSString *tmpResult = @"";
    // Check that passed object has one of the supperted types and handle it appropriately
    if ([object isKindOfClass:[NSDictionary class]]) {
        tmpResult = [self serializeNSDictionary:(NSDictionary *)object error:error];
    }
    else if ([object isKindOfClass:[NSArray class]]) {
        tmpResult = [self serializeNSArray:(NSArray *)object error:error];
    }
    else if ([object isKindOfClass:[NSSet class]]) {
        tmpResult = [self serializeNSSet:(NSSet *)object error:error];
    }
    else if ([object isKindOfClass:[NSNumber class]]) {
        tmpResult = [self serializeNSNumber:(NSNumber *)object];
    }
    else if ([object isKindOfClass:[NSNull class]]) {
        tmpResult = [self serializeNSNull:(NSNull *)object];
    }
    else if ([object isKindOfClass:[NSValue class]]) {
        tmpResult = [self serializeCGRect:(NSValue *)object error:error];
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
    if (!!error && *error != nil) {
        return nil;
    }
    else {
        return [result stringByAppendingString:tmpResult];
    }
}

- (NSString *)serializeNSDictionary:(NSDictionary *)dictionary
                        error:(NSError *__autoreleasing *)error {
    NSMutableString *result = [[NSMutableString alloc] init];
    [result appendString:@"{"];
    [result appendString:self.lineSeparator];
    self.depth++;
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
            return nil;
        }
        else {
            [result appendString:self.lineIndentation];
            [result appendFormat:@"%@%@%@: ", KEY_WRAPPER_SYMBOL, key, KEY_WRAPPER_SYMBOL];
            NSString *tmpResult = [self serializeObject:dictionary[key] error:error];
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
                return nil;
            }
            else {
                [result appendString:tmpResult];
                if (key != [dictionaryKeys lastObject]) {
                    [result appendFormat:@"%@ ", ELEMENTS_SEPARATOR_SYMBOL];
                    [result appendString:self.lineSeparator];
                }
            }
        }
    }
    self.depth--;
    [result appendString:self.lineSeparator];
    [result appendString:self.lineIndentation];
    [result appendString:@"}"];
    return result;
}

- (NSString *)serializeNSArray:(NSArray *)array
                   error:(NSError *__autoreleasing *)error {
    NSMutableString *result = [[NSMutableString alloc] init];
    [result appendString:@"["];
    if ([array count] > 0) {
        [result appendString:self.lineSeparator];
        self.depth++;
        for (id item in array) {
            [result appendString:self.lineIndentation];
            NSString *tmpResult = [self serializeObject:item error:error];
            // Check if serializeObject method was ended with error and handle it
            if (!!error && *error != nil) {
                return nil;
            }
            else {
                [result appendString:tmpResult];
                if (item != [array lastObject]) {
                    [result appendFormat:@"%@ ", ELEMENTS_SEPARATOR_SYMBOL];
                    [result appendString:self.lineSeparator];
                }
            }
        }
        self.depth--;
        [result appendString:self.lineSeparator];
        [result appendString:self.lineIndentation];
    }
    [result appendString:@"]"];
    return result;
}

- (NSString *)serializeNSSet:(NSSet *)set
                 error:(NSError *__autoreleasing *)error {
    NSArray *tempArray = [set allObjects];
    return [self serializeNSArray:tempArray error:error];
}

- (NSString *)serializeNSNumber:(NSNumber *)number {
    return [number stringValue];
}

- (NSString *)serializeNSNull:(NSNull *)null {
    return @"null";
}

- (NSString *)serializeCGRect:(NSValue *)value
                  error:(NSError *__autoreleasing *)error {
    // Check that NSValue actualy contains CGRect
    if (strcmp([value objCType], @encode(CGRect)) == 0) {
        CGRect rect = [value rectValue];
        NSDictionary *tempDict = @{@"width": @(rect.size.width),
                                   @"height": @(rect.size.height),
                                   @"x": @(rect.origin.x),
                                   @"y": @(rect.origin.y)};
        return [self serializeNSDictionary:tempDict error:nil];
    }
    else {
        if (!!error) {
            NSString *const failureReason =
            @"Received NSValue object doesn't contain CGRect structure.";
            NSDictionary *const userInfo = @{NSLocalizedDescriptionKey:
                                                 NSLocalizedString(failureReason, nil)};
            *error = [NSError errorWithDomain:ERROR_DOMAIN code:INVALID_NSVALUE userInfo:userInfo];
        }
        return nil;
    }
}

- (NSString *)buildLineIndentation {
    NSMutableString *indentation = [[NSMutableString alloc] init];
    for (int i = 0; i < self.depth; i++) {
        [indentation appendString:self.singleLineIndentation];
    }
    return indentation;
}

@end
