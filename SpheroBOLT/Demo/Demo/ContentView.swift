//
//  ContentView.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 09.11.23.
//

import SwiftUI

struct SpheroDevice {
	var name: String
}

extension SpheroDevice {
	static let testDevices = [SpheroDevice(name: "Sphero 1"),
							  SpheroDevice(name: "Sphero 2")]
}

struct ContentView: View {
	var body: some View {
		NavigationView {
			VStack {
				List(SpheroDevice.testDevices, id: \.name, rowContent: DeviceRow.init)
				.navigationTitle("Sphero BOLTs")

				Spacer()

				HStack {
					Button(action: { }, label: {
						Text("Ping")
							.padding(8)
							.background(RoundedRectangle(cornerRadius: 8).fill(SwiftUI.Color(.systemBlue)))
							.foregroundStyle(.white)
					})
					Button(action: { }, label: {
						Text("Color")
							.padding(8)
							.background(RoundedRectangle(cornerRadius: 8).fill(SwiftUI.Color(.systemBlue)))
							.foregroundStyle(.white)
					})
				}
			}
		}
		.accentColor(.purple)
	}
}

struct DeviceRow: View {
	var device: SpheroDevice


	var body: some View {
		HStack {
			Text(device.name)

			Spacer()

			Button(action: { }, label: {
				Text("Connect")
					.padding(8)
					.background(RoundedRectangle(cornerRadius: 8).fill(SwiftUI.Color(.systemGreen)))
					.foregroundStyle(.white)
			})
		}
		.padding(.vertical)
	}
}

#Preview {
	ContentView()
}
