//
//  DemoApp.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 09.11.23.
//

import SwiftUI
import CoreBluetooth
import Combine

@main
struct DemoApp: App {
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
	}

	let deviceManager = DeviceManagerDemo()

	init() {
		
	}
}
