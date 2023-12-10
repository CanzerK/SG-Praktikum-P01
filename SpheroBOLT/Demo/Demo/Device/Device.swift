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

///
/// @method deviceCoordinatorDidConnectDevice
///
/// @param coordinator The instance of the coordinator that sent the message.
/// @param device The device that was connected.
///
//func deviceCoordinatorDidConnectDevice(_ coordinator: DeviceCoordinator, device: Device, error: DeviceError?)

///
/// @method deviceCoordinatorDidDisconnectDevice
///
/// @param coordinator The instance of the coordinator that sent the message.
/// @param device The device that was disconnected.
///
//func deviceCoordinatorDidDisconnectDevice(_ coordinator: DeviceCoordinator, device: Device, error: DeviceError?)

protocol DeviceDelegate: AnyObject {
	/**
	 * @discussion Called when the device changes its state.
	 *
	 * @parameter The device instance.
	 */
	func deviceDidChangeState(_ device: Device)

	/**
	 * @discussion Called when the device changes its state.
	 *
	 * @parameter The device instance.
	 */
	func deviceDidUpdateConnectionState(_ device: Device, state: ConnectionState, error: DeviceError?)
}

class Device: NSObject {
	/// Underlying bluetooth peripheral instance.
	private var peripheral: CBPeripheral

	/// Command buffer to enqueue all device commands into.
	private var commandQueue: CommandQueue

	/// Current sequence number of the command.
	private var sequenceNumber: UInt8 = 0

	/// The delegate of the device instance that will receive messages of changes.
	weak var delegate: DeviceDelegate?

	/// Stored during the call to connect and invoked upon completion of connection.
	var connectionCompletion: ((Result<ConnectionProgress, DeviceError>) -> Void)?

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
	func connect(toManager centralManager: CBCentralManager, completion: ((Result<ConnectionProgress, DeviceError>) -> Void)?) {
		state = .connecting

		centralManager.connect(peripheral)

		connectionCompletion = completion
	}

	func completeConnection() {
		// Create a new publisher by calling connect on the device.
		// Whenever we are completed we mark the device as connected.
		commandQueue.connect(self, completion: { [weak self] result in
			guard let self = self else {
				return
			}

			switch result {
			case .success(let progress):
				switch progress {
					case .updated(let state):
						switch state {
						case .connecting:
							self.state = .connecting
						case .connected:
							// At this point we know we have successfully passed the antidos protection and we are connected to the central manager.
							self.state = .connected
						default: break
						}
					default:
						self.state = .connected
				}
			case .failure(_):
				self.state = .discovered
			}

			self.connectionCompletion?(result)
		})
	}

	/// Disconnect from the given device using the manager. Don't call directly!
	func disconnect(fromManager manager: CBCentralManager) {
		commandQueue.cancelAll()

		manager.cancelPeripheralConnection(peripheral)

		state = .discovered
	}

	/// Returns the sequence number of the next packet.
	private var nextSequenceNumber: UInt8 {
		get {
			sequenceNumber += 1

			return (sequenceNumber % 255)
		}
	}

	internal func enqueueCommandInternal<R, T: CommandRepresentable>(_ dump: R.Type,
																	 deviceId: DeviceId,
																	 commandId: T,
																	 sourceId: UInt8? = nil,
																	 targetId: UInt8? = nil,
																	 completion: ((Result<Void, DeviceError>) -> Void)?) {
		var flags: PacketFlags = [.requestsResponse, .resetsInactivityTimeout]

		if (sourceId != nil) {
			flags.insert(PacketFlags.commandHasSourceId)
		}

		if (targetId != nil) {
			flags.insert(PacketFlags.commandHasTargetId)
		}

		let command = Command(flags.rawValue,
							  deviceId: deviceId.rawValue,
							  commandId: commandId.rawValue,
							  sequenceNumber: nextSequenceNumber,
							  contents: nil,
							  sourceId: sourceId,
							  targetId: targetId)

		return commandQueue.enqueue(command: command, completion: completion)
	}

	internal func enqueueCommandInternal<R, T: CommandRepresentable, D: CommandDataConvertible>(_ dump: R.Type,
																								deviceId: DeviceId,
																								commandId: T,
																								data: D?,
																								sourceId: UInt8? = nil,
																								targetId: UInt8? = nil,
																								completion: ((Result<Void, DeviceError>) -> Void)?) {
		var flags: PacketFlags = [.requestsResponse, .resetsInactivityTimeout]

		if (sourceId != nil) {
			flags.insert(PacketFlags.commandHasSourceId)
		}

		if (targetId != nil) {
			flags.insert(PacketFlags.commandHasTargetId)
		}

		let command = Command(flags.rawValue,
							  deviceId: deviceId.rawValue,
							  commandId: commandId.rawValue,
							  sequenceNumber: nextSequenceNumber,
							  contents: data?.packet,
							  sourceId: sourceId,
							  targetId: targetId)

		return commandQueue.enqueue(command: command, completion: completion)
	}

	internal func enqueueCommandInternal<R: DataInitializable, T: CommandRepresentable>(_ dump: R.Type,
																						deviceId: DeviceId,
																						commandId: T,
																						sourceId: UInt8? = nil,
																						targetId: UInt8? = nil,
																						completion: ((Result<R, DeviceError>) -> Void)?) {
		var flags: PacketFlags = [.requestsResponse, .resetsInactivityTimeout]

		if (sourceId != nil) {
			flags.insert(PacketFlags.commandHasSourceId)
		}

		if (targetId != nil) {
			flags.insert(PacketFlags.commandHasTargetId)
		}

		let command = Command(flags.rawValue,
							  deviceId: deviceId.rawValue,
							  commandId: commandId.rawValue,
							  sequenceNumber: nextSequenceNumber,
							  contents: nil,
							  sourceId: sourceId,
							  targetId: targetId)

		commandQueue.enqueueWithData(command: command, completion: completion)
	}

	internal func enqueueCommandInternal<R: DataInitializable, T: CommandRepresentable, D: CommandDataConvertible>(_ dump: R.Type,
																												   deviceId: DeviceId,
																												   commandId: T,
																												   data: D?,
																												   sourceId: UInt8? = nil,
																												   targetId: UInt8? = nil,
																												   completion: ((Result<R, DeviceError>) -> Void)?) {
		var flags: PacketFlags = [.requestsResponse, .resetsInactivityTimeout]

		if (sourceId != nil) {
			flags.insert(PacketFlags.commandHasSourceId)
		}

		if (targetId != nil) {
			flags.insert(PacketFlags.commandHasTargetId)
		}

		let command = Command(flags.rawValue, 
							  deviceId: deviceId.rawValue,
							  commandId: commandId.rawValue,
							  sequenceNumber: nextSequenceNumber,
							  contents: data?.packet,
							  sourceId: sourceId,
							  targetId: targetId)

		commandQueue.enqueueWithData(command: command, completion: completion)
	}
}
