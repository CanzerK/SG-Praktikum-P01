//
//  Queue.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 23.11.23.
//

import Foundation
import CoreBluetooth

final class CommandOperation: Operation, CBPeripheralDelegate {
	private let packet: Data
	private let peripheral: CBPeripheral
	private let apiCharacteristic: CBCharacteristic
	private var packetWritten = false;

	override var isAsynchronous: Bool {
		return false
	}

	override var isConcurrent: Bool {
		return false
	}

	override var isFinished: Bool {
		return packetWritten
	}

	init(_ packet: Data, peripheral: CBPeripheral, apiCharacteristic: CBCharacteristic) {
		self.packet = packet
		self.peripheral = peripheral
		self.apiCharacteristic = apiCharacteristic

		super.init()
	}

	override func main() {
		guard isCancelled else {
			return
		}

		peripheral.writeValue(packet, for: apiCharacteristic, type: .withResponse)
	}

	internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		packetWritten = true
	}
}

struct CommandQueue {
	private let operationQueue = OperationQueue()

	private let peripheral: CBPeripheral
	private let apiCharacteristic: CBCharacteristic

	init(_ peripheral: CBPeripheral, apiCharacteristic: CBCharacteristic) {
		self.peripheral = peripheral
		self.apiCharacteristic = apiCharacteristic

		self.operationQueue.maxConcurrentOperationCount = 1
		self.operationQueue.qualityOfService = .default
		self.operationQueue.name = "CommandQueue"
	}

	func enqueue(_ command: Command) {
		operationQueue.addOperation(CommandOperation(command.packet, peripheral: peripheral, apiCharacteristic: apiCharacteristic))
	}

	mutating func cancelAll() {
		operationQueue.cancelAllOperations()
	}
}
