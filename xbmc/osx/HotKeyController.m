//
//  HotKeyController.m
//
//  Modified by Gaurav Khanna on 8/17/10.
//  SOURCE: http://github.com/sweetfm/SweetFM/blob/master/Source/HMediaKeys.m
//  SOURCE: http://stackoverflow.com/questions/2969110/cgeventtapcreate-breaks-down-mysteriously-with-key-down-events
//
//
//  Permission is hereby granted, free of charge, to any person 
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without restriction,
//  including without limitation the rights to use, copy, modify, 
//  merge, publish, distribute, sublicense, and/or sell copies of 
//  the Software, and to permit persons to whom the Software is 
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be 
//  included in all copies or substantial portions of the Software.
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
//  ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "HotKeyController.h"
#import <IOKit/hidsystem/ev_keymap.h>

#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
#if __LP64__ || NS_BUILD_32_LIKE_64
typedef long NSInteger;
typedef unsigned long NSUInteger;
#define NSUIntegerMax   ULONG_MAX
#else
typedef int NSInteger;
typedef unsigned int NSUInteger;
#define NSUIntegerMax   UINT_MAX
#endif
#endif

NSString* const MediaKeyPower                 = @"MediaKeyPower";
NSString* const MediaKeySoundMute             = @"MediaKeySoundMute";
NSString* const MediaKeySoundUp               = @"MediaKeySoundUp";
NSString* const MediaKeySoundDown             = @"MediaKeySoundDown";
NSString* const MediaKeyPlayPauseNotification = @"MediaKeyPlayPauseNotification";
NSString* const MediaKeyNextNotification      = @"MediaKeyNextNotification";
NSString* const MediaKeyPreviousNotification  = @"MediaKeyPreviousNotification";

#ifndef kCGEventTapOptionDefault
#define kCGEventTapOptionDefault 0
#endif

#define NX_KEYSTATE_UP      0x0A
#define NX_KEYSTATE_DOWN    0x0B

@implementation HotKeyController

+ (HotKeyController*)sharedController
{
  static HotKeyController *sharedHotKeyController = nil;
  if (sharedHotKeyController == nil)
    sharedHotKeyController = [[super allocWithZone:NULL] init];

  return sharedHotKeyController;
}

+ (id)allocWithZone:(NSZone *)zone
{
  return [[self sharedController] retain];
}
 
- (id)copyWithZone:(NSZone *)zone
{
  return self;
}
 
- (id)retain
{
  return self;
}
 
- (NSUInteger)retainCount
{
  //denotes an object that cannot be released
  return NSUIntegerMax;
}
 
- (void)release
{
  //do nothing
}
 
- (id)autorelease
{
  return self;
}

- (CFMachPortRef)eventPort
{
  return m_eventPort;
}

- (void)sysPower: (BOOL)enable;
{
  m_controlSysPower = enable;
}
- (BOOL)controlPower;
{
  return m_controlSysPower;
}

- (void)sysVolume: (BOOL)enable;
{
  m_controlSysVolume = enable;
}
- (BOOL)controlVolume;
{
  return m_controlSysVolume;
}

- (void)setActive: (BOOL)active
{
  m_active = active;
}

- (BOOL)getActive
{
  return m_active;
}

// WARNING: do not debugger breakpoint in this routine.
// It's a system level call back that taps ALL Events
// and you WILL lose all key control :)
CGEventRef tapEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
  if (type == kCGEventTapDisabledByTimeout)
    CGEventTapEnable([[HotKeyController sharedController] eventPort], TRUE);
  
  if (![[HotKeyController sharedController] getActive] )
    return event;
    
  if (type != NX_SYSDEFINED) 
    return event;

  // we get a warning on this when compiling under 10.4 SDK, ignore it.
  NSEvent *nsEvent = [NSEvent eventWithCGEvent:event];
  
  if (!nsEvent || [nsEvent subtype] != 8) 
    return event;
    
  int data = [nsEvent data1];
  int keyCode = (data & 0xFFFF0000) >> 16;
  int keyFlags = (data & 0xFFFF);
  int keyState = (keyFlags & 0xFF00) >> 8;
  BOOL keyIsRepeat = (keyFlags & 0x1) > 0;
  
  if (keyIsRepeat) 
    return event;
  
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  switch (keyCode)
  {
    case NX_POWER_KEY:
      if ([[HotKeyController sharedController] controlPower])
      {
        if (keyState == NX_KEYSTATE_DOWN)
          [center postNotificationName:MediaKeyPower object:(HotKeyController *)refcon];
        if (keyState == NX_KEYSTATE_UP || keyState == NX_KEYSTATE_DOWN)
          return NULL;
      }
    break;
    case NX_KEYTYPE_MUTE:
      if ([[HotKeyController sharedController] controlVolume])
      {
        if (keyState == NX_KEYSTATE_DOWN)
          [center postNotificationName:MediaKeySoundMute object:(HotKeyController *)refcon];
        if (keyState == NX_KEYSTATE_UP || keyState == NX_KEYSTATE_DOWN)
          return NULL;
      }
    break;
    case NX_KEYTYPE_SOUND_UP:
      if ([[HotKeyController sharedController] controlVolume])
      {
        if (keyState == NX_KEYSTATE_DOWN)
          [center postNotificationName:MediaKeySoundUp object:(HotKeyController *)refcon];
        if (keyState == NX_KEYSTATE_UP || keyState == NX_KEYSTATE_DOWN)
          return NULL;
      }
    break;
    case NX_KEYTYPE_SOUND_DOWN:
      if ([[HotKeyController sharedController] controlVolume])
      {
        if (keyState == NX_KEYSTATE_DOWN)
          [center postNotificationName:MediaKeySoundDown object:(HotKeyController *)refcon];
        if (keyState == NX_KEYSTATE_UP || keyState == NX_KEYSTATE_DOWN)
          return NULL;
      }
    break;
    case NX_KEYTYPE_PLAY:
      if (keyState == NX_KEYSTATE_DOWN)
        [center postNotificationName:MediaKeyPlayPauseNotification object:(HotKeyController *)refcon];
      if (keyState == NX_KEYSTATE_UP || keyState == NX_KEYSTATE_DOWN)
        return NULL;
    break;
    case NX_KEYTYPE_FAST:
      if (keyState == NX_KEYSTATE_DOWN)
        [center postNotificationName:MediaKeyNextNotification object:(HotKeyController *)refcon];
      if (keyState == NX_KEYSTATE_UP || keyState == NX_KEYSTATE_DOWN)
        return NULL;
    break;
    case NX_KEYTYPE_REWIND:
      if (keyState == NX_KEYSTATE_DOWN)
        [center postNotificationName:MediaKeyPreviousNotification object:(HotKeyController *)refcon];
      if (keyState == NX_KEYSTATE_UP || keyState == NX_KEYSTATE_DOWN)
        return NULL;
    break;
  }
  return event;
}

- (id)init
{
  if (self = [super init])
  {
    CFRunLoopRef runLoop;
    CFRunLoopSourceRef runLoopSource;

    m_active = NO;
    m_controlSysPower = NO;
    m_controlSysVolume = NO;
    m_eventPort = CGEventTapCreate(kCGSessionEventTap,
     kCGHeadInsertEventTap, kCGEventTapOptionDefault,
     CGEventMaskBit(NX_SYSDEFINED), tapEventCallback, self);
    if (m_eventPort == NULL)
    {
      NSLog(@"Fatal Error: Event Tap could not be created");
      return self;
    }

    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorSystemDefault, m_eventPort, 0);
    if (runLoopSource == NULL)
    {
      NSLog(@"Fatal Error: Run Loop Source could not be created");
      return self;
    }

    runLoop = CFRunLoopGetCurrent();
    if (runLoop == NULL)
    {
      NSLog(@"Fatal Error: Couldn't get current threads Run Loop");
      return self;
    }
    CFRunLoopAddSource(runLoop, runLoopSource, kCFRunLoopCommonModes);
    CFRelease(runLoopSource);
  }
  return self;
}

- (void)dealloc
{
  CFRelease(m_eventPort);
  [super dealloc];
}

@end
