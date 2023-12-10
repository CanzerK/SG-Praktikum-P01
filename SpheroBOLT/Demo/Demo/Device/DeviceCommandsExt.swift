//
//  DeviceCommandsExt.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 05.12.23.
//

import Foundation
import CoreBluetooth
import Combine

extension Device {
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
