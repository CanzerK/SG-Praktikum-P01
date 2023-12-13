//
//  Sensor.swift
//  SpheroBOLT
//
//  Created by Zhivko Bogdanov on 26.11.23.
//

import Foundation
import Combine

public enum SensorCommandId: UInt8 {
	case resetLocator = 0x13
}


/// Navigation and drive extensions to the device object.
extension Device {
	/**
	 * Resets the device locator.
	 */
	public func resetLocator() -> CommandResponseType<Void> {
		return enqueueCommand(deviceId: .sensors,
							  commandId: SensorCommandId.resetLocator,
							  sourceId: nil,
							  targetId: 0x12)
	}

}
