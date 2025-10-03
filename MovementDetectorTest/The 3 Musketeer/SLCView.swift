//
import Foundation
import CoreLocation
import Combine
import SwiftUI
import MapKit // <-- 1. IMPORT MAPKIT

struct SignificantLocationView: View {
    @ObservedObject var slm: SignificantLocationManager

    private let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .medium
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

    // ▼▼▼▼▼ MODIFIED SECTION ▼▼▼▼▼
    private var historyListView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                // Use ForEach without binding
                ForEach(slm.locationHistory) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        // This is the original HStack with your location info
                        HStack(spacing: 12) {
                            Image(systemName: "location.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.cyan)
                                .frame(width: 28, height: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                // --- CORRECTED LINE (No CVarArg) ---
                                Text(String(format: "%.5f, %.5f", item.latitude as CVarArg, item.longitude as CVarArg))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(timeFormatter.string(from: item.date))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }

                        // --- REVISED MAP SECTION ---
                        if #available(iOS 17.0, *) {
                            Map(initialPosition: .region(item.region)) {
                                Marker("", coordinate: item.coordinate)
                                    .tint(.cyan)
                            }
                            .mapStyle(.standard) // Use mapStyle instead of mapControls
                            .allowsHitTesting(false)
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        } else {
                            // --- Fallback for older iOS versions ---
                            Map(coordinateRegion: .constant(item.region), annotationItems: [item]) { place in
                                MapMarker(coordinate: place.coordinate, tint: .cyan)
                            }
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .disabled(true)
                        }
                    }
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.vertical, 4)
        }
    }
    // ▲▲▲▲▲ END MODIFIED SECTION ▲▲▲▲▲
}

struct LocationEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // ▼▼▼ ADD THIS COMPUTED PROPERTY ▼▼▼
    var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: self.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    init(id: UUID = UUID(), location: CLLocation) {
        self.id = id

        self.date = Date()
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
    }
}

class SignificantLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let clManager = CLLocationManager()
    var appLocationManager: LocationManager? // reference to app's tracker

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
        clManager.delegate = self // Set delegate
        clManager.requestAlwaysAuthorization()
    }

    func startMonitoring() {
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            clManager.startMonitoringSignificantLocationChanges()
            print("SLC: Monitoring started.")
        } else {
            print("Significant location monitoring is not available on this device.")
            authorizationStatusMessage = "Significant location monitoring not available"
        }
    }

    func clearHistory() {
        locationHistory.removeAll()
    }

    private func saveHistory() {
        if let encodedData = try? JSONEncoder().encode(locationHistory) {
            UserDefaults.standard.set(encodedData, forKey: historySaveKey)
            print("Location history saved! (\(locationHistory.count) entries)")
        }
    }

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

            self.locationHistory.insert(LocationEntry(location: location), at: 0)
            print("Significant location change detected: \(location.coordinate)")
            self.appLocationManager?.startLocationTracking() // trigger app tracking
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        authorizationStatusMessage = "Location error: \(error.localizedDescription)"
        print("Location manager error: \(error.localizedDescription)")
    }
}
