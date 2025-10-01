//
//  SignificantLocationView.swift
//  MovementDetectorTest
//
//  Created by Adrian Yusufa Rachman on 01/10/25.
//

import SwiftUI
import CoreLocation

struct SignificantLocationView: View {
    @ObservedObject var slm: SignificantLocationManager

    private let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short
        return df
    }()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.cyan.opacity(0.6), Color.indigo.opacity(0.6)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Significant Locations")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .padding(.top, 8)
                    Spacer()
                    if !slm.recentLocations.isEmpty {
                        Text("Monitoring")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }

                if slm.recentLocations.isEmpty {
                    Text("No significant location changes yet.")
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.vertical, 12)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(slm.recentLocations.enumerated()), id: \.offset) { index, item in
                                HStack(spacing: 12) {
                                    Image(systemName: "location.circle.fill")
                                        .foregroundStyle(.cyan)
                                        .frame(width: 28, height: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(String(format: "%.5f", item.coordinate.latitude)), \(String(format: "%.5f", item.coordinate.longitude))")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text(timeFormatter.string(from: item.timestamp))
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
            .padding()
        }
    }
}

#Preview {
    SignificantLocationView(slm: SignificantLocationManager())
}
