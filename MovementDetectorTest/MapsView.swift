//
//  MapsView.swift
//  MovementDetectorTest
//
//  Created by Adrian Yusufa Rachman on 01/10/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapsView: View {
    // MARK: - Properties

    // The array of coordinates you provided.
    @State private var coordinates: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: -8.73712374551025, longitude: 115.17616498211015),
        CLLocationCoordinate2D(latitude: -8.73730299247452, longitude: 115.1760392830837),
        CLLocationCoordinate2D(latitude: -8.737365146098892, longitude: 115.17599440302712),
        CLLocationCoordinate2D(latitude: -8.737217496173534, longitude: 115.17609837346926),
        CLLocationCoordinate2D(latitude: -8.737172622193627, longitude: 115.17613002103975),
        CLLocationCoordinate2D(latitude: -8.73721943508369, longitude: 115.1760889928665),
        CLLocationCoordinate2D(latitude: -8.737410997780424, longitude: 115.17597024723813),
        CLLocationCoordinate2D(latitude: -8.737361080952155, longitude: 115.17595456059782),
        CLLocationCoordinate2D(latitude: -8.73731040300484, longitude: 115.17596969984207),
        CLLocationCoordinate2D(latitude: -8.737359223306193, longitude: 115.17596746988964),
        CLLocationCoordinate2D(latitude: -8.737377013943275, longitude: 115.17591895841964),
        CLLocationCoordinate2D(latitude: -8.737326386068371, longitude: 115.17594087832107),
        CLLocationCoordinate2D(latitude: -8.737279743450731, longitude: 115.17590979197757),
        CLLocationCoordinate2D(latitude: -8.737333308992843, longitude: 115.1759415281409),
        CLLocationCoordinate2D(latitude: -8.737360655115321, longitude: 115.175949611749),
        CLLocationCoordinate2D(latitude: -8.737320923314376, longitude: 115.17596854799254),
        CLLocationCoordinate2D(latitude: -8.737271981400431, longitude: 115.17598608317462),
        CLLocationCoordinate2D(latitude: -8.737248056272367, longitude: 115.17602506557975),
        CLLocationCoordinate2D(latitude: -8.737191911232516, longitude: 115.17607334123217),
        CLLocationCoordinate2D(latitude: -8.737178350589328, longitude: 115.17617308204004),
        CLLocationCoordinate2D(latitude: -8.737159198695833, longitude: 115.17621875313297)
    ]

    // MARK: - Body

    var body: some View {
        Map {
            // This will draw a line connecting all the coordinates.
            MapPolyline(coordinates: coordinates)
                .stroke(.blue, lineWidth: 5)

            // This will place a marker at each coordinate.
            ForEach(coordinates.indices, id: \.self) { index in
                Marker("Point \(index + 1)", coordinate: coordinates[index])
            }
        }
        .mapStyle(.standard)
        .onAppear(perform: setupMap)
    }

    // MARK: - Private Methods

    private func setupMap() {
        // Here you can add any additional map setup if needed.
    }
}

// MARK: - Preview

#Preview {
    MapsView()
}
