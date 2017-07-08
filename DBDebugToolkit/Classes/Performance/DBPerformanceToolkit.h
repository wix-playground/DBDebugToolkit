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

@import Foundation;
@import UIKit;
@import Darwin;

#import "DTXPollable.h"
#import "DTXProfiler.h"

@interface DTXThreadMeasurement : NSObject

@property (nonatomic) thread_t machThread;
@property (nonatomic) uint64_t identifier;
@property (nonatomic, strong) NSString* name;
@property (nonatomic) double cpu;

@end

@interface DTXCPUMeasurement : NSObject

@property (nonatomic) double totalCPU;
@property (nonatomic) NSArray<DTXThreadMeasurement*>* threads;
@property (nonatomic) DTXThreadMeasurement* heaviestThread;

@end

/**
 `DBPerformanceToolkit` is a class responsible for the features seen in the `DBPerformanceTableViewController`.
 It calculates the performance stats, handles showing widget and can also simulate memory warning.
 */
@interface DBPerformanceToolkit : NSObject <DTXPollable>

- (instancetype)initWithConfiguration:(DTXProfilingConfiguration*)configuration;

///----------
/// @name CPU
///----------

/**
 Current CPU usage.
 */
@property (nonatomic, strong, readonly) DTXCPUMeasurement* currentCPU;

///-------------
/// @name Memory
///-------------

/**
 Current memory usage.
 */
@property (nonatomic, readonly) CGFloat currentMemory;

///----------
/// @name FPS
///----------

/**
 Current frames per second value.
 */
@property (nonatomic, readonly) CGFloat currentFPS;

///-----------------
/// @name Disk Reads
///-----------------

/**
 Current disk reads
 */
@property (nonatomic, readonly) uint64_t currentDiskReads;
@property (nonatomic, readonly) uint64_t currentDiskReadsDelta;


///------------------
/// @name Disk Writes
///------------------

/**
 Current disk writes
 */
@property (nonatomic, readonly) uint64_t currentDiskWrites;
@property (nonatomic, readonly) uint64_t currentDiskWritesDelta;

///---------------------
/// @name Initialization
///---------------------

/**
 Simulates the memory warning.
 */
- (void)simulateMemoryWarning;

@end
