//
//  SFUserAccountManagerNew.h
//  SalesforceSDKCore
//
//  Created by Kevin Hawkins on 9/7/16.
//  Copyright © 2016 salesforce.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFUserAccountNew.h"

@class SFUserAccountManagerNew;

/**
 Protocol for handling callbacks from SFUserAccountManager.
 */
@protocol SFUserAccountManagerDelegateNew <NSObject>

@optional

/**
 Called before the user account manager switches from one user to another.
 @param userAccountManager The SFUserAccountManager instance making the switch.
 @param fromUser The user being switched away from.
 @param toUser The user to be switched to.  `nil` if the user context is being switched back
 to no user.
 */
- (void)userAccountManager:(nonnull SFUserAccountManagerNew *)userAccountManager
        willSwitchFromUser:(nullable SFUserAccountNew *)fromUser
                    toUser:(nullable SFUserAccountNew *)toUser;

/**
 Called after the user account manager switches from one user to another.
 @param userAccountManager The SFUserAccountManager instance making the switch.
 @param fromUser The user that was switched away from.
 @param toUser The user that was switched to.  `nil` if the user context is being switched back
 to no user.
 */
- (void)userAccountManager:(nonnull SFUserAccountManagerNew *)userAccountManager
         didSwitchFromUser:(nullable SFUserAccountNew *)fromUser
                    toUser:(nullable SFUserAccountNew *)toUser;

@end

@interface SFUserAccountManagerNew : NSObject

+ (nullable instancetype)sharedInstance;

@end
