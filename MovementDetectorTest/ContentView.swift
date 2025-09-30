//
//  ContentView.swift
//  MovementDetectorTest
//
//  Created by Adrian Yusufa Rachman on 30/09/25.
//

import SwiftUI
import Combine
import CoreMotion

enum ActivityState: String, Codable {
    case stationary, walking, running, cycling, automotive, unknown

    var displayName: String {
        switch self {
        case .stationary: return "Stationary"
        case .walking: return "Walking"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .automotive: return "In Vehicle"
        case .unknown: return "Unknown"
        }
    }

    var iconName: String {
        switch self {
        case .stationary: return "pause.circle.fill"
        case .walking: return "figure.walk.circle.fill"
        case .running: return "figure.run.circle.fill"
        case .cycling: return "bicycle.circle.fill"
        case .automotive: return "car.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .stationary: return .gray
        case .walking: return .green
        case .running: return .orange
        case .cycling: return .teal
        case .automotive: return .blue
        case .unknown: return .purple
        }
    }

    var isMoving: Bool {
        switch self {
        case .walking, .running, .cycling, .automotive:
            return true
        default:
            return false
        }
    }
}

struct ActivityEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let state: ActivityState

    init(id: UUID = UUID(), date: Date = Date(), state: ActivityState) {
        self.id = id
        self.date = date
        self.state = state
    }
}

final class MovementHistoryViewModel: ObservableObject {
    @Published private(set) var currentState: ActivityState = .unknown
    @Published private(set) var history: [ActivityEntry] = [] {
        // *** NEW: This will run every time the history array is changed. ***
        didSet {
            saveHistory()
        }
    }
    @Published var availabilityMessage: String?

    private let manager = CMMotionActivityManager()
    private var lastLoggedState: ActivityState?
    
    // *** NEW: A key to identify our saved data in UserDefaults. ***
    private let historySaveKey = "MovementHistory"

    // *** NEW: The initializer now loads the history when the app starts. ***
    init() {
        loadHistory()
    }
    
    func start() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            availabilityMessage = "Motion activity is not available on this device."
            return
        }
        availabilityMessage = nil

        manager.startActivityUpdates(to: OperationQueue.main) { [weak self] activity in
            guard let self, let activity else { return }
            let newState = Self.map(activity)
            self.currentState = newState

            // Log only when state changes to keep history meaningful.
            if self.lastLoggedState != newState {
                self.lastLoggedState = newState
                self.history.insert(ActivityEntry(state: newState), at: 0)
                // keep history manageable
                if self.history.count > 50 {
                    self.history.removeLast(self.history.count - 50)
                }
            }
        }
    }

    func stop() {
        manager.stopActivityUpdates()
    }

    func clearHistory() {
        history.removeAll()
        // No need to call saveHistory() here, because the `didSet` observer above will do it for us.
    }
    
    // *** NEW: Function to save the history array to UserDefaults. ***
    private func saveHistory() {
        // We use JSONEncoder to convert our array of ActivityEntry objects into Data that can be stored.
        if let encodedData = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encodedData, forKey: historySaveKey)
            print("History saved! (\(history.count) entries)")
        }
    }
    
    // *** NEW: Function to load the history from UserDefaults. ***
    private func loadHistory() {
        // We check if there's any data saved under our key.
        if let savedData = UserDefaults.standard.data(forKey: historySaveKey) {
            // We use JSONDecoder to convert the saved Data back into an array of ActivityEntry objects.
            if let decodedHistory = try? JSONDecoder().decode([ActivityEntry].self, from: savedData) {
                self.history = decodedHistory
                print("History loaded! (\(history.count) entries)")
                return
            }
        }
        // If nothing is loaded, we start with an empty array.
        self.history = []
    }

    private static func map(_ activity: CMMotionActivity) -> ActivityState {
        if activity.running { return .running }
        if activity.walking { return .walking }
        if activity.cycling { return .cycling }
        if activity.automotive { return .automotive }
        if activity.stationary { return .stationary }
        return .unknown
    }
}

struct ContentView: View {
    @StateObject private var vm = MovementHistoryViewModel()

    private let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short
        return df
    }()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Movement Activity")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 8)

                currentStatusCard

                historySection
            }
            .padding()
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }

    private var currentStatusCard: some View {
        VStack(spacing: 12) {
            if let message = vm.availabilityMessage {
                Text(message)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: vm.currentState.iconName)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(vm.currentState.color)
                    .symbolEffect(.pulse, options: .repeating, value: vm.currentState.isMoving)

                Text(vm.currentState.displayName)
                    .font(.title.bold())
                    .foregroundStyle(.primary)

                Text(vm.currentState.isMoving ? "Moving" : "Not Moving")
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(vm.currentState.isMoving ? vm.currentState.color.opacity(0.2) : Color.gray.opacity(0.2))
                    .foregroundStyle(vm.currentState.isMoving ? vm.currentState.color : .secondary)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("History")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                if !vm.history.isEmpty {
                    Button("Clear") { vm.clearHistory() }
                        .font(.subheadline.weight(.semibold))
                        .tint(.white)
                }
            }

            if vm.history.isEmpty {
                Text("No activity changes yet.")
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.vertical, 12)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(vm.history) { entry in
                            HStack(spacing: 12) {
                                Image(systemName: entry.state.iconName)
                                    .foregroundStyle(entry.state.color)
                                    .frame(width: 28, height: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.state.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(timeFormatter.string(from: entry.date))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(entry.state.isMoving ? "Moving" : "Idle")
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(entry.state.color.opacity(0.15))
                                    .foregroundStyle(entry.state.color)
                                    .clipShape(Capsule())
                            }
                            .padding(12)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 280)
            }
        }
    }
}

#Preview {
    ContentView()
}
