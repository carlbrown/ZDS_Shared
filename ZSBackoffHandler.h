/*
 *  ZSBackoffHandler.h
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

#import <Foundation/Foundation.h>

@interface ZSBackoffHandler : NSObject

-(CGFloat) currentTimeout;

-(CGFloat) currentStartDelay;

-(void) setCurrentBandwith:(CGFloat) sampleBitsPerSecond;

-(void) incrementFailedCount;

//Forget our current backoff state and start over.
// This should be called when the network state improves
// for example, if we've been on EDGE, and switch to WiFi,
// then any backoff we needed for edge is now irrelevant, 
// and we should start our caclulations over
-(void) resetBackoffState;

@end
