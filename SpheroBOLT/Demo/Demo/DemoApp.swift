//
//  DemoApp.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 09.11.23.
//

import SwiftUI
import Combine

@main
struct DemoApp: App {
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
	}

	var spheroManager: DeviceCoordinator!
	var cancellables = [AnyCancellable]()

	init() {
		spheroManager = DeviceCoordinator()
		spheroManager.state
			.receive(on: DispatchQueue.main)
			.filter { state in
				return state == .poweredOn
			}
			.sink(receiveValue: { state in
				print(state)
			})
			.store(in: &cancellables)

//		spheroManager.findDevices()
//			.receive(on: DispatchQueue.main)
//			.sink { error in
//				print(error)
//			} receiveValue: { device in
//				print(device.name!)
//			}
//			.store(in: &cancellables)

	}
}
