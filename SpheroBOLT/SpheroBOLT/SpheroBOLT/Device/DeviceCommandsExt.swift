//
//  DeviceCommandsExt.swift
//  SpheroBOLT
//
//  Created by Zhivko Bogdanov on 05.12.23.
//

import Foundation
import CoreBluetooth
import Combine

extension Device {
	struct DefaultCommandDataConvertible: CommandDataConvertible {
		var packet: Array<UInt8> {
			return Array<UInt8>()
		}
	}

	internal func enqueueDelayCommand(_ duration: Float,
									  completion: ((Result<Void, DeviceError>) -> Void)? = nil) {
		return commandQueue.enqueueDelay(duration, completion: completion)
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
																								completion: ((Result<Void, DeviceError>) -> Void)? = nil) {
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
																						completion: ((Result<R, DeviceError>) -> Void)? = nil) {
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
																												   completion: ((Result<R, DeviceError>) -> Void)? = nil) {
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

	internal func enqueueCommand<T: CommandRepresentable>(deviceId: DeviceId,
														  commandId: T,
														  completion: ((Result<Void, DeviceError>) -> Void)? = nil) {
		self.enqueueCommandInternal(Void.self, deviceId: deviceId, commandId: commandId, completion: completion)
	}

	internal func enqueueCommand<R: DataInitializable, T: CommandRepresentable>(deviceId: DeviceId,
																				commandId: T,
																				completion: ((Result<R, DeviceError>) -> Void)?) {
		self.enqueueCommandInternal(R.self, deviceId: deviceId, commandId: commandId, completion: completion)
	}

	internal func enqueueCommand<T: CommandRepresentable, D: CommandDataConvertible>(deviceId: DeviceId,
																					 commandId: T,
																					 data: D?,
																					 sourceId: UInt8? = nil,
																					 targetId: UInt8? = nil,
																					 completion: ((Result<Void, DeviceError>) -> Void)? = nil) {
		self.enqueueCommandInternal(Void.self,
									deviceId: deviceId,
									commandId: commandId,
									data: data,
									sourceId: sourceId,
									targetId: targetId,
									completion: completion)
	}

	internal func enqueueCommand<T: CommandRepresentable>(deviceId: DeviceId,
														  commandId: T,
														  sourceId: UInt8? = nil,
														  targetId: UInt8? = nil,
														  completion: ((Result<Void, DeviceError>) -> Void)? = nil) {
		return enqueueCommand(deviceId: deviceId,
							  commandId: commandId,
							  data: Optional<DefaultCommandDataConvertible>.none,
							  sourceId: sourceId,
							  targetId: targetId,
							  completion: completion)
	}
}
