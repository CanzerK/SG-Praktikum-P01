//
//  Navigation.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 20.11.23.
//

import Foundation

enum Direction: UInt8 {
	case forward = 0x00
	case backward = 0x01
}

enum DirectionRawMotor: UInt8 {
	case disable = 0x00
	case forward = 0x01
	case reverse = 0x02
}

enum StabilizationIndex: UInt8 {
	case noControlSystem = 0x00
	case fullControlSystem = 0x01
	case pitchControlSystem = 0x02
	case rollControlSystem = 0x03
	case yawControlSystem = 0x04
	case speedAndYawControlSystem = 0x05
}

enum DriveCommand: UInt8 {
	case rawMotor = 0x01
	case setAckermannSteeringParameters = 0x02
	case drift = 0x03
	case absoluteYawSteering = 0x04
	case enableFlipDrive = 0x05
	case resetYaw = 0x06
	case driveWithHeading = 0x07
	case tankDrive = 0x08
	case rcCarDrive = 0x09
	case driveToPosition = 0x0a
	case setStabilization = 0x0c
}