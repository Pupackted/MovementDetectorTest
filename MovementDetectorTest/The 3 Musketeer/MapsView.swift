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

// MARK: - Data Models

// A Codable wrapper for CLLocationCoordinate2D that is also Hashable for caching
struct CodableCoordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}

// Represents a single saved trip with optional start/end location names
struct Trip: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let locations: [CodableCoordinate]
    var startLocationName: String?
    var endLocationName: String?
    
    init(id: UUID = UUID(), date: Date = Date(), locations: [CLLocationCoordinate2D]) {
        self.id = id
        self.date = date
        self.locations = locations.map { CodableCoordinate(coordinate: $0) }
    }
}

// MARK: - Geocoding Service

// Service to handle reverse geocoding and cache results to avoid repeated network calls
class GeocoderService {
    private let geocoder = CLGeocoder()
    private var cache: [CodableCoordinate: String] = [:]
    
    func placemark(for coordinate: CodableCoordinate) async -> String {
        if let cached = cache[coordinate] {
            return cached
        }
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            // Use a descriptive name if available, otherwise fallback
            let name = placemarks.first?.name ?? placemarks.first?.locality ?? "Unknown Location"
            cache[coordinate] = name
            return name
        } catch {
            // Handle cases where the network fails or no location is found
            return "Location not found"
        }
    }
}

// MARK: - Views

struct MapsView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @State private var showHistory = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        ZStack {
            // The Main Interactive Map
            Map(position: $cameraPosition) {
                
                if !locationManager.trackedLocations.isEmpty {
                    // The route line remains the same
                    MapPolyline(coordinates: locationManager.trackedLocations)
                        .stroke(.blue, lineWidth: 5)
                    
                    // Iterate through all tracked locations to place a point for each one
                    ForEach(Array(locationManager.trackedLocations.enumerated()), id: \.offset) { index, coordinate in
                        
                        // Use a special marker for the START point
                        if index == 0 {
                            Marker("Start", systemImage: "flag.fill", coordinate: coordinate)
                                .tint(.green)
                            
                            // Use a special marker for the END point (only if it's not also the start point)
                        } else if index == locationManager.trackedLocations.count - 1 {
                            Marker("End", systemImage: "flag.checkered", coordinate: coordinate)
                                .tint(.red)
                            
                            // For all intermediate "ping" points, use a small circle
                        } else {
                            Annotation("", coordinate: coordinate, anchor: .center) {
                                ZStack { // Used to layer the number on top of the circle
                                    Circle()
                                        .fill(Color.blue)
                                    
                                    Text("\(index)") // Displays the number
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 22, height: 22) // Made the frame larger
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: 2)
                                )
                            }
                        }
                    }
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea(edges: .bottom)
            .onChange(of: locationManager.trackedLocations) { _ in
                // When trackedLocations change, animate the camera to fit them
                if let region = locationManager.regionForTrackedLocations() {
                    withAnimation(.easeOut) {
                        cameraPosition = .region(region)
                    }
                }
            }
            
            // UI Overlay
            VStack {
                Spacer()
                
                // Show History Sheet with a smooth transition
                if showHistory {
                    historySheet
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                bottomControls
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showHistory)
    }
    
    // MARK: Subviews
    
    private var bottomControls: some View {
        HStack {
            
            Button {
                showHistory.toggle()
            } label: {
                Image(systemName: "list.bullet")
                    .font(.title2)
                    .padding()
                    .background(.thinMaterial)
                    .foregroundColor(.primary)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            
            Spacer()
            
      
            Button(action: locationManager.toggleTracking) {
                Text(locationManager.isTracking ? "Stop Tracking" : "Start Tracking")
                    .font(.headline.bold())
                    .padding()
                    .frame(minWidth: 160)
                    .background(locationManager.isTracking ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
            }
        }
        .padding()
    }
    
    private var historySheet: some View {
        VStack(spacing: 0) {
            // Header for the history sheet
            HStack {
                Text("Tracking History")
                    .font(.title2.bold())
                Spacer()
                if !locationManager.tripHistory.isEmpty {
                    Button("Clear", role: .destructive, action: locationManager.clearHistory)
                }
            }
            .padding()
            
            // Show a helpful message if history is empty
            if locationManager.tripHistory.isEmpty {
                ContentUnavailableView("No Saved Trips", systemImage: "map.fill", description: Text("Press 'Start Tracking' to record your first trip."))
            } else {
                // List of saved trips
                List {
                    ForEach($locationManager.tripHistory) { $trip in
                        Button(action: {
                            locationManager.displayTrip(trip)
                            showHistory = false // Close the sheet after selection
                        }) {
                            TripRowView(trip: $trip)
                        }
                        
                    }
                    
                }
                .listStyle(.sidebar)
                .background(.thinMaterial)
                
                
            }
        }
        .frame(height: 400)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25.0, style: .continuous))
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.2), radius: 10)
    }
}

// A dedicated view for a single, styled row in the history list
struct TripRowView: View {
    @Binding var trip: Trip
    
    var body: some View {
        HStack(spacing: 15) {
            // The small map preview
            TripPreviewMapView(trip: trip)
                .frame(width: 100, height: 75)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                )
            
            // Details of the trip: Date, Start, and End locations
            VStack(alignment: .leading, spacing: 5) {
                Text(trip.date, style: .date)
                    .fontWeight(.semibold)
                
                HStack {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundColor(.green)
                    Text(trip.startLocationName ?? "Loading...")
                }
                
                HStack {
                    Image(systemName: "arrow.down.right.circle.fill")
                        .foregroundColor(.red)
                    Text(trip.endLocationName ?? "Loading...")
                }
            }
            .font(.subheadline)
            .lineLimit(1) // Prevents long location names from wrapping
        }
        .padding(.vertical, 8)
    }
}

// A small, non-interactive map view for the history list preview
struct TripPreviewMapView: View {
    let trip: Trip
    
    private var region: MKCoordinateRegion {
        // Calculates the region that fits all points of the trip
        guard !trip.locations.isEmpty else {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: .defaultSpan)
        }
        
        var minLat = trip.locations.first!.latitude, maxLat = minLat
        var minLon = trip.locations.first!.longitude, maxLon = minLon
        
        trip.locations.forEach {
            minLat = min(minLat, $0.latitude); maxLat = max(maxLat, $0.latitude)
            minLon = min(minLon, $0.longitude); maxLon = max(maxLon, $0.longitude)
        }
        
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.5, longitudeDelta: (maxLon - minLon) * 1.5)
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    var body: some View {
        Map(initialPosition: .region(region)) {
            MapPolyline(coordinates: trip.locations.map { $0.coordinate })
                .stroke(.blue, lineWidth: 2)
        }
        .allowsHitTesting(false) // This makes the small map non-interactive
    }
}

// MARK: - ViewModel

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    private let historySaveKey = "MapTrackingHistory"
    private let geocoderService = GeocoderService()
    
    @Published var isTracking = false
    @Published var trackedLocations: [CLLocationCoordinate2D] = []
    @Published var tripHistory: [Trip] = [] { didSet { saveHistory() } }
    private var manualTrackingOverride = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 30 // meters
        loadHistory()
    }
    
    func toggleTracking() {
        if self.isTracking {
            manager.stopUpdatingLocation()
            if !trackedLocations.isEmpty {
                var newTrip = Trip(locations: trackedLocations)
                tripHistory.insert(newTrip, at: 0)
                // Asynchronously fetch location names after saving
                Task {
                    await fetchLocationNames(for: &newTrip)
                    // Find the trip in the history and update it with the names
                    if let index = tripHistory.firstIndex(where: { $0.id == newTrip.id }) {
                        tripHistory[index] = newTrip
                    }
                }
            }
            manualTrackingOverride = true
        } else {
            trackedLocations = []
            manager.startUpdatingLocation()
            manualTrackingOverride = false
        }
        isTracking.toggle()
    }
    
    func startLocationTracking() {
        if !isTracking && !manualTrackingOverride {
            trackedLocations = []
            manager.startUpdatingLocation()
            isTracking = true
        }
    }
    
    // Fetches start and end placenames for a trip
    private func fetchLocationNames(for trip: inout Trip) async {
        guard let first = trip.locations.first, let last = trip.locations.last else { return }
        trip.startLocationName = await geocoderService.placemark(for: first)
        trip.endLocationName = await geocoderService.placemark(for: last)
    }
    
    func displayTrip(_ trip: Trip) {
        if isTracking { toggleTracking() }
        self.trackedLocations = trip.locations.map { $0.coordinate }
    }
    
    func regionForTrackedLocations() -> MKCoordinateRegion? {
        guard !trackedLocations.isEmpty else { return nil }
        var minLat = trackedLocations.first!.latitude, maxLat = minLat
        var minLon = trackedLocations.first!.longitude, maxLon = minLon
        trackedLocations.forEach {
            minLat = min(minLat, $0.latitude); maxLat = max(maxLat, $0.latitude)
            minLon = min(minLon, $0.longitude); maxLon = max(maxLon, $0.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.5, longitudeDelta: (maxLon - minLon) * 1.5)
        return MKCoordinateRegion(center: center, span: span)
    }
    
    func clearHistory() {
        tripHistory.removeAll()
        trackedLocations = []
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(tripHistory) {
            UserDefaults.standard.set(data, forKey: historySaveKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historySaveKey),
           let history = try? JSONDecoder().decode([Trip].self, from: data) {
            self.tripHistory = history
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        trackedLocations.append(latest.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Error: \(error.localizedDescription)")
    }
}

// MARK: - Extensions

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension MKCoordinateSpan {
    static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
}


// MARK: - Preview

#Preview {
    MapsView()
        .environmentObject(LocationManager())
}

