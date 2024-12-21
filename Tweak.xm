#import <UIKit/UIKit.h>
#import <SpringBoard/SpringBoard.h>
#import <Foundation/Foundation.h>
#import <spawn.h>

@interface _UIBatteryView : UIView
@end

bool isCharging = NO;
NSString *chargingstate = @"";

void executeCommand() {
  pid_t pid;
  const char* args[] = {"batt", NULL};
  posix_spawn(&pid, "/usr/bin/batt", NULL, NULL, (char* const*)args, NULL);
}


NSString* readFileData(NSString *filePath) {
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    return content ?: @"";
}

NSString* parseChargingTime(NSString *fileContent) {
    NSArray *lines = [fileContent componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        if ([line hasPrefix:@"Charging Time:"]) {
            return [line stringByReplacingOccurrencesOfString:@"Charging Time: " withString:@""];
        }
    }
    return nil;
}

void loadPrefs() {
    if(isCharging) {
        executeCommand();
        NSString *fileContent = readFileData(@"/tmp/data.txt");
        NSString *chargingTime = parseChargingTime(fileContent);
        chargingstate = chargingTime ? [NSString stringWithFormat:@"%@", chargingTime] : @"Failed to retrieve charging time.";
    } else {
        chargingstate = @"Not Charging\nSwipe to Unlock";
    }
}

// void updateChargingTime() {
//     executeCommand("/var/jb/usr/bin/batt");
//     NSString *fileContent = readFileData(@"/tmp/data.txt");
//     NSString *chargingTime = parseChargingTime(fileContent);
//     NSString *displayText = chargingTime ? [NSString stringWithFormat:@"Charging time left: %@", chargingTime] : @"Failed to retrieve charging time.";
// }

%hook _UIBatteryView
- (void)setChargingState:(NSInteger)arg1 {
    if (arg1 == 1) {
        isCharging = YES;
        loadPrefs();
    } else {
        isCharging = NO;
        loadPrefs();
    }
    return %orig;
}
%end

%hook CSTeachableMomentsContainerViewController
- (void)_updateText:(id)arg1 {
    if (isCharging) {
        arg1 = [NSString stringWithFormat:@"Est. Time Fully Charge: %@", chargingstate];
    } else {
        arg1 = @"Not Charging\nSwipe to Unlock";
    }
    //arg1 = [NSString stringWithFormat:@"Time Left: %@", chargingstate];
    %orig;
}
%end

%ctor {
    if (isCharging) {
        loadPrefs();
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            while (isCharging) {
                loadPrefs();
                [NSThread sleepForTimeInterval:30];
            }
        });
    }
}