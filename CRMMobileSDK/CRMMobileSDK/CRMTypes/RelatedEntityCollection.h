//  RelatedEntityCollection.h

//#import "EntityReference.h"
#import <Foundation/Foundation.h>
#import "SOAPGenerator.h"
#import "SOAPParser.h"

@interface RelatedEntityCollection : NSObject <SOAPGenerator, SOAPParser>
//@interface RelatedEntityCollection : NSObject <JSONGenerator, SOAPGenerator, SOAPParser>

@property (nonatomic, strong) NSDictionary *items;

@end
