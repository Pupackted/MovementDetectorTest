//
//  MovementDetectorTestApp.swift
//  MovementDetectorTest
//
//  Created by Adrian Yusufa Rachman on 30/09/25.
//

import SwiftUI

@main
struct MovementDetectorTestApp: App {
    @StateObject private var locationManager = LocationManager()  // added this for auto launching the app using SLC
   

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)  // added this for auto launching the app using SLC
        }
    }
}
