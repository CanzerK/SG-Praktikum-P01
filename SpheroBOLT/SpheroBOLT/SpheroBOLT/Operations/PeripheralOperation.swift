//
//  PeripheralOperation.swift
//  SpheroBOLT
//
//  Created by Zhivko Bogdanov on 05.12.23.
//

import Foundation
import CoreBluetooth

/// Base for all peripheral operations.
class PeripheralOperation<R>: SerialOperation {
	internal let packet: Data
	internal let peripheral: CBPeripheral
	internal var completion: ((Result<R, DeviceError>) -> Void)?

	fileprivate var operationCancelled = false

	override var isCancelled: Bool {
		return operationCancelled
	}

	init(_ packet: Data,
		 peripheral: CBPeripheral,
		 completion: ((Result<R, DeviceError>) -> Void)?) {
		self.packet = packet
		self.peripheral = peripheral
		self.completion = completion

		super.init()
	}

	/// Called when the operation has been cancelled.
	override func cancel() {
		super.cancel()

		operationCancelled = true
	}
}
