


//Constants needed for ZDS_Shared code to work, taken from README

#ifdef DEBUG
  #define MCRelease(x) [x release]
#ifndef DLog
  #define DLog(...) NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat:__VA_ARGS__])
#endif
#ifndef DCLog
  #define DCLog(...) NSLog(@"%@", [NSString stringWithFormat:__VA_ARGS__])
#endif
#ifndef ALog
  #define ALog(...) {NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat:__VA_ARGS__]);[[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSUTF8StringEncoding] file:[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lineNumber:__LINE__ description:__VA_ARGS__];}
#endif
#else
  #define MCRelease(x) [x release], x = nil
  #define DLog(...) do { } while (0)
  #define DCLog(...) do { } while (0)
  #ifndef NS_BLOCK_ASSERTIONS
    #define NS_BLOCK_ASSERTIONS
  #endif
  #define ALog(...) NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat:__VA_ARGS__])
#endif

#define ZAssert(condition, ...) do { if (!(condition)) { ALog(__VA_ARGS__); }} while(0)

#define ISRETINADISPLAY (([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) ? [[UIScreen mainScreen] scale] > 1.0 : NO)

#define degreesToRadians(x) (M_PI * x / 180.0)
