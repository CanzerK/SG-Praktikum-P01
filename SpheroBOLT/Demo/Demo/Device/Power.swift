//
//  Power.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 11.11.23.
//

import Foundation

enum BatteryVoltage: UInt8 {
	case ok = 0x01
	case low = 0x02
	case critical = 0x03
}

enum ChargingState: UInt8 {
	case notCharging = 0x01
	case charging = 0x02
	case charged = 0x03
}

enum PowerCommand: UInt8 {
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
