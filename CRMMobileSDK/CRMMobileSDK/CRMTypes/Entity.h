//  Entity.h

#import "EntityReference.h"
#import "RelatedEntityCollection.h"
#import "SOAPParser.h"

@interface Entity : NSObject <JSONGenerator, SOAPGenerator, SOAPParser>

@property (nonatomic, strong) NSUUID *id;
@property (nonatomic, strong, readonly) NSString *logicalName;

@property (nonatomic, strong) NSMutableDictionary *attributes;
@property (nonatomic, strong) NSMutableDictionary *formattedValues;

@property (nonatomic, strong) RelatedEntityCollection *relatedEntities;

- (instancetype)initWithLogicalName:(NSString *)logicalName;
- (instancetype)initWithDictionary:(NSDictionary *)dict fields:(NSDictionary *)fields;

- (id)objectForKeyedSubscript:(id <NSCopying>)key;
- (void)setObject:(id <SOAPGenerator>)obj forKeyedSubscript:(id <NSCopying>)key;

- (bool)contains:(NSString *)attributeName;
- (id)toEntity:(Class)entityType;
- (EntityReference *)toEntityReference;

+ (NSString *)entityLogicalName;
+ (NSString *)entityIdAttribute;
+ (NSString *)entityClassName;
+ (NSNumber *)entityTypeCode;

@end
