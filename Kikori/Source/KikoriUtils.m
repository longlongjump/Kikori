//
//  Kikori.m
//  Kikori
//
//  Created by eugene on 11/4/16.
//  Copyright © 2016 Eugene Ovchynnykov. All rights reserved.
//

#import "KikoriUtils.h"
#import <Kikori/Kikori-Swift.h>
@import ObjectiveC;

typedef NSURLSessionConfiguration*(*SessionConfigConstructor)(id,SEL);
static SessionConfigConstructor orig_defaultSessionConfiguration;

static NSURLSessionConfiguration* Kikori_defaultSessionConfiguration(id self, SEL _cmd)
{
    NSURLSessionConfiguration *conf = orig_defaultSessionConfiguration(self, _cmd);
    conf.protocolClasses = [@[Kikori.self] arrayByAddingObjectsFromArray:conf.protocolClasses];
    return conf;
}

@implementation NSURLSessionConfiguration(Kikori)

+ (void) enableKikoriForDefaultSession:(BOOL)enable {
    static BOOL enabled = NO;
    
    if (enabled == enable) { return; }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method m = class_getClassMethod([self class], @selector(defaultSessionConfiguration));
        orig_defaultSessionConfiguration = (SessionConfigConstructor)method_getImplementation(m);
    });
    
    Method m = class_getClassMethod([self class], @selector(defaultSessionConfiguration));
    if (enable) {
        method_setImplementation(m, (IMP)Kikori_defaultSessionConfiguration);
    } else {
        method_setImplementation(m, (IMP)orig_defaultSessionConfiguration);
    }
    
    enabled = enable;
}

@end

typedef void(*MutableRequestSetter)(id,SEL,NSData*);
static MutableRequestSetter orig_mutableRequestSetter;

static void Kikori_mutableRequestSetter(id self, SEL _cmd, NSData *data)
{
    orig_mutableRequestSetter(self, _cmd, data);
    if (data) {
        [NSURLProtocol setProperty:data forKey:Kikori.RequestBodyKey inRequest:self];
    } else {
        [NSURLProtocol removePropertyForKey:Kikori.RequestBodyKey inRequest:self];
    }
}


@implementation NSMutableURLRequest(Kikori)

+ (void) enableSavingHTTPBody:(BOOL)enable
{
    static BOOL enabled = NO;
    
    if (enabled == enable) { return; }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method m = class_getInstanceMethod([self class], @selector(setHTTPBody:));
        orig_mutableRequestSetter = (MutableRequestSetter)method_getImplementation(m);
    });
    
    Method m = class_getInstanceMethod([self class], @selector(setHTTPBody:));
    if (enable) {
        method_setImplementation(m, (IMP)Kikori_mutableRequestSetter);
    } else {
        method_setImplementation(m, (IMP)orig_mutableRequestSetter);
    }
    
    enabled = enable;
}

@end
