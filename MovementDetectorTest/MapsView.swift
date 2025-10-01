//
//  MapsView.swift
//  MovementDetectorTest
//
//  Created by Adrian Yusufa Rachman on 01/10/25.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct MapsView: View {
    // MARK: - Properties

    // Create an observed object for the LocationManager.
    @StateObject private var locationManager = LocationManager()

    // MARK: - Body

    var body: some View {
        ZStack {
            Map {
                // This will draw a line connecting all the tracked coordinates.
                MapPolyline(coordinates: locationManager.trackedLocations)
                    .stroke(.blue, lineWidth: 5)

                // This will place a marker at each coordinate.
                ForEach(locationManager.trackedLocations.indices, id: \.self) { index in
                    let coordinate = locationManager.trackedLocations[index]
                    Marker("Point \(index + 1)", coordinate: coordinate)
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea(edges: .bottom)

            VStack {
                Spacer()
                Button(action: {
                    locationManager.toggleTracking()
                }) {
                    Text(locationManager.isTracking ? "Stop Tracking" : "Start Tracking")
                        .font(.headline)
                        .padding()
                        .background(locationManager.isTracking ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
}


class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()

    @Published var isTracking = false
    @Published var trackedLocations: [CLLocationCoordinate2D] = []

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 10
    }

    func toggleTracking() {
        if self.isTracking {
            manager.stopUpdatingLocation()
            print("🛑 Tracking stopped. Collected \(trackedLocations.count) points.")
        } else {
            trackedLocations = []
            manager.startUpdatingLocation()
            print("▶️ Tracking started.")
        }
        isTracking.toggle()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }

        // Append to the trackedLocations array within this class
        trackedLocations.append(latestLocation.coordinate)
        print("📍 New location added: \(latestLocation.coordinate)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❗️ Error getting location: \(error.localizedDescription)")
    }
}


// MARK: - Preview

#Preview {
    MapsView()
}
