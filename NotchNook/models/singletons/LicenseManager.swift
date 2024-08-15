//
//  LicenseManager.swift
//  NotchNook
//
//  Created by Igor Marcossi on 31/05/24.
//

import SwiftUI
import Defaults
import JWTKit

#if !SETAPP_BUILD
@Observable
class LicenseManager {
    static let shared = LicenseManager()
    static let trialDurationInHours: Double = 48
    static let networkErrorLimit = 20
    private var timer: Timer?
    
    var activeTasks = [Task<Void, Never>]()
    
    init() {
        Task { await checkLicense() }
        scheduleCheck()
    }
    
    deinit {
        unscheduleCheck()
    }
    
    func scheduleCheck() {
        timer = Timer.scheduledTimer(withTimeInterval: 60*60*4, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.checkLicense()
            }
        }
    }
    
    func unscheduleCheck() {
        timer?.invalidate()
        timer = nil
    }
    
    func checkLicense(_ altLicense: License? = nil) async -> CheckLicenseResult {
        guard let license = Defaults[.license] ?? altLicense else { return .invalid }
        
        let result = await Self.checkLicense(license)
        
        await MainActor.run {
            updateLicenseState(result: result, newLicense: license)
        }
        
        return result
    }
    
    private func updateLicenseState(result: CheckLicenseResult, newLicense: License) {
        switch result {
        case .invalid:
            Defaults[.license] = nil
            Defaults[.networkErrorCounting] = 0
        case .networkError:
            Defaults[.networkErrorCounting] += 1
        case .valid:
            if Defaults[.license] != newLicense { Defaults[.license] = newLicense }
            Defaults[.networkErrorCounting] = 0
        case .noDeviceID:
            break
        }
        
        if Defaults[.networkErrorCounting] > Self.networkErrorLimit {
            Defaults[.license] = nil
        }
    }
    
    static func checkLicense(_ license: License) async -> CheckLicenseResult {
        URLCache.shared.removeAllCachedResponses()
        
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
}

#else
@Observable
class LicenseManager {
    static let shared = LicenseManager()
    static let trialDurationInHours: Double = 48
    
    func checkLicense() -> CheckLicenseResult {
        Defaults[.license] = License(email: "", key: "", type: .license)
        
        // Always return valid
        return .valid
    }
}
#endif

extension LicenseManager {
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
