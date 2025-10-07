//
//  AppDelegate.swift
//  MovementDetectorTest
//
//  Created by Adrian Yusufa Rachman on 07/10/25.
//

import Foundation

import UIKit
import SwiftUI
import CoreLocation
import SwiftData

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // A static container to ensure the AppDelegate and the main app use the same database
    static var container: ModelContainer?
    
    // A lazy-loaded instance of your existing LocationManager
    lazy var locationManager: LocationManager = {
        let manager = LocationManager()
        return manager
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if launchOptions?[.location] != nil {
            print("App re-launched by a location event.")
            
            // Check if the user had tracking enabled before termination
            if UserDefaults.standard.bool(forKey: "isTrackingEnabled") {
                print("Tracking was enabled. Switching to high-frequency updates.")
                // This is the key step: switch from SLC to standard updates
                locationManager.startLocationTracking()
            }
        }
        return true
    }
}
