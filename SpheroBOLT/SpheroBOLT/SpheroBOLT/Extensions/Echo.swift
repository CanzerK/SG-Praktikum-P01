//
//  Echo.swift
//  SpheroBOLT
//
//  Created by Zhivko Bogdanov on 26.11.23.
//

import Foundation
import Combine

public enum ProcessorCommandId: UInt8 {
	case echo = 0x00
}

/// Echo extensions to the device object.
extension Device {
	/**
	 * Pings the device
	 */
	public func echo() -> CommandResponseType<Void> {
		return enqueueCommand(deviceId: .apiProcessor,
							  commandId: ProcessorCommandId.echo)
	}
}
