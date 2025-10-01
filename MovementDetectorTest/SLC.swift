//
//  SLC.swift
//  MovementDetectorTest
//
//  Created by Adrian Yusufa Rachman on 01/10/25.
//
import CoreLocation
import Combine

// NEW: A Codable struct to hold identifiable location entries.
struct LocationEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(id: UUID = UUID(), location: CLLocation) {
        self.id = id
        self.date = location.timestamp
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
    }
}


class SignificantLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    // UPDATED: This now holds the persistent history of locations.
    @Published private(set) var locationHistory: [LocationEntry] = [] {
        didSet {
            saveHistory()
        }
    }
    
    @Published var authorizationStatusMessage: String = "Initializing..."
    
    private let historySaveKey = "LocationHistory"

    override init() {
        super.init()
        loadHistory() // Load history on initialization
        authorizationStatusMessage = "Requesting authorization..."
        locationManager.delegate = self // Set delegate
        locationManager.requestAlwaysAuthorization()
    }

    func startMonitoring() {
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.startMonitoringSignificantLocationChanges()
            print("SLC: Monitoring started.")
        } else {
            print("Significant location monitoring is not available on this device.")
            authorizationStatusMessage = "Significant location monitoring not available"
        }
    }

    // NEW: Function to clear the location history.
    func clearHistory() {
        locationHistory.removeAll()
    }
    
    // NEW: Function to save the history array to UserDefaults.
    private func saveHistory() {
        if let encodedData = try? JSONEncoder().encode(locationHistory) {
            UserDefaults.standard.set(encodedData, forKey: historySaveKey)
            print("Location history saved! (\(locationHistory.count) entries)")
        }
    }
    
    // NEW: Function to load the history from UserDefaults.
    private func loadHistory() {
        if let savedData = UserDefaults.standard.data(forKey: historySaveKey) {
            if let decodedHistory = try? JSONDecoder().decode([LocationEntry].self, from: savedData) {
                self.locationHistory = decodedHistory
                print("Location history loaded! (\(locationHistory.count) entries)")
                return
            }
        }
        self.locationHistory = []
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        switch status {
        case .authorizedAlways:
            authorizationStatusMessage = "Authorized Always. Monitoring significant changes."
            print("SLC: Authorized Always.")
            startMonitoring()
        case .authorizedWhenInUse:
            authorizationStatusMessage = "Authorized When In Use. Monitoring while app is active."
            print("SLC: Authorized When In Use.")
            startMonitoring()
        case .denied:
            authorizationStatusMessage = "Authorization denied. Enable in Settings."
            print("SLC: Authorization denied.")
        case .restricted:
            authorizationStatusMessage = "Authorization restricted."
            print("SLC: Authorization restricted.")
        case .notDetermined:
            authorizationStatusMessage = "Awaiting authorization..."
            print("SLC: Authorization not determined.")
        @unknown default:
            authorizationStatusMessage = "Unknown authorization status."
            print("SLC: Unknown authorization status.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            // UPDATED: Insert new location entry into the history.
            self.locationHistory.insert(LocationEntry(location: location), at: 0)
            print("Significant location change detected: \(location.coordinate)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        authorizationStatusMessage = "Location error: \(error.localizedDescription)"
        print("Location manager error: \(error.localizedDescription)")
    }
}
