//
//  SFUserAccountManagerNew.m
//  SalesforceSDKCore
//
//  Created by Kevin Hawkins on 9/7/16.
//  Copyright © 2016 salesforce.com. All rights reserved.
//

#import "SFUserAccountManagerNew+Internal.h"
#import "SFDirectoryManager.h"

@implementation SFUserAccountManagerNew

+ (instancetype)sharedInstance {
    static dispatch_once_t pred;
    static SFUserAccountManagerNew *userAccountManager = nil;
    dispatch_once(&pred, ^{
        userAccountManager = [[self alloc] init];
    });
    return userAccountManager;
}

- (id)init {
    self = [super init];
    if (self) {
        _delegates = [NSHashTable weakObjectsHashTable];
        _userAccountMap = [[NSMutableDictionary alloc] init];
        _accountIOQueue = dispatch_queue_create(kSFSDKAccountIOQueueName, DISPATCH_QUEUE_SERIAL);
        NSError *loadAccountsError = nil;
        BOOL loadSuccess = [self loadAccounts:&loadAccountsError];
        if (!loadSuccess) {
            NSString *errorMessage = loadAccountsError ? loadAccountsError.localizedDescription : @"Unknown error loading accounts";
            [self log:SFLogLevelError format:@"Error loading user accounts: %@", errorMessage];
            self = nil;
        }
    }
    return self;
}

#pragma mark - Private methods

- (BOOL)loadAccounts:(NSError **)error {
    dispatch_sync(self.accountIOQueue, ^{
        NSError *localIOError = nil;
        
        // Make sure we start from a blank state
        [self clearAllAccountState];
        
        // Get the root directory, usually ~/Library/<appBundleId>/
        NSString *rootDirectory = [[SFDirectoryManager sharedManager] directoryForUser:nil type:NSLibraryDirectory components:nil];
        NSFileManager *fm = [[NSFileManager alloc] init];
        if (![fm fileExistsAtPath:rootDirectory]) {
            // There is no root directory, that's fine, probably a fresh app install,
            // new user will be created later on.
            return YES;
        }
        
        // Now iterate over the org and then user directories to load
        // each individual user account file.
        // ~/Library/<appBundleId>/<orgId>/<userId>/UserAccount.plist
        NSArray *rootContents = [fm contentsOfDirectoryAtPath:rootDirectory error:&localIOError];
        if (nil == rootContents) {
            NSString *rootContentsErrorMessage = (localIOError ? localIOError.localizedDescription : @"Unknown error");
            if (error != nil) *error = localIOError;
            [self log:SFLogLevelError format:@"Unable to enumerate the content at %@: %@", rootDirectory, rootContentsErrorMessage];
            
            return NO;
        }
        for (NSString *rootContent in rootContents) {
            
            // Ignore content that don't represent an organization or an anonymous org
            if (![rootContent hasPrefix:kOrgPrefix] && ![rootContent isEqualToString:SFUserAccountManagerAnonymousUserAccountOrgId]) continue;
            NSString *rootPath = [rootDirectory stringByAppendingPathComponent:rootContent];
            
            // Fetch the content of the org directory
            NSArray *orgContents = [fm contentsOfDirectoryAtPath:rootPath error:error];
            if (nil == orgContents) {
                if (error) {
                    [self log:SFLogLevelDebug format:@"Unable to enumerate the content at %@: %@", rootPath, *error];
                }
                continue;
            }
            
            for (NSString *orgContent in orgContents) {
                
                // Ignore content that don't represent a user or an anonymous user
                if (![orgContent hasPrefix:kUserPrefix] && ![orgContent isEqualToString:SFUserAccountManagerAnonymousUserAccountUserId]) continue;
                NSString *orgPath = [rootPath stringByAppendingPathComponent:orgContent];
                
                // Now let's try to load the user account file in there
                NSString *userAccountPath = [orgPath stringByAppendingPathComponent:kUserAccountPlistFileName];
                if ([fm fileExistsAtPath:userAccountPath]) {
                    SFUserAccount *userAccount = [self loadUserAccountFromFile:userAccountPath];
                    if (userAccount) {
                        [self addAccount:userAccount];
                    } else {
                        // Error logging will already have occurred.  Make sure account file data is removed.
                        [fm removeItemAtPath:userAccountPath error:nil];
                    }
                } else {
                    [self log:SFLogLevelDebug format:@"There is no user account file in this user directory: %@", orgPath];
                }
            }
        }
        
        // Convert any legacy active user data to the active user identity.
        [SFUserAccountManagerUpgrade updateToActiveUserIdentity:self];
        
        SFUserAccountIdentity *curUserIdentity = self.activeUserIdentity;
        
        // In case the most recently used account was removed, or the most recent account is the temporary account,
        // see if we can load another available account.
        if (nil == curUserIdentity || [curUserIdentity isEqual:self.temporaryUserIdentity]) {
            for (SFUserAccount *account in self.userAccountMap.allValues) {
                if (account.credentials.userId) {
                    curUserIdentity = account.accountIdentity;
                    break;
                }
            }
        }
        if (nil == curUserIdentity) {
            [self log:SFLogLevelInfo msg:@"Current active user identity is nil"];
        }
        
        self.previousCommunityId = self.activeCommunityId;
        
        if (curUserIdentity){
            SFUserAccount *account = [self userAccountForUserIdentity:curUserIdentity];
            account.communityId = self.previousCommunityId;
            self.currentUser = account;
        }else{
            self.currentUser = nil;
        }
        
        // update the client ID in case it's changed (via settings, etc)
        self.currentUser.credentials.clientId = self.oauthClientId;
        
        [self userChanged:SFUserAccountChangeCredentials];
        
        return YES;
    });
}

- (void)clearAllAccountState {
    [self.userAccountMap removeAllObjects];
}

@end
