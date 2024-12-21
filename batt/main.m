#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>

NSDictionary* getBatteryInfo() {
    CFDictionaryRef matching = IOServiceMatching("IOPMPowerSource");
    io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, matching);
    CFMutableDictionaryRef prop = NULL;
    IORegistryEntryCreateCFProperties(service, &prop, NULL, 0);
    NSDictionary* dict = (__bridge_transfer NSDictionary*) prop;
    IOObjectRelease(service);
    return dict;
}

void calculateChargingTime(double rawMaxCapacity, double currentCapacity, double watts, double current, double voltage, double temperature, int *hours, int *minutes) {
    double efficiencyFactor;

    if (temperature < 10.0 || temperature > 40.0) {
        efficiencyFactor = 0.7;
    } else if (temperature < 20.0 || temperature > 35.0) {
        efficiencyFactor = 0.8;
    } else if ((temperature < 25.0 && temperature >= 20 ) || (temperature > 30.0 && temperature <= 35.0)) {
        efficiencyFactor = 0.85;
    } else {
        efficiencyFactor = 0.9;
    }

    //double current = watts / voltage;
    if (current == 0) {
        *hours = 0;
        *minutes = 0;
        return;
    }
    double totalTimeInHours = ((rawMaxCapacity - currentCapacity) / (current * 1000)) / efficiencyFactor;

    *hours = (int)totalTimeInHours;
    *minutes = (int)((totalTimeInHours - *hours) * 60);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {

        NSDictionary *batteryInfo = getBatteryInfo();

        double rawMaxCapacity = [batteryInfo[@"AppleRawMaxCapacity"] doubleValue];
        double currentCapacity = [batteryInfo[@"AppleRawCurrentCapacity"] doubleValue];
        double temperature = [batteryInfo[@"Temperature"] doubleValue] / 100.0;
        int isCharging = [batteryInfo[@"IsCharging"] intValue];

        NSArray *adapterDetails = batteryInfo[@"AppleRawAdapterDetails"];
        NSDictionary *primaryAdapter = nil;
        for (NSDictionary *adapter in adapterDetails) {
            if (adapter[@"AdapterID"] != 0) {
                primaryAdapter = adapter;
                break;
            }
        }

        double adapterVoltage = [primaryAdapter[@"AdapterVoltage"] doubleValue] / 1000.0;
        double watts = [primaryAdapter[@"Watts"] doubleValue];
        double current = [primaryAdapter[@"Current"] doubleValue] / 1000.0;

        int hours, minutes;
        calculateChargingTime(rawMaxCapacity, currentCapacity, watts, current, adapterVoltage, temperature, &hours, &minutes);

        NSString *chargingTimeString;
        if (hours == 0) {
            chargingTimeString = [NSString stringWithFormat:@"Charging Time: %d minutes\n", minutes];
        } else {
            chargingTimeString = [NSString stringWithFormat:@"Charging Time: %d hours and %d minutes\n", hours, minutes];
        }

        NSString *outputString = [NSString stringWithFormat:
                                  @"Raw Max Capacity: %.2f\n"
                                  "Current Capacity: %.2f\n"
                                  "Temperature: %.2f°C\n"
                                  "Adapter Voltage: %.2fV\n"
                                  "Watts: %.2fW\n"
                                  "Current: %.2fA\n"
                                  "Is Charging: %d\n"
                                  "%@",
                                  rawMaxCapacity,
                                  currentCapacity,
                                  temperature,
                                  adapterVoltage,
                                  watts,
                                  current,
                                  isCharging,
                                  chargingTimeString];

        NSString *filePath = @"/tmp/data.txt";
        NSError *error = nil;
        BOOL success = [outputString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];

        if (success) {
            NSLog(@"Data successfully written to %@", filePath);
        } else {
            NSLog(@"Failed to write data: %@", error.localizedDescription);
        }
    }
    return 0;
}
