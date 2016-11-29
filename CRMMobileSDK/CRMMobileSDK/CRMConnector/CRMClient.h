//  CRMClient.h

#import <Foundation/Foundation.h>
#import "OrganizationRequest.h"
#import "OrganizationResponse.h"
#import "Entity.h"
#import "EntityCollection.h"

typedef void(^AuthCallback)(id result);
typedef void(^LogoutCallback)(BOOL completed);

@interface CRMClient : NSObject

+ (instancetype)clientWithClientID:(NSString *)clientId redirectURI:(NSString *)redirectURI;
+ (instancetype)sharedClient;

- (void)loginWithEndpoint:(NSString *)endpoint completion:(AuthCallback)completion;
- (void)logoutForEndpoint:(NSString *)endpoint completion:(LogoutCallback)completion;

- (void)execute:(OrganizationRequest *)request withCompletionBlock:(void (^) (OrganizationResponse *response, NSError *error))completionBlock;
- (void)executeRaw:(OrganizationRequest *)request withCompletionBlock:(void (^) (NSData *data, NSError *error))completionBlock;
- (void)getMetadataWithCompletionBlock:(void (^) (NSData *data, NSError *error))completionBlock;

- (void)create:(Entity *)entity completionBlock:(void (^) (NSUUID *id, NSError *error))completionBlock;
- (void)update:(Entity *)entity completionBlock:(void (^) (NSError *error))completionBlock;
- (void)delete:(NSString *)schemaName id:(NSUUID *)id completionBlock:(void (^) (NSError *error))completionBlock;
- (void)retrieve:(NSString *)schemaName id:(NSUUID *)id attributes:(NSDictionary *)attributes completionBlock:(void (^) (Entity *entity, NSError *error))completionBlock;
- (void)retrieveMultiple:(NSString *)schemaName attributes:(NSDictionary *)attributes completionBlock:(void (^) (EntityCollection *entities, NSError *error))completionBlock;
- (void)retrieveMultipleRaw:(NSString *)schemaName
                 attributes:(NSArray *)attributes
           filterExpression:(NSString *)filterExpression
          orderByExpression:(NSString *)orderByExpression
                        top:(NSString *)top
                       skip:(NSString *)skip
            completionBlock:(void (^) (NSData *data, NSError *error))completionBlock;
- (void)retrieveWithURL:(NSString *)URL completionBlock:(void (^) (NSData *data, NSError *error))completionBlock;

@end
