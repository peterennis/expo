import { Subscription } from '@unimodules/core';
import { BatteryLevelEvent, BatteryLevelUpdateListener, BatteryState, BatteryStateEvent, BatteryStateUpdateListener, PowerModeEvent, PowerModeUpdateListener, PowerState } from './Battery.types';
/**
 * Deprecated
 */
export declare const isSupported: boolean;
export declare function isAvailableAsync(): Promise<boolean>;
export declare function getBatteryLevelAsync(): Promise<number>;
export declare function getBatteryStateAsync(): Promise<BatteryState>;
export declare function isLowPowerModeEnabledAsync(): Promise<boolean>;
export declare function getPowerStateAsync(): Promise<PowerState>;
export declare function addBatteryLevelListener(listener: BatteryLevelUpdateListener): Subscription;
export declare function addBatteryStateListener(listener: BatteryStateUpdateListener): Subscription;
export declare function addLowPowerModeListener(listener: PowerModeUpdateListener): Subscription;
export { BatteryLevelEvent, BatteryLevelUpdateListener, BatteryState, BatteryStateEvent, BatteryStateUpdateListener, PowerModeEvent, PowerModeUpdateListener, PowerState, Subscription, };
