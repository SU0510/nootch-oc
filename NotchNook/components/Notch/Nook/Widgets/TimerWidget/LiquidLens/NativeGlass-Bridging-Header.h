//
//  NativeGlass-Bridging-Header.h
//  NotchNook
//
//  Private CoreAnimation interfaces used by the macOS 26+ native Liquid Glass
//  pill (see NativeGlassPill.swift). These are the same private layers SwiftUI's
//  own `.glassEffect()` is built on; declarations adapted verbatim from the
//  AlexStrNik/ShatteredGlass deconstruction. macOS is NOT shipped on the Mac App
//  Store, so private-API use is acceptable. Everything that consumes these is
//  runtime-gated (`#available(macOS 26)` + `NSClassFromString` availability
//  checks) with a Metal-lens fallback, so a future OS rename degrades, not crashes.
//

#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>

typedef struct CAColorMatrix {
    float m11, m12, m13, m14, m15;
    float m21, m22, m23, m24, m25;
    float m31, m32, m33, m34, m35;
    float m41, m42, m43, m44, m45;
} CAColorMatrix;

@interface CABackdropLayer : CALayer
- (void)setAllowsFilteredLuma:(BOOL)arg1;
- (void)setScale:(double)arg1;
- (void)setTracksLuma:(BOOL)arg1;
- (void)setWindowServerAware:(BOOL)arg1;
@end

@interface CASDFElementLayer : CALayer
- (void)setGradientOvalization:(double)arg1;
- (void)setMode:(NSString*)arg1;
- (void)setOperation:(NSString*)arg1;
@end

@interface CASDFEffect : NSObject
- (nonnull instancetype)init;
@end

@interface CASDFLayer : CALayer
- (void)setEffect:(CASDFEffect*)arg1;
- (void)setSmoothness:(double)arg1;
@end


@interface CASDFOutputEffect : CASDFEffect
- (void)setMaximum:(double)arg1;
- (void)setMinimum:(double)arg1;
@end

@interface CASDFGlassHighlightEffect : CASDFEffect
- (void)setAmount:(double)arg1;
- (void)setAngle:(double)arg1;
- (void)setColor:(id)arg1;
- (void)setCurvature:(double)arg1;
- (void)setGlobal:(bool)arg1;
- (void)setHeight:(double)arg1;
- (void)setSpread:(double)arg1;
@end

@interface CAFilter : NSObject
+ (nonnull instancetype)filterWithType:(NSString*)arg1;

- (void)setValue:(id)arg1 forKey:(NSString*)arg2;
- (id)valueForKey:(NSString*)arg1;
@end

@interface CAPortalLayer : CALayer
- (void)setSourceContextId:(unsigned int)arg1;
- (void)setSourceLayer:(id)arg1;
- (void)setSourceLayerRenderId:(unsigned long long)arg1;
@end

@interface NSValue (Details)
+ (NSValue *)valueWithCAColorMatrix:(CAColorMatrix)t;
@end
