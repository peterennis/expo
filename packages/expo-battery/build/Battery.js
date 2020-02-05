import { EventEmitter, deprecate } from '@unimodules/core';
import { BatteryState, } from './Battery.types';
import ExpoBattery from './ExpoBattery';
const BatteryEventEmitter = new EventEmitter(ExpoBattery);
if (typeof module !== 'undefined' && module.exports) {
    Object.defineProperties(module.exports, {
        isSupported: {
            enumerable: true,
            get() {
                deprecate('expo-battery', 'Battery.isSupported', {
                    replacement: 'Battery.isAvailableAsync',
                    currentVersion: require('../package.json').version,
                    versionToRemove: '3.0.0',
                });
                return (ExpoBattery && ExpoBattery.isSupported) || false;
            },
        },
    });
}
export async function isAvailableAsync() {
    return Promise.resolve((ExpoBattery && ExpoBattery.isSupported) || false);
}
export async function getBatteryLevelAsync() {
    if (!ExpoBattery.getBatteryLevelAsync) {
        return -1;
    }
    return await ExpoBattery.getBatteryLevelAsync();
}
export async function getBatteryStateAsync() {
    if (!ExpoBattery.getBatteryStateAsync) {
        return BatteryState.UNKNOWN;
    }
    return await ExpoBattery.getBatteryStateAsync();
}
export async function isLowPowerModeEnabledAsync() {
    if (!ExpoBattery.isLowPowerModeEnabledAsync) {
        return false;
    }
    return await ExpoBattery.isLowPowerModeEnabledAsync();
}
export async function getPowerStateAsync() {
    const [batteryLevel, batteryState, lowPowerMode] = await Promise.all([
        getBatteryLevelAsync(),
        getBatteryStateAsync(),
        isLowPowerModeEnabledAsync(),
    ]);
    return {
        batteryLevel,
        batteryState,
        lowPowerMode,
    };
}
export function addBatteryLevelListener(listener) {
    return BatteryEventEmitter.addListener('Expo.batteryLevelDidChange', listener);
}
export function addBatteryStateListener(listener) {
    return BatteryEventEmitter.addListener('Expo.batteryStateDidChange', listener);
}
export function addLowPowerModeListener(listener) {
    return BatteryEventEmitter.addListener('Expo.powerModeDidChange', listener);
}
export { BatteryState, };
//# sourceMappingURL=Battery.js.map