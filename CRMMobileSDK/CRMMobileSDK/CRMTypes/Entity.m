//  Entity.m

#import <objc/runtime.h>
#import "Entity.h"
#import "JSONParser.h"
#import "SOAPMapper.h"
#import "NSUUID+CRMUUID.h"
#import "NSString+XMLEncode.h"

@interface Entity()

@property (nonatomic, strong) NSString *logicalName;

@end

@implementation Entity

- (instancetype)init
{
	return [self initWithLogicalName:[[self class] entityLogicalName]];
}

- (instancetype)initWithLogicalName:(NSString *)logicalName
{
	self = [super init];
	if (self) {
		self.attributes = [NSMutableDictionary dictionary];
		self.formattedValues = [NSMutableDictionary dictionary];
        self.relatedEntities = [[RelatedEntityCollection alloc] init];
		self.logicalName = logicalName;
	}
	
	return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict fields:(NSDictionary *)fields;
{
    self = [self initWithLogicalName:[[self class] entityLogicalName]];

    NSDictionary *attributes = dict[@"d"];
    if (!attributes) {
        attributes = dict;
    }

    if (attributes) {
        //NSMutableDictionary *attsDict = [NSMutableDictionary dictionary];
        for (NSString* key in fields) {
            //id attribute = [dict objectForKey:key];
            NSObject *attribute = attributes[key];
            NSObject *className = fields[key];
            // NSLog(@"JSON attribute %@ : %@", key, attribute);

            Class valueClass = NSClassFromString(className);

            if (attribute && [valueClass conformsToProtocol:@protocol(JSONParser)]) {
                id value = [valueClass instanceWithJSONObject:attribute];

                if (value && ![value isKindOfClass:[NSNull class]]) {
                    // [self setValue:value forKey:key];
                    [self setObject:value forKeyedSubscript:key];
                }
            }
        }

        NSString *idKey = [[self class] entityIdAttribute];
        NSObject *idVal = attributes[idKey];
        self.id = [NSUUID instanceWithJSONObject:idVal];
    }

    return self;
}

- (id)objectForKeyedSubscript:(id <NSCopying>)key
{
	return [self.attributes valueForKey:(NSString *)key];
}

- (void)setObject:(id <SOAPGenerator>)obj forKeyedSubscript:(id <NSCopying>)key;
{
	[self.attributes setValue:obj forKey:(NSString *)key];
}

- (bool)contains:(NSString *)attributeName
{
	return [[self.attributes allKeys] indexOfObject:attributeName] != NSNotFound;
}

- (id)toEntity:(Class)entityType
{
	if (![entityType isSubclassOfClass:[Entity class]]) {
		[NSException raise:@"Invalid Type" format:@"The class must be a subclass of Entity"];
	}
	
	if (![[entityType entityLogicalName] isEqualToString:self.logicalName]) {
		NSString *currentClass = NSStringFromClass([self class]);
		NSString *newClass = NSStringFromClass(entityType);
		
		[NSException raise:@"Invalid Type" format:@"Cannot convert entity %@ to %@", currentClass, newClass];
	}
	
	id entity = [[entityType alloc] init];
	
	[(Entity *)entity setId:self.id];
	[(Entity *)entity setAttributes:self.attributes];
	[(Entity *)entity setFormattedValues:self.formattedValues];
    [(Entity *)entity setRelatedEntities:self.relatedEntities];
	
	return entity;
}

- (EntityReference *)toEntityReference
{
	return [[EntityReference alloc] initWithLogicalName:self.logicalName id:self.id];
}

- (NSObject *)generateJSON
{
    Class class = [self class];
    
    if (![class isSubclassOfClass:[Entity class]]) {
        [NSException raise:@"Invalid Type" format:@"The class must be a subclass of Entity"];
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    for (id key in [self.attributes allKeys]) {
        id value = self.attributes[key];

        if (![value conformsToProtocol:@protocol(JSONGenerator)]) {
            [NSException raise:@"Invalid Attribute Type"
                        format:@"Attribute \"%@\" does not conform to JSONGenerator protocol.", key];
        }

        id val = [value generateJSON];

        if (val) {
            dict[key] = val;
        }
    }

    return dict;
}

- (NSString *)generateSOAP
{
    return [NSString stringWithFormat:
            @"<b:value i:type=\"a:Entity\">"
                "%@"
            "</b:value>",
            [self generateSOAPInternal]];
}

- (NSString *)generateSOAPForArray
{
    return [NSString stringWithFormat:
            @"<a:Entity>"
                "%@"
            "</a:Entity>",
            [self generateSOAPInternal]];
}

- (NSString *)generateSOAPInternal
{
    NSString *attributes = @"";
    for (id key in [self.attributes allKeys]) {
        id value = self.attributes[key];
        
        if (![value conformsToProtocol:@protocol(SOAPGenerator)]) {
            [NSException raise:@"Invalid Attribute Type"
                        format:@"Attribute \"%@\" does not conform to SOAPGenerator protocol.", key];
        }
        
        NSString *valueSOAP = (value == nil) ? @"<b:value i:nil=\"true\" />" : [value generateSOAP];
        
        NSString *attrSOAP = [NSString stringWithFormat:
                              @"<a:KeyValuePairOfstringanyType>"
                                "<b:key>%@</b:key>"
                                "%@"
                              "</a:KeyValuePairOfstringanyType>",
                              [key xmlEncode], valueSOAP];
        attributes = [attributes stringByAppendingString:attrSOAP];
    }
    
    NSUUID *id = (self.id == nil) ? [NSUUID emptyUUID] : self.id;
    
    return [NSString stringWithFormat:
            @"<a:Attributes>%@</a:Attributes>"
            "<a:EntityState i:nil=\"true\" />"
            "<a:FormattedValues />"
            "<a:Id>%@</a:Id>"
            "<a:LogicalName>%@</a:LogicalName>"
            "<a:RelatedEntities>%@</a:RelatedEntities>",
            attributes, [id UUIDString], [self.logicalName xmlEncode], [self.relatedEntities generateSOAP]];
}

+ (instancetype)instanceWithObject:(NSObject *)obj
{
    if (![obj isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    Entity *entity = [[Entity alloc] init];
    
    NSArray *objArray = (NSArray *)obj;
    entity.logicalName = (NSString *)[SOAPMapper oneForKey:@"LogicalName" inArray:objArray];
    entity.id = [NSUUID instanceWithObject:[SOAPMapper oneForKey:@"Id" inArray:objArray]];
    
    NSArray *attributes = (NSArray *)[SOAPMapper oneForKey:@"Attributes" inArray:objArray];
    if (attributes) {
        NSMutableDictionary *attsDict = [NSMutableDictionary dictionary];
        [SOAPMapper forKey:@"KeyValuePairOfstringanyType" inArray:attributes with:^(NSObject *keyValuePair) {
            NSString *key = (NSString *)[SOAPMapper oneForKey:@"key" inArray:(NSArray *)keyValuePair];
            NSObject *value = [SOAPMapper oneForKey:@"value" inArray:(NSArray *)keyValuePair];
            
            NSArray *attributes = [SOAPMapper attributesForKey:@"value" inArray:(NSArray *)keyValuePair];
            NSString *type = (NSString *)[SOAPMapper oneForKey:@"type" inArray:attributes];
            
            if (value != nil && type != nil) {
                Class class = [SOAPMapper classForType:type];
                attsDict[key] = [class instanceWithObject:value];
            }
        }];
        entity.attributes = attsDict;
    }
    
    NSArray *formattedValues = (NSArray *)[SOAPMapper oneForKey:@"FormattedValues" inArray:objArray];
    if (formattedValues) {
        NSMutableDictionary *fvsDict = [NSMutableDictionary dictionary];
        [SOAPMapper forKey:@"KeyValuePairOfstringstring" inArray:formattedValues with:^(NSObject *keyValuePair) {
            NSString *key = (NSString *)[SOAPMapper oneForKey:@"key" inArray:(NSArray *)keyValuePair];
            NSString *value = (NSString *)[SOAPMapper oneForKey:@"value" inArray:(NSArray *)keyValuePair];
            if (value != nil) {
                Class class = [SOAPMapper classForType:@"string"];
                fvsDict[key] = [class instanceWithObject:value];
            }
        }];
        entity.formattedValues = fvsDict;
    }
    
    NSArray *relatedEntities = (NSArray *)[SOAPMapper oneForKey:@"RelatedEntities" inArray:objArray];
    if (relatedEntities) {
        entity.relatedEntities = [RelatedEntityCollection instanceWithObject:relatedEntities];
    }
    
    return entity;
}

+ (NSString *)entityLogicalName
{
    return nil;
}

+ (NSString *)entitySetName
{
    return nil;
}

+ (NSString *)entityIdAttribute
    {
        return nil;
    }

+ (NSString *)entityClassName
    {
        NSString *className = NSStringFromClass([self class]);
        //className = [[className componentsSeparatedByString:@"."] lastObject];
        return  className;
    }

+ (NSNumber *)entityTypeCode
{
    return [NSNumber numberWithInt:0];
}

@end
