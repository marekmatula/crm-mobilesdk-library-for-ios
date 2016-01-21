#import "AliasedValue.h"
#import "SOAPMapper.h"


@implementation AliasedValue

- (instancetype)init
{
  return [self initWithValue:nil];
}

- (instancetype)initWithValue:(id)value
{
  self = [super init];
  if (self)
  {
    self.value = value;
  }
  
  return self;
}

+ (instancetype)instanceWithObject:(NSObject *)obj
{
  if (![obj isKindOfClass:[NSArray class]])
  {
    return nil;
  }
  
  NSObject *wrappedValue = nil;
  NSObject *value = [SOAPMapper oneForKey:@"Value" inArray:(NSArray *)obj];
  NSArray *attributes = [SOAPMapper attributesForKey:@"Value" inArray:(NSArray *)obj];
  NSString *type = (NSString *)[SOAPMapper oneForKey:@"type" inArray:attributes];
  
  if (value != nil && type != nil)
  {
    Class class = [SOAPMapper classForType:type];
    wrappedValue = [class instanceWithObject:value];
  }
  
  return [[AliasedValue alloc] initWithValue:wrappedValue];
}

@end
