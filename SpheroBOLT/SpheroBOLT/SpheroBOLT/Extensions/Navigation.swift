//
//  Navigation.swift
//  SpheroBOLT
//
//  Created by Zhivko Bogdanov on 20.11.23.
//

import Foundation
import Combine

@objc public enum Direction: UInt8 {
	case forward = 0x00
	case backward = 0x01
}

public enum DirectionRawMotor: UInt8 {
	case disable = 0x00
	case forward = 0x01
	case reverse = 0x02
}

public enum StabilizationIndex: UInt8 {
	case noControlSystem = 0x00
	case fullControlSystem = 0x01
	case pitchControlSystem = 0x02
	case rollControlSystem = 0x03
	case yawControlSystem = 0x04
	case speedAndYawControlSystem = 0x05
}

enum DriveCommandId: UInt8 {
	case rawMotor = 0x01
	case setAckermannSteeringParameters = 0x02
	case absoluteYawSteering = 0x04
	case enableFlipDrive = 0x05
	case resetYaw = 0x06
	case driveWithHeading = 0x07
	case driveToPosition = 0x0a
	case setStabilization = 0x0c
}

/// Navigation and drive extensions to the device object.
extension Device {
	/**
	 * Moves the Sphero BOLT with a given speed in a given heading direction.
	 * @param speed Value from 0 to 255.
	 * @param heading Value from 0 to 360
	 * @param direction Direction of drive.
	 */
	public func driveWithHeading(speed: UInt8,
								 heading: UInt16, 
								 direction: Direction,
								 completion: ((Result<Void, DeviceError>) -> Void)? = nil) {
		enqueueCommand(deviceId: .driving,
					   commandId: DriveCommandId.driveWithHeading,
					   data: [speed.packet, (heading % 360).packet, direction.rawValue.packet],
					   sourceId: nil,
					   targetId: 0x12,
					   completion: completion)
	}

	/**
	 * Resets the device yaw.
	 */
	public func resetYaw(completion: ((Result<Void, DeviceError>) -> Void)? = nil) {
		enqueueCommand(deviceId: .driving,
					   commandId: DriveCommandId.resetYaw,
					   sourceId: nil,
					   targetId: 0x12,
					   completion: completion)
	}
}
