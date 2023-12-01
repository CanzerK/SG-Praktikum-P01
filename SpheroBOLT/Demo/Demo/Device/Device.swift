//
//  SpheroDevice.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 11.11.23.
//

import Foundation
import Combine
import CoreBluetooth

enum DeviceState {
	case discovered
	case connecting
	case connected
}

protocol DeviceDelegate {
	/**
	 * @discussion Called when the device changes its state.
	 *
	 * @parameter The device instance.
	 */
	func deviceDidChangeState(_ device: Device)
}

class Device: NSObject, CBPeripheralDelegate {
	/// Underlying bluetooth peripheral instance.
	private var peripheral: CBPeripheral

	/// Command buffer to enqueue all device commands into.
	private var commandQueue: CommandQueue

	/// All cancellable subscriptions to events.
	private var cancellables = Set<AnyCancellable>()

	/// Current sequence number of the command.
	private var sequenceNumber: UInt8 = 0

	/// The delegate of the device instance that will receive messages of changes.
	var delegate: DeviceDelegate?

	/// The current state of the device depends on what the coordinator does with it and is based on the connection to it.
	var state = DeviceState.discovered {
		didSet {
			delegate?.deviceDidChangeState(self)
		}
	}

	/// Representative name of the device.
	var name: String? {
		return peripheral.name
	}

	override var hash: Int {
		return peripheral.hash
	}

	init(_ peripheral: CBPeripheral) {
		self.commandQueue = CommandQueue(peripheral)
		self.peripheral = peripheral

		super.init()
	}

	override func isEqual(_ object: Any?) -> Bool {
		if let otherDevice = object as? Device {
			return peripheral == otherDevice.peripheral
		} else if let otherPeripheral = object as? CBPeripheral {
			return peripheral == otherPeripheral
		} else {
			return false
		}
	}

	/// Connect to the given device using the manager. Don't call directly!
	func connect(toCoordinator coordinator: DeviceCoordinator) -> AnyPublisher<ConnectionState, DeviceError> {
		state = .connecting

		// Create a new publisher by calling connect on the device.
		// Whenever we are completed we mark the device as connected.
		let connectPublisher = commandQueue.connect().map { output in
			switch output {
			case .updated(let state):
				switch state {
				case .connecting:
					self.state = .connecting
				case .connected:
					// At this point we know we have successfully passed the antidos protection and we are connected to the central manager.
					self.state = .connected
				default: break
				}

				return state
			default:
				return ConnectionState.connected
			}
		}
		.mapError {
			self.state = .discovered

			return $0
		}.eraseToAnyPublisher()

//		manager.connect(peripheral)

		// Re-publish the subscriber.
		return connectPublisher
	}

	/// Disconnect from the given device using the manager. Don't call directly!
	func disconnect(fromManager manager: CBCentralManager) {
		for cancellable in cancellables {
			cancellable.cancel()
		}

		cancellables.removeAll()

		commandQueue.cancelAll()

		manager.cancelPeripheralConnection(peripheral)

		state = .discovered
	}

	/// Returns the sequence number of the next packet.
	private var nextSequenceNumber: UInt8 {
		get {
			let nextSequenceNumber = (sequenceNumber + 1) % 255
			sequenceNumber += 1

			return nextSequenceNumber
		}
	}

	internal func enqueueCommand<T: CommandRepresentable>(deviceId: DeviceId, 
														  commandId: T,
														  sourceId: UInt8? = nil, 
														  targetId: UInt8? = nil) -> AnyPublisher<Void, DeviceError> {
		var flags: PacketFlags = [.requestsResponse, .resetsInactivityTimeout]

		if (sourceId != nil) {
			flags.insert(PacketFlags.commandHasSourceId)
		}

		if (targetId != nil) {
			flags.insert(PacketFlags.commandHasTargetId)
		}

		let command = Command(flags.rawValue, deviceId: deviceId.rawValue, commandId: commandId.rawValue, sequenceNumber: nextSequenceNumber, contents: nil, sourceId: sourceId, targetId: targetId)

		return commandQueue.enqueue(command)
	}

	internal func enqueueCommand<T: CommandRepresentable, D: CommandDataConvertible>(deviceId: DeviceId, 
																					 commandId: T,
																					 data: D?,
																					 sourceId: UInt8? = nil,
																					 targetId: UInt8? = nil) -> AnyPublisher<Void, DeviceError> {
		var flags: PacketFlags = [.requestsResponse, .resetsInactivityTimeout]

		if (sourceId != nil) {
			flags.insert(PacketFlags.commandHasSourceId)
		}

		if (targetId != nil) {
			flags.insert(PacketFlags.commandHasTargetId)
		}

		let command = Command(flags.rawValue, deviceId: deviceId.rawValue, commandId: commandId.rawValue, sequenceNumber: nextSequenceNumber, contents: data?.packet, sourceId: sourceId, targetId: targetId)

		return commandQueue.enqueue(command)
	}
}
