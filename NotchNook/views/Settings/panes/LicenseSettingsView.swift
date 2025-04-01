//
//  LicenseSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/05/24.
//

import Settings
import SwiftUI
import AppKit
import Defaults

struct LicenseSettingsView: View {
    @State private var email = ""
    @State private var key = ""
    @State private var loading = false
    @State private var error: LicenseManager.CheckLicenseResult? = nil
    @State private var errorStr: String?
    @State private var successMessage: String?
    @State private var isEmailValid = true
    @Default(.license) private var license
    @Default(.trialInitialTime) private var trialInitialTime
    @Environment(\.openURL) private var openURL
    @Environment(\.trialOver) private var trialOver
    
    var body: some View {
        Form {
            Section("Status") {
                HStack {
                    Image(systemName: isLicenseValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .foregroundStyle(isLicenseValid ? .blue : .red)
                        .font(.system(size: 24))
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Status").font(.title2)
                        Text(isLicenseValid ? "Registered" : "Unregistered")
                            .fontWeight(.semibold)
                            .foregroundStyle(isLicenseValid ? .blue : .red)
                    }
                }
            }
            
#if !SETAPP_BUILD
            if license == nil, let trialInitialTime, !isTrialOver() {
                Section("Trial") {
                    if trialOver {
                        LabeledContent("Time Remaining", value: "EXPIRED")
                    } else {
                        TimeCounter(initialDate: trialInitialTime, maxTimeInHours: LicenseManager.trialDurationInHours)
                    }
                }
            }
#endif
            
            Section("License") {
#if SETAPP_BUILD
                HStack {
                    Image(.setappLogo)
                        .resizable()
                        .frame(80)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Authenticated with Setapp!")
                            .font(.system(size: 15 , weight: .semibold))
                        Text("Enjoy NotchNook ❤️")
                            .font(.system(size: 12))
                            .opacity(0.5)
                    }
                }
                .background(alignment: .leading) {
                    Image(.dashedSetappLine)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 291, height: 68)
                        .padding(.leading, 80)
                        .opacity(0.125)
                }
#else
                
                VStack(spacing: 8) {
                    HStack {
                        Label("Email", systemImage: "at")
                        
                        if !isEmailValid && !email.isEmpty {
                            Text("Please enter a valid email")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        FixedWidthTextField(text: $email, placeholder: "john.doe@email.com", isSecure: false)
                            .onChange(of: email) { _, _ in
                                withAnimation(.snappy) { isEmailValid = validateEmail(email) }
                            }
                            .disabled(isLicenseValid)
                            .frame(width: 250, height: 24)
                    }
                    
                    HStack {
                        Label("License Key", systemImage: "key.horizontal.fill")
                        
                        Spacer()
                        
                        FixedWidthTextField(text: $key, placeholder: "Ex: gjp1lh5dtzqp4yddn73uush9r4inv0", isSecure: isLicenseValid)
                            .frame(width: 250, height: 24)
                            .disabled(isLicenseValid)
                    }
                    
                    
                    HStack {
                        VStack(alignment: .leading) {
                            if let errorStr {
                                Text(errorStr)
                                    .foregroundColor(.red)
                            }
                            
                            if let successMessage {
                                Text(successMessage)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                        
                        if loading { ProgressView().controlSize(.small).padding(.horizontal, 4) }
                        
                        if !isLicenseValid, let url = URL(string: "https://lo.cafe/notchnook") {
                            Button("Get a License") {
                                openURL(url)
                            }
                        }
                        
                        Button(isLicenseValid ? "Unregister" : "Register") {
                            if isLicenseValid {
                                license = nil
                                successMessage = "License unregistered successfully"
                                return
                            }
                            
                            registerLicense()
                        }
                        .disabled(loading || !isEmailValid || email.isEmpty || key.isEmpty)
                        .buttonStyle(BorderedProminentButtonStyle())
                        
                        if isLicenseValid {
                            Button("Manage Billing") {
                                if let url = URL(string: "https://pay.lo.cafe/p/login/aEU8xOfsWfSo3nO144?prefilled_email=\(email)") {
                                    openURL(url)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
#endif
            }
        }
        .formStyle(.grouped)
        .defaultSettingsProps()
        .onAppear {
#if !SETAPP_BUILD
            if let license {
                email = license.email
                key = license.key
            }
#endif
        }
    }
    
    private var isLicenseValid: Bool {
#if SETAPP_BUILD
        return true
#else
        return license != nil
#endif
    }
    
#if !SETAPP_BUILD
    private func registerLicense() {
        guard validateEmail(email) else {
            errorStr = "Invalid email format"
            return
        }
        guard !key.isEmpty else {
            errorStr = "License key cannot be empty"
            return
        }
        
        loading = true
        error = nil
        successMessage = nil
        
        let newLicense = License(email: email, key: key)
        Task {
            let result = await LicenseManager.shared.checkLicense(newLicense)
            DispatchQueue.main.async {
                loading = false
                switch result {
                case .valid:
                    license = newLicense
                    successMessage = "License registered successfully"
                case .invalid:
                    errorStr = "Invalid license key"
                case .networkError:
                    errorStr = "Network error. Please try again later"
                case .noDeviceID:
                    errorStr = "Unable to retrieve device ID"
                }
                
                if result == .valid {
                    errorStr = nil
                } else {
                    successMessage = nil
                }
            }
        }
    }
    
    private func validateEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
#endif
}

let LicenseSettingsViewController: () -> SettingsPane = {
    let paneView = Settings.Pane(
        identifier: .license,
        title: String(localized: "License"),
        toolbarIcon: NSImage(systemSymbolName: "key.horizontal.fill", accessibilityDescription: "License settings")!
    ) {
        LicenseSettingsView()
    }
    
    return Settings.PaneHostingController(pane: paneView)
}
