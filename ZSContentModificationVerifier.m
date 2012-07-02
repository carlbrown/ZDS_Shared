//
//  ZSContentModificationVerifier.m
//  AssetManagerTest
//
//  Created by Carl Brown on 7/2/12.
//  Copyright (c) 2012 Zarra Studios LLC. All rights reserved.
//

#import "ZSContentModificationVerifier.h"

extern NSInteger activityCount;

extern void incrementNetworkActivity(id sender);
extern void decrementNetworkActivity(id sender);

@interface ZSContentModificationVerifier ()
-(NSString *) modificationDictionaryFilePath;
@end

@implementation ZSContentModificationVerifier

@synthesize connection = _connection;
@synthesize myURL = _myURL;
@synthesize filePath = _filePath;
@synthesize request = _request;
@synthesize response = _response;

-(NSString *) modificationDictionaryFilePath {
  return [[self filePath] stringByAppendingPathExtension:@".modified.plist"];
}

-(BOOL) hasContentChangedForURL: (NSURL *) theURL forFilePath: (NSString *) theFilePath {
  BOOL shouldReDownloadFile=YES;
  
  
  if (![[NSFileManager defaultManager] fileExistsAtPath:theFilePath]) {
    //No data saved for this URL, must re-download
    return YES;
  }

  [self setFilePath:theFilePath];

  if (![[NSFileManager defaultManager] fileExistsAtPath:[self modificationDictionaryFilePath]]) {
    //No modification info file saved for this URL, must re-download
    return YES;
  }
  
  NSDictionary *modificationDict = [NSDictionary dictionaryWithContentsOfFile:[self modificationDictionaryFilePath]];
  if (!modificationDict) {
    //Saved file is bogus
    return YES;
  }
  
  if ([modificationDict objectForKey:@"Etag"]==nil && [modificationDict objectForKey:@"Last-Modified"]==nil) {
    //Saved file is bogus
    return YES;
  }
  
  [self setMyURL:theURL];

  NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:[self myURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5];

  [theRequest setHTTPMethod:@"HEAD"];
  
  [self setRequest:theRequest];
  
  incrementNetworkActivity(self);
  
  [self setConnection:[NSURLConnection connectionWithRequest:theRequest delegate:self]];
  
  CFRunLoopRun();
  
  if ([self response]==nil || [[self response] allHeaderFields]==nil) {
    //No headers to check
    return YES;
  }
  
  NSString *currentEtag =[[[self response] allHeaderFields] objectForKey:@"ETag"];
  NSString *currentModifiedDate =[[[self response] allHeaderFields] objectForKey:@"Last-Modified"];
  
  if (currentEtag && currentModifiedDate) {
    if ([currentEtag isEqualToString:[modificationDict objectForKey:@"ETag"]]
        && [currentModifiedDate isEqualToString:[modificationDict objectForKey:@"Last-Modified"]]) {
      shouldReDownloadFile = NO;
    }
  } else if (currentModifiedDate) {
    if ([currentModifiedDate isEqualToString:[modificationDict objectForKey:@"Last-Modified"]]) {
      shouldReDownloadFile = NO;
    }
  } else if (currentEtag) {
    if ([currentEtag isEqualToString:[modificationDict objectForKey:@"ETag"]]) {
      shouldReDownloadFile = NO;
    }
  }
  
  decrementNetworkActivity(self);

  return shouldReDownloadFile;
}

-(void) saveModificationDetailsForResponse: (NSHTTPURLResponse *) theResponse forFilePath: (NSString *) theFilePath {
  NSMutableDictionary *modificationDict = [NSMutableDictionary dictionaryWithCapacity:2];
  BOOL thereSomethingToSave=NO;
  [self setFilePath:theFilePath];
  
  if ([[theResponse allHeaderFields] objectForKey:@"ETag"]) {
    [modificationDict setObject:[[theResponse allHeaderFields] objectForKey:@"ETag"] forKey:@"Etag"];
    thereSomethingToSave=YES;
  }
  if ([[theResponse allHeaderFields] objectForKey:@"Last-Modified"]) {
    [modificationDict setObject:[[theResponse allHeaderFields] objectForKey:@"Last-Modified"] forKey:@"Last-Modified"];
    thereSomethingToSave=YES;
  }

  if (thereSomethingToSave) {
    [modificationDict writeToFile:[self modificationDictionaryFilePath] atomically:YES];
  }
}

-(void) finish {
  CFRunLoopStop(CFRunLoopGetCurrent());
}

-(void) cancel {
  [[self connection] cancel];
  [self finish];
}

//See http://sutes.co.uk/2009/12/nsurlconnection-using-head-met.html for explanation
- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)redirectResponse
{
  if ([[request HTTPMethod] isEqualToString:@"HEAD"])
    return request;
  
  NSMutableURLRequest *newRequest = [request mutableCopy];
  [newRequest setHTTPMethod:@"HEAD"];
  
  return [newRequest autorelease];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
  [self finish];
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSHTTPURLResponse*)resp
{
  [self setResponse:resp];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)newData
{
  NSLog(@"WARNING: We shouldn't be receiving data on a HEAD call");
  [self finish];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
  [self finish];
}


@end
