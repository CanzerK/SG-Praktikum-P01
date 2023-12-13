//
//  Power.swift
//  SpheroBOLT
//
//  Created by Zhivko Bogdanov on 11.11.23.
//

import Foundation
import Combine

public enum BatteryVoltage: UInt8 {
	case ok = 0x01
	case low = 0x02
	case critical = 0x03
}

public enum BatteryLMQ: UInt8 {
	case charged = 0x01
	case charging = 0x02
	case notCharging = 0x03
	case ok = 0x04
	case low = 0x05
	case critical = 0x06
}

public enum ChargeState: UInt8 {
	case notCharging = 0x01
	case charging = 0x02
	case charged = 0x03
}

enum PowerCommandId: UInt8 {
	case enterDeepSleep = 0x00
	case enterSoftSleep = 0x01
	case getUSBState = 0x02
	case getBatteryVoltage = 0x03
	/// Value from Core library Used by LMQ
	case getBatteryStateLMQ = 0x04
	case enableBatteryStateChangeNotification = 0x05
	/// Value from Core library used by LMQ
	case batteryStateChangedLMQ = 0x06
	case wake = 0x0d
	case getBatteryPercentage = 0x10
	case setPowerOptions = 0x12
	case getPowerOptions = 0x13
	case getBatteryState = 0x17
	case willSleepAsync = 0x19
	case sleepAsync = 0x1a
	case batteryStateChanged = 0x1f
}

/// Power extensions to the device object.
extension Device {
	/**
	 * Wakes up the device.
	 */
	public func wake() -> CommandResponseType<Void> {
		return enqueueCommand(deviceId: .power, commandId: PowerCommandId.wake)
	}

	/**
	 * Shuts down the robot.
	 */
	public func enterDeepSleep() -> CommandResponseType<Void> {
		return enqueueCommand(deviceId: .power, commandId: PowerCommandId.enterDeepSleep)
	}

	/**
	 * Sends a soft sleep command to the robot.
	 */
	public func enterSoftSleep() -> CommandResponseType<Void> {
		return enqueueCommand(deviceId: .power, commandId: PowerCommandId.enterSoftSleep)
	}

	/**
	 * Get the current battery voltage. Determines the level of charge.
	 */
	public func getBatteryVoltage() -> CommandResponseType<BatteryLevel> {
		return enqueueCommand(deviceId: .power, commandId: PowerCommandId.getBatteryVoltage)
//		let batteryCharge = Float(100.0) / 100.0
//
//		return batteryCharge
	}

	/**
	 * Get battery state without known voltage constants.
	 */
	public func getBatteryLMQ() -> CommandResponseType<Void> { // -> BatteryLMQ {
		return enqueueCommand(deviceId: .power, commandId: PowerCommandId.getBatteryStateLMQ)

//		let batteryState = BatteryLMQ(rawValue: 0x02)!
//		return batteryState
	}

	/**
	 * Get battery state without known voltage constants.
	 */
	public func getBatteryState() -> CommandResponseType<Void> { // -> BatteryVoltage {
		return enqueueCommand(deviceId: .power, commandId: PowerCommandId.getBatteryState)

//		let batteryVoltage = BatteryVoltage(rawValue: 0x02)!
//		return batteryVoltage
	}

	/**
	 * Charging status information.
	 */
	public func batteryStateChanged() -> CommandResponseType<Void> { // -> ChargeState {
		return enqueueCommand(deviceId: .power, commandId: PowerCommandId.batteryStateChanged)

//		let batteryState = ChargeState(rawValue: 0x02)!
//		return batteryState
	}

	/**
	 * Returns the battery percentage.
	 */
	public func getBatteryPercentage() -> CommandResponseType<Int> {
		return enqueueCommand(deviceId: .power, commandId: PowerCommandId.getBatteryPercentage)

//		let batteryPercentage = 100
//		return batteryPercentage
	}
}
