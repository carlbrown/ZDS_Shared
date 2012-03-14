/*
 *  ZSBackoffHandler.m
 *  ExpBkOffTest
 *  
 *  Created by Carl Brown on 3/13/12.
 *  Copyright (c) 2012 PDAgent, LLC. All rights reserved.
 *
 *  Implementation of a backoff handler similar in philosophy
 *  to RFC2988. The idea is to delay network activity in the 
 *  presence of network congestion in an exponential fashion
 *  so that all clients might make the most of whatever bandwidth
 *  is available.
 *  It's primarily intended to be useful when there are large 
 *  numbers of clients trying to access a service at the same
 *  time (e.g. Apps designed to be used at a crowded conference 
 *  or sporting event where cellular bandwidth is stressed, or
 *  at a specific time, like a newsstand App where a large number
 *  of clients sharing the same cellular bandwidth all wake up at 
 *  the same specific time of day to grab new content)
 *
 *  Permission is hereby granted, free of charge, to any person
 *  obtaining a copy of this software and associated documentation
 *  files (the "Software"), to deal in the Software without
 *  restriction, including without limitation the rights to use,
 *  copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following
 *  conditions:
 *
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 *  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 *  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 *  OTHER DEALINGS IN THE SOFTWARE.
 *
 */

#ifndef ISRETINADISPLAY
#import "ZSConstants.h"
#endif

#import "ZSBackoffHandler.h"


#pragma - Constants to tweak

/* These parameters may need to be experimentally tweaked */

//Constants as per rfc2988 section 2
static CGFloat alpha = 0.125f; //from RRC
static CGFloat beta = 0.25f; // from RFC
static CGFloat KVarianceMultiplier = 4.0f; // "K" in rfc2988
static CGFloat Granularity = 0.001f; // Clock granularity (estimated)
//  "G" in rfc2988

//If we've had this many times more successful downloads than 
//  failed downloads, turn off throttling until the next failure 
static NSUInteger SuccessesNeededToEraseAFailure = 10; 

//Number of seconds after which you think a human would be annoyed
// if nothing had happened.  Set this too low at your peril
static CGFloat defaultHTTPTimeout = 10.0f; 
#pragma - End Constants to tweak



@interface ZSBackoffHandler()

@property (nonatomic, assign) NSUInteger recentNetworkFailures;
@property (nonatomic, assign) NSUInteger recentNetworkSamples;
@property (nonatomic, assign) CGFloat smoothedRoundTripTime; //SRTT in RFC
@property (nonatomic, assign) CGFloat roundTripTimeVariance; //RTTVAR in RFC
@property (nonatomic, assign) CGFloat roundTripTimeout; //RTO in RFC
@property (nonatomic, assign) BOOL roundTripInitialized;

@property (nonatomic, assign) CGFloat httpConnectionTimeout; //not in RFC


@end

@implementation ZSBackoffHandler

@synthesize recentNetworkFailures;
@synthesize recentNetworkSamples;
@synthesize smoothedRoundTripTime;
@synthesize roundTripTimeout;
@synthesize roundTripTimeVariance;
@synthesize roundTripInitialized;
@synthesize httpConnectionTimeout;

- (id)init
{
  self = [super init];
  
  if (self) {
    roundTripTimeout = 3.0f; //default as per RFC
    roundTripInitialized = NO; // use defaults the first time
    httpConnectionTimeout = defaultHTTPTimeout;
  }
  
  return self;
}


-(CGFloat) currentTimeout {
  return httpConnectionTimeout;
}

-(CGFloat) currentStartDelay {
  //Don't delay connection starts unless we've had a failure
  if (recentNetworkFailures > 0) {
    DLog(@"Current Start delay is %f",roundTripTimeout);
    return roundTripTimeout;
  }
  return 0.0f;
}

-(void) setCurrentBandwith:(CGFloat) sampleBitsPerSecond {
  recentNetworkSamples++;
  
  if (recentNetworkFailures > 0) {
    if (recentNetworkSamples >= SuccessesNeededToEraseAFailure) {
      //decrement the failure count - we might be able to turn
      //  off throttling now
      recentNetworkFailures--;
      recentNetworkSamples=0;
    }
  }
  
  //As a surrogate for Round Trip time here, we're using 
  //  "amount of time it took to transfer 1 Kilobyte"
  CGFloat sampleKBPerSecond = ((sampleBitsPerSecond / 1024.0f) / 8.0f);
  CGFloat tripTimePerKilobyte = (1.0f / sampleKBPerSecond);
  
  DLog(@"Sample is %f. Time to transfer 1 kilobyte is %f",sampleBitsPerSecond,tripTimePerKilobyte);
  
  if (!roundTripInitialized) {
    //Initial behavior
    /* From RFC:
     * SRTT <- R
     * RTTVAR <- R/2
     * RTO <- SRTT + max (G, K*RTTVAR) 
     */
    
    smoothedRoundTripTime = tripTimePerKilobyte;
    roundTripTimeVariance = tripTimePerKilobyte/2.0f;
    roundTripTimeout = smoothedRoundTripTime + MAX(Granularity, KVarianceMultiplier * roundTripTimeVariance);
    
    roundTripInitialized = YES;
    
  } else {
    //Incremental behavior
    /* 
     * RTTVAR <- (1 - beta) * RTTVAR + beta * |SRTT - R'|
     * SRTT <- (1 - alpha) * SRTT + alpha * R'
     * RTO <- SRTT + max (G, K*RTTVAR)
     */
    
    roundTripTimeVariance = (1 - beta) * roundTripTimeVariance + beta * ABS(smoothedRoundTripTime - tripTimePerKilobyte);
    smoothedRoundTripTime = (1-alpha) * smoothedRoundTripTime + alpha * tripTimePerKilobyte;
    roundTripTimeout = smoothedRoundTripTime + MAX(Granularity, KVarianceMultiplier * roundTripTimeVariance);
    
  }
  DLog(@"Current start delay calculated to be %f",roundTripTimeout);
  
  
}

-(void) incrementFailedCount {
  recentNetworkFailures++;
  recentNetworkSamples=0.0f;
  
  //We had a connection fail.  Exponentially back off our timeout
  roundTripTimeout = roundTripTimeout * 2;
  
  DLog(@"Transfer failed. Current failed out: %d. Current timeout is: %f",recentNetworkFailures,roundTripTimeout);
  
}

//Forget our current backoff state and start over.
// This should be called when the network state improves
// for example, if we've been on EDGE, and switch to WiFi,
// then any backoff data for edge is now irrelevant, 
// and we should start our caclulations over
-(void) resetBackoffState {
  recentNetworkSamples=0;
  recentNetworkFailures=0;
  roundTripTimeout = 3.0f; //default as per RFC
  roundTripInitialized = NO; // use defaults the first time
  httpConnectionTimeout = defaultHTTPTimeout;
}


@end
