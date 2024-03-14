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
		resetYaw()
		resetLocator { [weak self] completion in
			guard let self = self else {
				return
			}

			self.delegate?.deviceDidWake?(self)
		}
	}

	@objc func sendSoftSleepCommand() {
		enterSoftSleep() { [weak self] completion in
			guard let self = self else {
				return
			}

			self.delegate?.deviceDidSleep?(self)
		}
	}

	@objc func sendPingCommand() {
		ping()
	}

	@objc func sendDelayCommand(duration: Float) {
		enqueueDelayCommand(duration)
	}

	@objc func sendDriveWithHeadingCommand(speed: UInt8, heading: UInt16, direction: Direction, duration: Float, driveId: UInt8) {
		driveWithHeading(speed: speed, heading: heading, direction: direction)
		enqueueDelayCommand(duration)
		driveWithHeading(speed: 0, heading: 0, direction: .forward) { [weak self] completion in
			guard let self = self else {
				return
			}

			self.delegate?.deviceDidFinishDriving?(self, driveId: driveId)
		}
	}

	@objc func sendSetAllLEDColorsCommand(front: CGColor, back: CGColor) {
		setAllLEDColors(front: front, back: back)
	}

	@objc func sendSetMainLEDColorCommand(_ color: CGColor) {
		setMainLEDColor(color)
	}

	@objc func sendSetBackLEDColorCommand(_ color: CGColor) {
		setBackLEDColor(color)
	}
}
