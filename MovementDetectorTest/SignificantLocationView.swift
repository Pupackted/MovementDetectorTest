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

#Preview {
    SignificantLocationView(slm: SignificantLocationManager())
}
