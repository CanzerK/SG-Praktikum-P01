//
//  Echo.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 26.11.23.
//

import Foundation
import Combine

enum ProcessorCommandId: UInt8 {
	case echo = 0x00
}

/// Echo extensions to the device object.
extension Device {
	/**
	 * Pings the device
	 */
	func echo() -> CommandResponseType<Void> {
		return enqueueCommand(deviceId: .apiProcessor,
							  commandId: ProcessorCommandId.echo)
	}
}
