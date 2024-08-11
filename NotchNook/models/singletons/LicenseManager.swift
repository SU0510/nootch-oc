//
//  LicenseManager.swift
//  NotchNook
//
//  Created by Igor Marcossi on 31/05/24.
//

import SwiftUI
import Defaults
import JWTKit

@Observable
class LicenseManager {
    static let shared = LicenseManager()
    static let trialDurationInHours: Double = 48
    static let networkErrorLimit = 20
    private var timer: Timer?
    
    var license: License? {
        get { Defaults[.license] }
        set { Defaults[.license] = newValue }
    }
    var networkErrorCounting: Int {
        get { Defaults[.networkErrorCounting] }
        set { Defaults[.networkErrorCounting] = newValue }
    }
    
    var activeTasks = [Task<Void, Never>]()
    
    init() {
        Task { await checkLicense() }
        scheduleCheck()
    }
    
    deinit {
        unscheduleCheck()
    }
    
    func scheduleCheck() {
        timer = Timer.scheduledTimer(timeInterval: 60*60*4, target: self, selector: #selector(asyncCheckLicense), userInfo: nil, repeats: true)
    }
    
    func unscheduleCheck() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func asyncCheckLicense() {
        Task {
            await checkLicense()
        }
    }
    
    func checkLicense(_ altLicense: License? = nil) async -> CheckLicenseResult? {
        guard let newLicense = self.license ?? altLicense else { return nil }
        let result = await Self.checkLicense(newLicense)
        switch result {
            case .invalid:
                self.license = nil
                self.networkErrorCounting = 0
            case .networkError: self.networkErrorCounting += 1
            case .valid:
                if self.license != newLicense { self.license = newLicense }
                self.networkErrorCounting = 0
            case .noDeviceID: break
        }
        if self.networkErrorCounting > Self.networkErrorLimit { self.license = nil }
        return result
    }
    
    static func checkLicense(_ license: License) async -> CheckLicenseResult {
        let url = URL(string: "https://lo.cafe/api/notchnook-verify-key-v2")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let deviceIdentifier = getDeviceSerialNumber() else {
            return .noDeviceID
        }
        
        var payload: [String: Any] = ["email": license.email, "deviceId": deviceIdentifier]
        
        if license.type == .license {
            payload["licenseKey"] = license.key
        } else {
            payload["subKey"] = license.key
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
        
        do {
            // Fetch data and check for token
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let tokenString = jsonResponse["token"] as? String else {
                return .networkError
            }
            
            // Create the JWTVerifier using the provided function
            let keys = JWTKeyCollection()
            
            do {
                let key = try Insecure.RSA.PublicKey(pem: pubKey)
                await keys.add(rsa: key, digestAlgorithm: .sha256)
                let payload = try await keys.verify(tokenString, as: NNJWTPayload.self)
                
                if payload.valid {
                    return .valid
                } else {
                    print("License check failed: \(payload.error ?? "Unknown error")")
                    return .invalid
                }
            } catch {
                print("JWT verification error: \(error)")
                return .invalid
            }
        } catch {
            return .networkError
        }
    }
    
    
    enum CheckLicenseResult {
        case invalid, noDeviceID, networkError, valid
    }
}

struct License: Equatable, Codable, Hashable, Defaults.Serializable {
    var email: String
    var key: String
    var type: KeyType
    
    enum KeyType: String, Equatable, Hashable, Codable, CaseIterable, Identifiable {
        case license = "Lifetime License"
        case subscription = "Subscription Key"
        var id: String { self.rawValue }
    }
}

struct NNJWTPayload: JWTPayload {
    func verify(using algorithm: some JWTKit.JWTAlgorithm) async throws {}
    
    let valid: Bool
    let message: String?
    let error: String?
    let iat: IssuedAtClaim
}
