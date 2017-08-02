// The MIT License
//
// Copyright (c) 2016 Dariusz Bukowski
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DBFPSCalculator.h"

@import Darwin;

static const CGFloat DBFPSCalculatorTargetFramerate = 60.0;

@interface DBFPSCalculator ()
{
	_Atomic uint64_t _frameCount;
	_Atomic BOOL _enabled;
}

@property (nonatomic, strong) CADisplayLink *displayLink;

//Handle last known fps - must use synchronized access for thread safety
@property (nonatomic, strong) dispatch_queue_t lastKnownFPSQueue;
@property (nonatomic, assign) CGFloat lastKnownFPS;

@end

@implementation DBFPSCalculator

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupFPSMonitoring];
        [self setupNotifications];
    }
    
    return self;
}

- (void)dealloc {
    [self.displayLink setPaused:YES];
    [self.displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - FPS Monitoring

- (void)setupFPSMonitoring
{
	self.lastKnownFPSQueue = dispatch_queue_create("com.wix.DTXProfilerLastKnownFPSQueue", DISPATCH_QUEUE_SERIAL);
	
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTick)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	
	__block BOOL enabled = NO;
	
	void (^block)(void) = ^{
		if([UIApplication sharedApplication] && [UIApplication sharedApplication].applicationState == UIApplicationStateActive)
		{
			enabled = YES;
		}
	};
	
	if(NSThread.isMainThread == YES)
	{
		block();
	}
	else
	{
		dispatch_sync(dispatch_get_main_queue(), block);
	}
	
	if(enabled)
	{
		atomic_store(&_enabled, YES);
	}
	else
	{
		[self.displayLink setPaused:YES];
	}
}

- (void)pollWithTimePassed:(NSTimeInterval)interval
{
	if(atomic_load(&_enabled) == NO)
	{
		dispatch_sync(_lastKnownFPSQueue, ^{
			self.lastKnownFPS = 0;
		});
		
		return;
	}
		
	uint64_t frameCount = atomic_exchange(&_frameCount, 0);
	CGFloat fps = MIN(frameCount / interval, DBFPSCalculatorTargetFramerate);
	
	dispatch_sync(_lastKnownFPSQueue, ^{
		self.lastKnownFPS = fps;
	});
}

- (void)displayLinkTick {
#if FPS_CALCULATOR_ENFORCE_THREAD_SAFETY
	atomic_fetch_add(&_frameCount, 1);
#else
	_frameCount++;
#endif
}

#pragma mark - Notifications

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(applicationDidBecomeActiveNotification:)
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(applicationWillResignActiveNotification:)
                                                 name: UIApplicationWillResignActiveNotification
                                               object: nil];
}

- (void)applicationDidBecomeActiveNotification:(NSNotification *)notification {
	atomic_exchange(&_frameCount, 0);
    [self.displayLink setPaused:NO];
	atomic_store(&_enabled, YES);
}


- (void)applicationWillResignActiveNotification:(NSNotification *)notification {
    [self.displayLink setPaused:YES];
	atomic_store(&_enabled, NO);
}

#pragma mark - FPS 

- (CGFloat)fps {
	__block CGFloat fps;
	
#if FPS_CALCULATOR_ENFORCE_THREAD_SAFETY
	dispatch_sync(_lastKnownFPSQueue, ^{
#endif
		fps = self.lastKnownFPS;
#if FPS_CALCULATOR_ENFORCE_THREAD_SAFETY
	});
#endif
	
	return fps;
}

@end
