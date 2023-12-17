//
//  Device.swift
//  SpheroBOLT
//
//  Created by Zhivko Bogdanov on 11.11.23.
//

import Foundation
import Combine
import CoreBluetooth

@objc public enum DeviceState: Int {
	case discovered
	case connecting
	case connected
}

@objc public protocol DeviceDelegate: NSObjectProtocol {
	/**
	 * @discussion Called when the device changes its state.
	 *
	 * @parameter The device instance.
	 */
	@objc optional func deviceDidChangeState(_ device: Device)

	/**
	 * @discussion Called when the device successfully changes its connection state.
	 *
	 * @parameter The device instance.
	 */
	@objc optional func deviceDidUpdateConnectionState(_ device: Device, state: ConnectionState)

	/**
	 * @discussion Called when the device fails its connection state.
	 *
	 * @parameter The device instance.
	 */
	@objc optional func deviceDidFailConnectionState(_ device: Device, error: NSError?)

	/**
	 * @discussion Called when the device wakes.
	 *
	 * @parameter The device instance.
	 */
	@objc optional func deviceDidWake(_ device: Device)

	/**
	 * @discussion Called when the device sleeps.
	 *
	 * @parameter The device instance.
	 */
	@objc optional func deviceDidSleep(_ device: Device)
}

@objc public class Device: NSObject {
	/// Underlying bluetooth peripheral instance.
	private var peripheral: CBPeripheral

	/// Command buffer to enqueue all device commands into.
	internal var commandQueue: CommandQueue

	/// Current sequence number of the command.
	private var sequenceNumber: UInt8 = 0

	/// All cancellable operations.
	private var cancellables = Set<AnyCancellable>()

	/// Returns the sequence number of the next packet.
	internal var nextSequenceNumber: UInt8 {
		get {
			sequenceNumber += 1

			return (sequenceNumber % 255)
		}
	}

	/// The delegate of the device instance that will receive messages of changes.
	@objc public weak var delegate: DeviceDelegate?

	/// The current state of the device depends on what the coordinator does with it and is based on the connection to it.
	@objc public var state = DeviceState.discovered {
		didSet {
			delegate?.deviceDidChangeState?(self)
		}
	}

	/// Representative name of the device.
	@objc public var name: String? {
		return peripheral.name
	}

	open override var hash: Int {
		return peripheral.hash
	}

	init(_ peripheral: CBPeripheral) {
		self.commandQueue = CommandQueue(peripheral)
		self.peripheral = peripheral

		super.init()
	}

	deinit {
		cancellables.removeAll()
	}

	open override func isEqual(_ object: Any?) -> Bool {
		if let otherDevice = object as? Device {
			return peripheral == otherDevice.peripheral
		} else if let otherPeripheral = object as? CBPeripheral {
			return peripheral == otherPeripheral
		} else {
			return false
		}
	}

	/// Connect to the given device using the manager. Don't call directly!
	func connect(toManager centralManager: CBCentralManager) {
		state = .connecting

		centralManager.connect(peripheral)
	}

	func failConnection(_ error: DeviceError) {
		self.delegate?.deviceDidFailConnectionState?(self, error: error as NSError)
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
					self.delegate?.deviceDidUpdateConnectionState?(self, state: state)

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
			case .failure(let error):
				self.state = .discovered

				self.delegate?.deviceDidFailConnectionState?(self, error: error as NSError)
			}
		})
	}

	/// Disconnect from the given device using the manager. Don't call directly!
	func disconnect(fromManager manager: CBCentralManager) {
		commandQueue.cancelAll()

		manager.cancelPeripheralConnection(peripheral)
	}

	@objc func sendWakeCommand() {
		wake()
			.flatMap { self.resetYaw() }
			.flatMap { self.resetLocator() }
			.receive(on: DispatchQueue.main)
			.sink { [weak self] completion in
				guard let self = self else {
					return
				}

				self.delegate?.deviceDidWake?(self)
			} receiveValue: { value in

			}
			.store(in: &cancellables)
	}

	@objc func sendSoftSleepCommand() {
		enterSoftSleep()
			.receive(on: DispatchQueue.main)
			.sink { [weak self] completion in
				guard let self = self else {
					return
				}

				self.delegate?.deviceDidSleep?(self)
			} receiveValue: { value in

			}
			.store(in: &cancellables)
	}
}
