//
//  DeviceObjCFunctions.swift
//  SpheroBOLT-Godot
//
//  Created by Zhivko Bogdanov on 12.03.24.
//

import Foundation
import CoreGraphics

extension Device {
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

	@objc func sendDriveWithHeadingCommand(speed: UInt8, heading: UInt16, direction: Direction, duration: Float, driveId: UInt8) {
		driveWithHeading(speed: speed, heading: heading, direction: direction)
			.flatMap({ () in
				self.enqueueDelayCommand(duration)
			})
//			.delay(for: .seconds(2), scheduler: DispatchQueue.main, options: .none)
			.flatMap({ Void in
				self.driveWithHeading(speed: 0, heading: 0, direction: .forward)
			})
			.receive(on: DispatchQueue.main)
			.sink { [weak self] completion in
				guard let self = self else {
					return
				}

				self.delegate?.deviceDidFinishDriving?(self, driveId: driveId)
			} receiveValue: { _ in

			}
			.store(in: &cancellables)
	}

	@objc func sendSetAllLEDColorsCommand(front: CGColor, back: CGColor) {
		setAllLEDColors(front: front, back: back)
			.receive(on: DispatchQueue.main)
			.sink { _ in

			} receiveValue: { value in

			}
			.store(in: &cancellables)
	}

	@objc func sendSetMainLEDColorCommand(_ color: CGColor) {
		setMainLEDColor(color)
			.receive(on: DispatchQueue.main)
			.sink { _ in

			} receiveValue: { value in

			}
			.store(in: &cancellables)
	}

	@objc func sendSetBackLEDColorCommand(_ color: CGColor) {
		setBackLEDColor(color)
			.receive(on: DispatchQueue.main)
			.sink { _ in

			} receiveValue: { value in

			}
			.store(in: &cancellables)
	}
}
