//
//  ViewController.swift
//  MovementDetectorTest
//
//  Created by Adrian Yusufa Rachman on 30/09/25.
//

import Foundation
import UIKit
import CoreMotion

class ViewController: UIViewController {

    // 1. Create an instance of CMMotionActivityManager.
    // This object is the central point for accessing motion activity data.
    private let activityManager = CMMotionActivityManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // A simple label to show status on the screen
        let statusLabel = UILabel(frame: view.bounds)
        statusLabel.text = "Checking for movement..."
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        view.addSubview(statusLabel)
        
        startMovementDetection()
    }

    func startMovementDetection() {
        // 2. Check if motion activity is available on the device.
        // Not all devices have the necessary hardware.
        if CMMotionActivityManager.isActivityAvailable() {
            
            // 3. Start receiving activity updates.
            // We provide an operation queue for the updates to be delivered on,
            // and a handler block to process the activity data.
            self.activityManager.startActivityUpdates(to: OperationQueue.main) { (activity) in
                // The 'activity' parameter is an optional CMMotionActivity object.
                if let activity = activity {
                    
                    // 4. Check the activity type.
                    // The CMMotionActivity object has boolean properties for different
                    // types of motion (walking, running, cycling, automotive, stationary).
                    if activity.walking || activity.running {
                        // This is the action you wanted to trigger.
                        // When debugging with your phone connected to Xcode,
                        // you will see this message in the console.
                        print("User is walking or running.")
                        
                        // You can also update the UI if the app is in the foreground.
                        if let label = self.view.subviews.first as? UILabel {
                            label.text = "Hello World!\nUser is walking or running."
                        }
                        
                    } else if activity.stationary {
                        print("User is stationary.")
                        if let label = self.view.subviews.first as? UILabel {
                            label.text = "User is stationary."
                        }
                    } else if activity.automotive {
                        print("User is in a vehicle.")
                         if let label = self.view.subviews.first as? UILabel {
                            label.text = "User is in a vehicle."
                        }
                    } else {
                        print("User is doing something else or activity is unknown.")
                        if let label = self.view.subviews.first as? UILabel {
                            label.text = "Detecting..."
                        }
                    }
                }
            }
        } else {
            print("Motion activity is not available on this device.")
            if let label = self.view.subviews.first as? UILabel {
                label.text = "Motion activity is not available on this device."
            }
        }
    }
}
