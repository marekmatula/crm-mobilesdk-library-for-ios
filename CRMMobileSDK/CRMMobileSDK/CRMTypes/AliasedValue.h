#import "SOAPParser.h"


@interface AliasedValue : NSObject <SOAPParser>

@property id value;

- (instancetype)initWithValue:(id)value;

@end
