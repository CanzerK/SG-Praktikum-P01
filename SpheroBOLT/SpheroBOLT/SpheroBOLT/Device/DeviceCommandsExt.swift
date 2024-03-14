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
	internal func enqueueDelayCommandInternal(_ duration: Float,
											  completion: ((Result<Void, DeviceError>) -> Void)?) {
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

	internal func enqueueDelayCommand(_ duration: Float) -> CommandResponseType<Void> {
		Deferred {
			Future<Void, DeviceError> { [weak self] promise in
				guard let self = self else {
					promise(.failure(.unableToWrite))

					return
				}

				return self.enqueueDelayCommandInternal(duration) {
					switch $0 {
					case .success(let value):
						promise(.success(value))
					case .failure(let error):
						promise(.failure(error))
					}
				}
			}
		}.eraseToAnyPublisher()
	}

	internal func enqueueCommand<T: CommandRepresentable>(deviceId: DeviceId, commandId: T) -> CommandResponseType<Void> {
		Deferred {
			Future<Void, DeviceError> { [weak self] promise in
				guard let self = self else {
					promise(.failure(.unableToWrite))

					return
				}

				return self.enqueueCommandInternal(Void.self, deviceId: deviceId, commandId: commandId) {
					switch $0 {
					case .success(let value):
						promise(.success(value))
					case .failure(let error):
						promise(.failure(error))
					}
				}
			}
		}.eraseToAnyPublisher()
	}

	internal func enqueueCommand<R: DataInitializable, T: CommandRepresentable>(deviceId: DeviceId, commandId: T) -> CommandResponseType<R> {
		Deferred {
			Future<R, DeviceError> { [weak self] promise in
				guard let self = self else {
					promise(.failure(.unableToWrite))

					return
				}

				return self.enqueueCommandInternal(R.self, deviceId: deviceId, commandId: commandId) {
					switch $0 {
					case .success(let value):
						promise(.success(value))
					case .failure(let error):
						promise(.failure(error))
					}
				}
			}
		}.eraseToAnyPublisher()
	}

	internal func enqueueCommand<T: CommandRepresentable, D: CommandDataConvertible>(deviceId: DeviceId,
																					 commandId: T,
																					 data: D?,
																					 sourceId: UInt8? = nil,
																					 targetId: UInt8? = nil) -> CommandResponseType<Void> {
		Deferred {
			Future<Void, DeviceError> { [weak self] promise in
				guard let self = self else {
					promise(.failure(.unableToWrite))

					return
				}

				return self.enqueueCommandInternal(Void.self, deviceId: deviceId, commandId: commandId, data: data, sourceId: sourceId, targetId: targetId) {
					switch $0 {
					case .success(let value):
						promise(.success(value))
					case .failure(let error):
						promise(.failure(error))
					}
				}
			}
		}.eraseToAnyPublisher()
	}

	struct DefaultCommandDataConvertible: CommandDataConvertible {
		var packet: Array<UInt8> {
			return Array<UInt8>()
		}
	}

	internal func enqueueCommand<T: CommandRepresentable>(deviceId: DeviceId,
														  commandId: T,
														  sourceId: UInt8? = nil,
														  targetId: UInt8? = nil) -> CommandResponseType<Void> {
		return enqueueCommand(deviceId: deviceId, commandId: commandId, data: Optional<DefaultCommandDataConvertible>.none, sourceId: sourceId, targetId: targetId)
	}
}
