//
//  Sensor.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 26.11.23.
//

import Foundation
import Combine

enum SensorCommandId: UInt8 {
	case resetLocator = 0x13
}


/// Navigation and drive extensions to the device object.
extension Device {
	/**
	 * Sets the color of the main matrix.
	 * @param speed Value from 0 to 255.
	 * @param heading Value from 0 to 360
	 * @param direction Direction of drive.
	 */
	func resetLocator() -> CommandResponseType<Void> {
		return enqueueCommand(deviceId: .sensors,
							  commandId: SensorCommandId.resetLocator,
							  sourceId: nil,
							  targetId: 0x12)
	}

}
