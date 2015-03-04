#import <Foundation/Foundation.h>

@interface Serializer : NSObject

@property (copy, nonatomic) NSString *singleLineIndentation; // Single indentation for a line
@property (copy, nonatomic, readonly) NSString *lineIndentation; // Total indentation for a line
@property (copy, nonatomic) NSString *lineSeparator;
@property (assign, nonatomic) NSInteger depth;

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
+ (NSString *)serializeDictionary:(id)dictionary error:(NSError **)error;

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
                            error:(NSError *__autoreleasing *)error;

@end
