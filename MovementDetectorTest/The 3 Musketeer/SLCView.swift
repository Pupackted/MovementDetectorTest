//
//  SLCView.swift
//  MovementDetectorTest
//
//  Created by Adrian Yusufa Rachman on 02/10/25.
//

import Foundation
import CoreLocation
import Combine
import SwiftUI


struct SignificantLocationView: View {
    @ObservedObject var slm: SignificantLocationManager

    private let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .medium // Changed to medium for more detail
        return df
    }()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.cyan.opacity(0.6), Color.indigo.opacity(0.6)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                headerView
                
                // UPDATED: Swapped the logic to display history list
                if slm.locationHistory.isEmpty {
                    Text("No significant location changes yet.")
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.vertical, 12)
                        .frame(maxHeight: .infinity)
                } else {
                    historyListView
                }
            }
            .padding()
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Significant Locations")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .padding(.top, 8)
            
            Spacer()
            
            if !slm.locationHistory.isEmpty {
                Button("Clear") { slm.clearHistory() }
                    .font(.subheadline.weight(.semibold))
                    .tint(.white)
            }
        }
    }
    
    private var historyListView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                // UPDATED: Loop through the new locationHistory
                ForEach(slm.locationHistory) { item in
                    HStack(spacing: 12) {
                        Image(systemName: "location.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.cyan)
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(String(format: "%.5f", item.latitude)), \(String(format: "%.5f", item.longitude))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(timeFormatter.string(from: item.date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.vertical, 4)
        }
    }
}


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
        // --- FIX IS HERE ---
        // Use Date() to get the current time the event is processed,
        // instead of location.timestamp.
        self.date = Date()
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
        
        // It's also good practice to check if the location data isn't too old.
        let locationAge = -location.timestamp.timeIntervalSinceNow
        if locationAge > 60 { // If data is more than a minute old, maybe ignore it.
            print("Discarding old location data. Age: \(locationAge) seconds")
            return
        }
        
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
