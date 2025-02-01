#define UNRESTRICTED_AVAILABILITY
#import <CoreFoundation/CoreFoundation.h>
#import <PSHeader/CameraApp/CAMCaptureCapabilities.h>
#import <PSHeader/CameraApp/CAMUserPreferences.h>
#import <PSHeader/CameraApp/CAMViewfinderViewController.h>
#import <version.h>
#import <UIKit/UIApplication+Private.h>

@interface CAMViewfinderViewController (TapVideoConfig)
- (void)changeVideoConfigurationMode:(UITapGestureRecognizer *)gesture;
@end

typedef NS_ENUM(NSInteger, VideoConfigurationMode) {
    VideoConfigurationModeDefault = 0,
    VideoConfigurationMode1080p60 = 1,
    VideoConfigurationMode720p120 = 2,
    VideoConfigurationMode720p240 = 3,
    VideoConfigurationMode1080p120 = 4,
    VideoConfigurationMode4k30 = 5,
    VideoConfigurationMode720p30 = 6,
    VideoConfigurationMode1080p30 = 7,
    VideoConfigurationMode1080p240 = 8,
    VideoConfigurationMode4k60 = 9,
    VideoConfigurationMode4k24 = 10,
    VideoConfigurationMode1080p25 = 11,
    VideoConfigurationMode4k25 = 12,
    VideoConfigurationMode4k120 = 13,
    VideoConfigurationMode4k100 = 14,
    VideoConfigurationModeCount
};

NSInteger devices[] = { 1, 0, 0, 0, 1, 1 };

NSString *title(VideoConfigurationMode mode) {
    switch (mode) {
        case VideoConfigurationModeDefault:
            return @"Default";
        case VideoConfigurationMode1080p60:
            return @"1080p60";
        case VideoConfigurationMode720p120:
            return @"720p120";
        case VideoConfigurationMode720p240:
            return @"720p240";
        case VideoConfigurationMode1080p120:
            return @"1080p120";
        case VideoConfigurationMode4k30:
            return @"4k30";
        case VideoConfigurationMode720p30:
            return @"720p30";
        case VideoConfigurationMode1080p30:
            return @"1080p30";
        case VideoConfigurationMode1080p240:
            return @"1080p240";
        case VideoConfigurationMode4k60:
            return @"4k60";
        case VideoConfigurationMode4k24:
            return @"4k24";
        case VideoConfigurationMode1080p25:
            return @"1080p25";
        case VideoConfigurationMode4k25:
            return @"4k25";
        case VideoConfigurationMode4k120:
            return @"4k120";
        case VideoConfigurationMode4k100:
            return @"4k100";
        case VideoConfigurationModeCount:
            break;
    }
    return @"Unknown";
}

NSInteger fps = 0;

%hook CAMFramerateIndicatorView

- (NSInteger)_framesPerSecond {
    return fps ?: %orig;
}

- (void)setStyle:(NSInteger)style {
    if (style == 0) {
        fps = 30;
        %orig(1);
        [self setValue:@(style) forKey:@"_style"];
        fps = 0;
    } else
        %orig(style);
}

%end

%hook CAMCaptureCapabilities

- (bool)interactiveVideoFormatControlAlwaysEnabled {
    return true;
}

%end

%hook CAMViewfinderViewController

- (BOOL)_shouldHideFramerateIndicatorForGraphConfiguration:(CAMCaptureGraphConfiguration *)configuration {
    return [self._captureController isCapturingVideo] || [self._topBar shouldHideFramerateIndicatorForGraphConfiguration:configuration] ? %orig : (configuration.mode == 1 || configuration.mode == 2 ? NO : %orig);
}

- (BOOL)_shouldHideFramerateIndicatorForMode:(NSInteger)mode device:(NSInteger)device {
    return [UIApplication shouldMakeUIForDefaultPNG];
}

- (void)_createFramerateIndicatorViewIfNecessary {
    %orig;
    CAMFramerateIndicatorView *view = [self valueForKey:@"_framerateIndicatorView"];
    if (!view) return;
    view.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeVideoConfigurationMode:)];
    tap.numberOfTouchesRequired = 1;
    [view addGestureRecognizer:tap];
}

- (void)_createVideoConfigurationStatusIndicatorIfNecessary {
    %orig;
    UIControl *view = [self valueForKey:@"__videoConfigurationStatusIndicator"];
    if (!view) return;
    view.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeVideoConfigurationMode:)];
    tap.numberOfTouchesRequired = 1;
    [view addGestureRecognizer:tap];
}

- (void)videoConfigurationStatusIndicatorDidTapFramerate:(id)arg1 {
    [self changeVideoConfigurationMode:nil];
}

- (void)videoConfigurationStatusIndicatorDidTapResolution:(id)arg1 {
    [self changeVideoConfigurationMode:nil];
}

%new(v@:@)
- (void)changeVideoConfigurationMode:(UITapGestureRecognizer *)gesture {
    NSInteger cameraMode = self._currentGraphConfiguration.mode;
    NSInteger cameraDevice = self._currentGraphConfiguration.device == 0 ? 0 : devices[self._currentGraphConfiguration.device - 1];
    NSString *message = @"Select video configuration:";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"TapVideoConfig" message:message preferredStyle:UIAlertControllerStyleAlert];
    NSMutableDictionary <NSString *, NSNumber *> *modes = [NSMutableDictionary dictionary];
    VideoConfigurationMode currentVideoConfigurationMode = [[NSClassFromString(@"CAMUserPreferences") preferences] videoConfiguration];
    CAMCaptureCapabilities *capabilities = [NSClassFromString(@"CAMCaptureCapabilities") capabilities];
    for (VideoConfigurationMode mode = 0; mode < VideoConfigurationModeCount; ++mode) {
        if (mode != currentVideoConfigurationMode) {
            if ([capabilities isSupportedVideoConfiguration:mode forMode:cameraMode device:cameraDevice])
                modes[title(mode)] = @(mode);
        }
    }
    NSArray <NSString *> *sortedArray = [[modes allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    for (NSString *mode in sortedArray) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:mode style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self _writeUserPreferences];
            CFPreferencesSetAppValue(cameraMode == 2 ? CFSTR("CAMUserPreferenceSlomoConfiguration") : CFSTR("CAMUserPreferenceVideoConfiguration"), (CFNumberRef)modes[mode], CFSTR("com.apple.camera"));
            CFPreferencesAppSynchronize(CFSTR("com.apple.camera"));
            [self readUserPreferencesAndHandleChangesWithOverrides:0];
        }];
        [alert addAction:action];
    }
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

%end
