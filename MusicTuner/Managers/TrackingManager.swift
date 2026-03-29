//
//  TrackingManager.swift
//  MusicTuner
//
//  App Tracking Transparency (ATT) permission manager
//

import AppTrackingTransparency
import Foundation

/// Manages App Tracking Transparency permission requests
@MainActor
final class TrackingManager {
    
    static let shared = TrackingManager()
    
    private init() {}
    
    /// Request ATT permission. Returns the authorization status.
    /// Must be called AFTER the app's first view has appeared.
    func requestTrackingPermission() async -> ATTrackingManager.AuthorizationStatus {
        // If already determined, return current status
        let currentStatus = ATTrackingManager.trackingAuthorizationStatus
        if currentStatus != .notDetermined {
            return currentStatus
        }
        
        // Request permission
        let status = await ATTrackingManager.requestTrackingAuthorization()
        
        switch status {
        case .authorized:
            print("✅ Tracking authorized")
        case .denied:
            print("⚠️ Tracking denied — showing non-personalized ads")
        case .restricted:
            print("⚠️ Tracking restricted")
        case .notDetermined:
            print("⚠️ Tracking not determined")
        @unknown default:
            print("⚠️ Tracking unknown status")
        }
        
        return status
    }
    
    /// Check if tracking is authorized
    var isTrackingAuthorized: Bool {
        ATTrackingManager.trackingAuthorizationStatus == .authorized
    }
}
