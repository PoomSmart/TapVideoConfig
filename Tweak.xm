#import "../PS.h"

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
	VideoConfigurationMode4k24 = 10
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
	}
	return @"Unknown";
}

BOOL is30 = NO;

%hook CAMFramerateIndicatorView

- (void)setStyle:(NSInteger)style {
	MSHookIvar<NSInteger>(self, "_style") = style;
	[self _updateForAppearanceChange];
}

- (NSInteger)_framesPerSecond {
	return is30 ? 30 : %orig;
}

- (void)_updateAppearance {
	NSInteger style = MSHookIvar<NSInteger>(self, "_style");
	if (style == 0) {
		is30 = YES;
		MSHookIvar<NSInteger>(self, "_style") = 1;
		%orig;
		MSHookIvar<NSInteger>(self, "_style") = style;
		is30 = NO;
	} else
		%orig;
}

%end

%hook CAMViewfinderViewController

- (BOOL)_shouldHideFramerateIndicatorForGraphConfiguration:(CAMCaptureGraphConfiguration *)configuration {
	return [self._captureController isCapturingVideo] || [self._topBar shouldHideFramerateIndicatorForGraphConfiguration:configuration] ? %orig : (configuration.mode == 1 || configuration.mode == 2 ? NO : %orig);
}

- (void)_createFramerateIndicatorViewIfNecessary {
	%orig;
	CAMFramerateIndicatorView *view = [self valueForKey:@"_framerateIndicatorView"];
	view.userInteractionEnabled = YES;
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeVideoConfigurationMode:)];
	tap.numberOfTouchesRequired = 1;
	[view addGestureRecognizer:tap];
}

%new
- (void)changeVideoConfigurationMode:(UITapGestureRecognizer *)gesture {
	NSInteger cameraMode = self._currentGraphConfiguration.mode;
	NSInteger cameraDevice = devices[self._currentGraphConfiguration.device - 1];
	NSString *message = @"Select video configuration:";
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"TapVideoConfig" message:message preferredStyle:UIAlertControllerStyleAlert];
	NSMutableDictionary <NSString *, NSNumber *> *modes = [NSMutableDictionary dictionary];
	for (VideoConfigurationMode mode = 1; mode < 11; mode++) {
		if ([[NSClassFromString(@"CAMCaptureCapabilities") capabilities] isSupportedVideoConfiguration:mode forMode:cameraMode device:cameraDevice])
			modes[title(mode)] = @(mode);
	}
	NSArray <NSString *> *sortedArray = [[modes allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	for (NSString *mode in sortedArray) {
		UIAlertAction *action = [UIAlertAction actionWithTitle:mode style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			[self _writeUserPreferences];
			CFPreferencesSetAppValue(cameraMode == 2 ? CFSTR("CAMUserPreferenceSlomoConfiguration") : CFSTR("CAMUserPreferenceVideoConfiguration"), modes[mode], CFSTR("com.apple.camera"));
			CFPreferencesAppSynchronize(CFSTR("com.apple.camera"));
			[self _readUserPreferencesAndHandleChanges];
		}];
		[alert addAction:action];
	}
	UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	[alert addAction:defaultAction];
	[self presentViewController:alert animated:YES completion:nil];
}

%end