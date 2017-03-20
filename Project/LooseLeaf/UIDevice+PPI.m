//
//  UIDevice+PPI.m
//  LooseLeaf
//
//  Created by Adam Wulf on 7/13/13.
//  Copyright (c) 2013 Milestone Made, LLC. All rights reserved.
//

#import "UIDevice+PPI.h"
#import "EPPZDevice.h"


@implementation UIDevice (PPI)

+ (CGFloat)ppi {
    // source: http://dpi.lv

    NSString* machineId = [[EPPZDevice sharedDevice] machineID];
    if ([machineId isEqualToString:@"iPad1,1"]) {
        return 132; // 1st gen ipad
    } else if ([machineId isEqualToString:@"iPad2,1"]) {
        return 132; // ipad 2
    } else if ([machineId isEqualToString:@"iPad2,2"]) {
        return 132; // ipad 2
    } else if ([machineId isEqualToString:@"iPad2,3"]) {
        return 132; // ipad 2
    } else if ([machineId isEqualToString:@"iPad2,4"]) {
        return 132; // ipad 2
    } else if ([machineId isEqualToString:@"iPad2,5"]) {
        return 163; // ipad mini
    } else if ([machineId isEqualToString:@"iPad2,6"]) {
        return 163; // ipad mini
    } else if ([machineId isEqualToString:@"iPad2,7"]) {
        return 163; // ipad mini
    } else if ([machineId isEqualToString:@"iPad3,1"]) {
        return 264; // iPad 3
    } else if ([machineId isEqualToString:@"iPad3,2"]) {
        return 264; // iPad 3
    } else if ([machineId isEqualToString:@"iPad3,3"]) {
        return 264; // iPad 3
    } else if ([machineId isEqualToString:@"iPad3,4"]) {
        return 264; // iPad 4
    } else if ([machineId isEqualToString:@"iPad3,5"]) {
        return 264; // iPad 4
    } else if ([machineId isEqualToString:@"iPad3,6"]) {
        return 264; // iPad 4
    } else if ([machineId isEqualToString:@"iPad4,1"]) {
        return 264; // iPad Air
    } else if ([machineId isEqualToString:@"iPad4,2"]) {
        return 264; // iPad Air
    } else if ([machineId isEqualToString:@"iPad4,3"]) {
        return 264; // iPad Air (China)
    } else if ([machineId isEqualToString:@"iPad4,4"]) {
        return 326; // ipad mini retina
    } else if ([machineId isEqualToString:@"iPad4,5"]) {
        return 326; // ipad mini retina
    } else if ([machineId isEqualToString:@"iPad4,6"]) {
        return 326; // ipad mini retina
    } else if ([machineId isEqualToString:@"iPad4,6"]) {
        return 326; // ipad mini retina
    } else if ([machineId isEqualToString:@"iPad4,7"]) {
        return 326; // iPad Mini 3
    } else if ([machineId isEqualToString:@"iPad4,8"]) {
        return 326; // iPad Mini 3
    } else if ([machineId isEqualToString:@"iPad4,9"]) {
        return 326; // iPad Mini 3
    } else if ([machineId isEqualToString:@"iPad5,1"]) {
        return 326; // iPad Mini 4 (WiFi)
    } else if ([machineId isEqualToString:@"iPad5,2"]) {
        return 326; // iPad Mini 4 (LTE)
    } else if ([machineId isEqualToString:@"iPad5,3"]) {
        return 264; // iPad Air 2
    } else if ([machineId isEqualToString:@"iPad5,4"]) {
        return 264; // iPad Air 2
    } else if ([machineId isEqualToString:@"iPad6,7"]) {
        return 264; // iPad Pro 12.9in
    } else if ([machineId isEqualToString:@"iPad6,8"]) {
        return 264; // iPad Pro 12.9in
    } else if ([machineId isEqualToString:@"iPad6,3"]) {
        return 264; // iPad Pro 9.7in
    } else if ([machineId isEqualToString:@"iPad6,4"]) {
        return 264; // iPad Pro 9.7in
    }

    // ipad air: 264
    // ipad retina: 264
    // ipad mini retina: 326
    // ipad mini: 163
    // ipad 2: 132
    // ipad 3: 264 // same as ipad retina

    // default, assume retina screen
    return 264;
}


+ (NSString*)modelName {
    // source: http://dpi.lv
    
    NSString* machineId = [[EPPZDevice sharedDevice] machineID];
    if ([machineId isEqualToString:@"iPad1,1"]) {
        return @"iPad 1"; // 1st gen ipad
    } else if ([machineId isEqualToString:@"iPad2,1"]) {
        return @"iPad 2"; // ipad 2
    } else if ([machineId isEqualToString:@"iPad2,2"]) {
        return @"iPad 2"; // ipad 2
    } else if ([machineId isEqualToString:@"iPad2,3"]) {
        return @"iPad 2"; // ipad 2
    } else if ([machineId isEqualToString:@"iPad2,4"]) {
        return @"iPad 2"; // ipad 2
    } else if ([machineId isEqualToString:@"iPad2,5"]) {
        return @"iPad Mini"; // ipad mini
    } else if ([machineId isEqualToString:@"iPad2,6"]) {
        return @"iPad Mini"; // ipad mini
    } else if ([machineId isEqualToString:@"iPad2,7"]) {
        return @"iPad Mini"; // ipad mini
    } else if ([machineId isEqualToString:@"iPad3,1"]) {
        return @"iPad 3"; // iPad 3
    } else if ([machineId isEqualToString:@"iPad3,2"]) {
        return @"iPad 3"; // iPad 3
    } else if ([machineId isEqualToString:@"iPad3,3"]) {
        return @"iPad 3"; // iPad 3
    } else if ([machineId isEqualToString:@"iPad3,4"]) {
        return @"iPad 4"; // iPad 4
    } else if ([machineId isEqualToString:@"iPad3,5"]) {
        return @"iPad 4"; // iPad 4
    } else if ([machineId isEqualToString:@"iPad3,6"]) {
        return @"iPad 4"; // iPad 4
    } else if ([machineId isEqualToString:@"iPad4,1"]) {
        return @"iPad Air"; // iPad Air
    } else if ([machineId isEqualToString:@"iPad4,2"]) {
        return @"iPad Air"; // iPad Air
    } else if ([machineId isEqualToString:@"iPad4,3"]) {
        return @"iPad Air"; // iPad Air (China)
    } else if ([machineId isEqualToString:@"iPad4,4"]) {
        return @"iPad Mini 2"; // ipad mini retina
    } else if ([machineId isEqualToString:@"iPad4,5"]) {
        return @"iPad Mini 2"; // ipad mini retina
    } else if ([machineId isEqualToString:@"iPad4,6"]) {
        return @"iPad Mini 2"; // ipad mini retina
    } else if ([machineId isEqualToString:@"iPad4,6"]) {
        return @"iPad Mini 2"; // ipad mini retina
    } else if ([machineId isEqualToString:@"iPad4,7"]) {
        return @"iPad Mini 3"; // iPad Mini 3
    } else if ([machineId isEqualToString:@"iPad4,8"]) {
        return @"iPad Mini 3"; // iPad Mini 3
    } else if ([machineId isEqualToString:@"iPad4,9"]) {
        return @"iPad Mini 3"; // iPad Mini 3
    } else if ([machineId isEqualToString:@"iPad5,1"]) {
        return @"iPad Mini 4"; // iPad Mini 4 (WiFi)
    } else if ([machineId isEqualToString:@"iPad5,2"]) {
        return @"iPad Mini 4"; // iPad Mini 4 (LTE)
    } else if ([machineId isEqualToString:@"iPad5,3"]) {
        return @"iPad Air 2"; // iPad Air 2
    } else if ([machineId isEqualToString:@"iPad5,4"]) {
        return @"iPad Air 2"; // iPad Air 2
    } else if ([machineId isEqualToString:@"iPad6,7"]) {
        return @"iPad Pro 12.9"; // iPad Pro 12.9in
    } else if ([machineId isEqualToString:@"iPad6,8"]) {
        return @"iPad Pro 12.9"; // iPad Pro 12.9in
    } else if ([machineId isEqualToString:@"iPad6,3"]) {
        return @"iPad Pro 9.7"; // iPad Pro 9.7in
    } else if ([machineId isEqualToString:@"iPad6,4"]) {
        return @"iPad Pro 9.7"; // iPad Pro 9.7in
    }
    
    // ipad air: 264
    // ipad retina: 264
    // ipad mini retina: 326
    // ipad mini: 163
    // ipad 2: 132
    // ipad 3: 264 // same as ipad retina
    
    // default, assume retina screen
    return  @"Unknown iPad";
}

static CGFloat _advisedMaxImportDim = 0;
+ (CGFloat)advisedMaxImportDim {
    if (_advisedMaxImportDim) {
        return _advisedMaxImportDim;
    }

    NSString* machineId = [[EPPZDevice sharedDevice] machineID];
    if ([machineId isEqualToString:@"iPad1,1"]) {
        _advisedMaxImportDim = 400; // 1st gen ipad
    } else if ([machineId isEqualToString:@"iPad2,1"]) {
        _advisedMaxImportDim = 400; // ipad 2
    } else if ([machineId isEqualToString:@"iPad2,2"]) {
        _advisedMaxImportDim = 400; // ipad 2
    } else if ([machineId isEqualToString:@"iPad2,3"]) {
        _advisedMaxImportDim = 400; // ipad 2
    } else if ([machineId isEqualToString:@"iPad2,4"]) {
        _advisedMaxImportDim = 400; // ipad 2
    } else if ([machineId isEqualToString:@"iPad2,5"]) {
        _advisedMaxImportDim = 400; // ipad mini
    } else if ([machineId isEqualToString:@"iPad2,6"]) {
        _advisedMaxImportDim = 400; // ipad mini
    } else if ([machineId isEqualToString:@"iPad2,7"]) {
        _advisedMaxImportDim = 400; // ipad mini
    } else if ([machineId isEqualToString:@"iPad3,1"]) {
        _advisedMaxImportDim = 500; // iPad 3
    } else if ([machineId isEqualToString:@"iPad3,2"]) {
        _advisedMaxImportDim = 500; // iPad 3
    } else if ([machineId isEqualToString:@"iPad3,3"]) {
        _advisedMaxImportDim = 500; // iPad 3
    } else if ([machineId isEqualToString:@"iPad3,4"]) {
        _advisedMaxImportDim = 600; // iPad 4
    } else if ([machineId isEqualToString:@"iPad3,5"]) {
        _advisedMaxImportDim = 600; // iPad 4
    } else if ([machineId isEqualToString:@"iPad3,6"]) {
        _advisedMaxImportDim = 600; // iPad 4
    } else if ([machineId isEqualToString:@"iPad4,1"]) {
        _advisedMaxImportDim = 600; // iPad Air
    } else if ([machineId isEqualToString:@"iPad4,2"]) {
        _advisedMaxImportDim = 600; // iPad Air
    } else if ([machineId isEqualToString:@"iPad4,3"]) {
        _advisedMaxImportDim = 600; // iPad Air (China)
    } else if ([machineId isEqualToString:@"iPad4,4"]) {
        _advisedMaxImportDim = 500; // ipad mini retina
    } else if ([machineId isEqualToString:@"iPad4,5"]) {
        _advisedMaxImportDim = 500; // ipad mini retina
    } else if ([machineId isEqualToString:@"iPad4,6"]) {
        _advisedMaxImportDim = 500; // ipad mini retina
    } else if ([machineId isEqualToString:@"iPad4,6"]) {
        _advisedMaxImportDim = 500; // ipad mini retina
    } else if ([machineId isEqualToString:@"iPad4,7"]) {
        _advisedMaxImportDim = 500; // iPad Mini 3
    } else if ([machineId isEqualToString:@"iPad4,8"]) {
        _advisedMaxImportDim = 500; // iPad Mini 3
    } else if ([machineId isEqualToString:@"iPad4,9"]) {
        _advisedMaxImportDim = 500; // iPad Mini 3
    } else if ([machineId isEqualToString:@"iPad5,1"]) {
        _advisedMaxImportDim = 600; // iPad Mini 4 (WiFi)
    } else if ([machineId isEqualToString:@"iPad5,2"]) {
        _advisedMaxImportDim = 600; // iPad Mini 4 (LTE)
    } else if ([machineId isEqualToString:@"iPad5,3"]) {
        _advisedMaxImportDim = 800; // iPad Air 2
    } else if ([machineId isEqualToString:@"iPad5,4"]) {
        _advisedMaxImportDim = 800; // iPad Air 2
    } else if ([machineId isEqualToString:@"iPad6,7"]) {
        _advisedMaxImportDim = 1366; // iPad Pro 12.9in
    } else if ([machineId isEqualToString:@"iPad6,8"]) {
        _advisedMaxImportDim = 1366; // iPad Pro 12.9in
    } else if ([machineId isEqualToString:@"iPad6,3"]) {
        _advisedMaxImportDim = 1024; // iPad Pro 9.7in
    } else if ([machineId isEqualToString:@"iPad6,4"]) {
        _advisedMaxImportDim = 1024; // iPad Pro 9.7in
    }

    // sane default
    _advisedMaxImportDim = MAX([[[UIScreen mainScreen] fixedCoordinateSpace] bounds].size.width, [[[UIScreen mainScreen] fixedCoordinateSpace] bounds].size.height);

    return _advisedMaxImportDim;
}

// points per cm
+ (CGFloat)ppc {
    return [UIDevice ppi] / 2.54;
}

// will return points per in/cm depending
// on user's locale
+ (CGFloat)idealUnitLength {
    if ([UIDevice isMetric]) {
        return [self ppc];
    } else {
        return [self ppi];
    }
}

static BOOL isMetric;
+ (BOOL)isMetric {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLocale* locale = [NSLocale currentLocale];
        isMetric = [[locale objectForKey:NSLocaleUsesMetricSystem] boolValue];
    });
    return isMetric;
}

+ (NSInteger)majorVersion {
    NSArray* vComp = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    return [[vComp objectAtIndex:0] integerValue];
}

+ (NSString*)buildVersion {
    int mib[2] = {CTL_KERN, KERN_OSVERSION};
    u_int namelen = sizeof(mib) / sizeof(mib[0]);
    size_t bufferSize = 0;

    NSString* osBuildVersion = nil;

    // Get the size for the buffer
    sysctl(mib, namelen, NULL, &bufferSize, NULL, 0);

    u_char buildBuffer[bufferSize];
    int result = sysctl(mib, namelen, buildBuffer, &bufferSize, NULL, 0);

    if (result >= 0) {
        osBuildVersion = [[NSString alloc] initWithBytes:buildBuffer length:bufferSize encoding:NSUTF8StringEncoding];
    }

    return osBuildVersion;
}

@end
