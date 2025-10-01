//
//  SLC.swift
//  MovementDetectorTest
//
//  Created by Adrian Yusufa Rachman on 01/10/25.
//
import CoreLocation
import Combine

class SignificantLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published private(set) var recentLocations: [CLLocation] = []
    @Published var statusMessage: String = "Initializing..."

    override init() {
        super.init()
        statusMessage = "Requesting authorization..."
        locationManager.requestAlwaysAuthorization()
        startMonitoring()
    }

    func startMonitoring() {
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.startMonitoringSignificantLocationChanges()
            statusMessage = "Monitoring started"
            print("SLC: Monitoring started.")
        } else {
            print("Significant location monitoring is not available on this device.")
            statusMessage = "Significant location monitoring not available"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        switch status {
        case .authorizedAlways:
            statusMessage = "Authorized Always. Monitoring significant changes."
            print("SLC: Authorized Always.")
            startMonitoring()
        case .authorizedWhenInUse:
            statusMessage = "Authorized When In Use. Monitoring while app is active."
            print("SLC: Authorized When In Use.")
            startMonitoring()
        case .denied:
            statusMessage = "Authorization denied. Enable in Settings."
            print("SLC: Authorization denied.")
        case .restricted:
            statusMessage = "Authorization restricted."
            print("SLC: Authorization restricted.")
        case .notDetermined:
            statusMessage = "Awaiting authorization..."
            print("SLC: Authorization not determined.")
        @unknown default:
            statusMessage = "Unknown authorization status."
            print("SLC: Unknown authorization status.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.recentLocations.insert(location, at: 0)
            if self.recentLocations.count > 20 {
                self.recentLocations.removeLast(self.recentLocations.count - 20)
            }
            let df = DateFormatter()
            df.dateStyle = .none
            df.timeStyle = .medium
            self.statusMessage = "Last update: \(df.string(from: Date()))"
            print("Significant location change detected: \(location.coordinate)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        statusMessage = "Location error: \(error.localizedDescription)"
        print("Location manager error: \(error.localizedDescription)")
    }
}
