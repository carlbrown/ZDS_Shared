//
//  ZSContentModificationVerifier.h
//  AssetManagerTest
//
//  Created by Carl Brown on 7/2/12.
//  Copyright (c) 2012 Zarra Studios LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZSContentModificationVerifier : NSObject

@property (nonatomic, retain) NSString *filePath;
@property (nonatomic, retain) NSURL *myURL;
@property (nonatomic, retain) NSHTTPURLResponse *response;
@property (nonatomic, assign) NSURLConnection *connection;
@property (nonatomic, assign) NSMutableURLRequest *request;

-(BOOL) hasContentChangedForURL: (NSURL *) theURL forFilePath: (NSString *) theFilePath;
-(void) saveModificationDetailsForResponse: (NSHTTPURLResponse *) theResponse forFilePath: (NSString *) theFilePath;
-(void) cancel;
-(void) finish;

@end
