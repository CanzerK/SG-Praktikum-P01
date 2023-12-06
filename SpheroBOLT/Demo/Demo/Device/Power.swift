//
//  Power.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 11.11.23.
//

import Foundation
import Combine

enum BatteryVoltage: UInt8 {
	case ok = 0x01
	case low = 0x02
	case critical = 0x03
}

enum BatteryLMQ: UInt8 {
	case charged = 0x01
	case charging = 0x02
	case notCharging = 0x03
	case ok = 0x04
	case low = 0x05
	case critical = 0x06
}

enum ChargeState: UInt8 {
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

extension Device {
	internal func enqueueCommand<T: CommandRepresentable>(deviceId: DeviceId, commandId: T) -> Future<Void, DeviceError> {
		return Future<Void, DeviceError> { [weak self] promise in
			guard let self = self else {
				promise(.failure(.unableToWrite))

				return
			}

			return self.enqueueCommand(deviceId: deviceId, commandId: commandId) {
				switch $0 {
				case .success:
					promise(.success(()))
				case .failure(let error):
					promise(.failure(error))
				}
			}
		}
	}

	internal func enqueueCommand<T: CommandRepresentable, R: DataInitializable>(deviceId: DeviceId, commandId: T) -> Future<R, DeviceError> {
		return Future<R, DeviceError> { [weak self] promise in
			guard let self = self else {
				promise(.failure(.unableToWrite))

				return
			}

			return self.enqueueCommand<R>(deviceId: deviceId, commandId: commandId) {
				switch $0 {
				case .success(let value):
					promise(.success(value))
				case .failure(let error):
					promise(.failure(error))
				}
			}
		}
	}
}

struct BatteryLevel: DataInitializable {
	init(fromData data: Data) throws {

	}
}

/// Power extensions to the device object.
extension Device {
	/**
	 * Wakes up the device.
	 */
	func wake() -> Future<Void, DeviceError> {
		return enqueueCommand(deviceId: .power, commandId: PowerCommandId.wake)
	}

	/**
	 * Shuts down the robot.
	 */
	func enterDeepSleep() -> Future<Void, DeviceError> {
		return enqueueCommand(deviceId: .power, commandId: PowerCommandId.enterDeepSleep)
	}

	/**
	 * Sends a soft sleep command to the robot.
	 */
	func enterSoftSleep() -> Future<Void, DeviceError> {
		return enqueueCommand(deviceId: .power, commandId: PowerCommandId.enterSoftSleep)
	}

	/**
	 * Get the current battery voltage. Determines the level of charge.
	 */
	func getBatteryVoltage() -> Future<BatteryLevel, DeviceError> {
		return enqueueCommand(deviceId: .power, commandId: PowerCommandId.getBatteryVoltage)
//		let batteryCharge = Float(100.0) / 100.0
//
//		return batteryCharge
	}

	/**
	 * Get battery state without known voltage constants.
	 */
	func getBatteryLMQ() -> Future<Void, DeviceError> { // -> BatteryLMQ {
		return enqueueCommand(deviceId: .power, commandId: PowerCommandId.getBatteryStateLMQ)

//		let batteryState = BatteryLMQ(rawValue: 0x02)!
//		return batteryState
	}

	/**
	 * Get battery state without known voltage constants.
	 */
	func getBatteryState() -> Future<Void, DeviceError> { // -> BatteryVoltage {
		return enqueueCommand(deviceId: .power, commandId: PowerCommandId.getBatteryState)

//		let batteryVoltage = BatteryVoltage(rawValue: 0x02)!
//		return batteryVoltage
	}

	/**
	 * Charging status information.
	 */
	func batteryStateChanged() -> Future<Void, DeviceError> { // -> ChargeState {
		return enqueueCommand(deviceId: .power, commandId: PowerCommandId.batteryStateChanged)

//		let batteryState = ChargeState(rawValue: 0x02)!
//		return batteryState
	}

	/**
	 * Returns the battery percentage.
	 */
	func getBatteryPercentage() -> Future<Void, DeviceError> { // -> Int {
		return enqueueCommand(deviceId: .power, commandId: PowerCommandId.getBatteryPercentage)

//		let batteryPercentage = 100
//		return batteryPercentage
	}
}
