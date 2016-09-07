//
//  SFUserAccountManagerNew.h
//  SalesforceSDKCore
//
//  Created by Kevin Hawkins on 9/7/16.
//  Copyright © 2016 salesforce.com. All rights reserved.
//

#import "SFUserAccountManagerNew.h"
#import "SFUserAccountIdentity.h"

static const char  * _Nonnull kSFSDKAccountIOQueueName = "com.salesforce.userAccountManager.accountIOQueue";

@interface SFUserAccountManagerNew ()

@property (nonatomic, strong, nonnull) NSHashTable<id<SFUserAccountManagerDelegateNew>> *delegates;
@property (nonatomic, strong, nonnull) NSMutableDictionary<SFUserAccountIdentity*, SFUserAccountManagerNew*> *userAccountMap;
@property (nonatomic, strong, nonnull) dispatch_queue_t accountIOQueue;

@end
