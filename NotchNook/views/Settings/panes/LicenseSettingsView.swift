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
    @State private var keyType: License.KeyType = .subscription
    @State private var loading = false
    @State private var error: LicenseManager.CheckLicenseResult? = nil
    @Default(.license) private var license
    @Default(.trialInitialTime) private var trialInitialTime
    @Environment(\.openURL) private var openURL
    @Environment(\.trialOver) private var trialOver
    var body: some View {
        Form {
            
            Section("Status") {
                HStack {
                    Image(systemName: license == nil ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .foregroundStyle(license == nil ? .red : .blue)
                        .font(.system(size: 24))
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Status").font(.title2)
                        Text(license == nil ? "Unregistered" : "Registered")
                            .fontWeight(.semibold)
                            .foregroundStyle(license == nil ? .red : .blue)
                    }
                }
            }
            
            if license == nil, let trialInitialTime, !isTrialOver() {
                Section("Trial") {
                    if trialOver {
                        LabeledContent("Time Remaining", value: "EXPIRED")
                    } else {
                        TimeCounter(initialDate: trialInitialTime, maxTimeInHours: LicenseManager.trialDurationInHours)
                    }
                }
            }
            
            Section("License") {
                Group {
                    TextField(text: $email, prompt: Text("john.doe@email.com"), label: {
                        Label("Email", systemImage: "at")
                    })
                    if license != nil {
                        SecureField(text: $key, label: {
                            Label("Key", systemImage: "key.horizontal.fill")
                        })
                    } else {
                        TextField(text: $key, prompt: Text("gjp1lh5dtzqp4yddn73uush9r4inv0"), label: {
                            Label("Key", systemImage: "key.horizontal.fill")
                        })
                    }
                    Picker("License Type", selection: $keyType) {
                        ForEach(License.KeyType.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.radioGroup)
                }
                .disabled(license != nil)
                
                HStack {
                    if loading { ProgressView().controlSize(.small).padding(.horizontal, 4) }
                    
                    Button(license == nil ? "Register" : "Unregister") {
                        if license != nil { license = nil; return }
                        if !validateEmail(email) || key.isEmpty { return }
                        loading = true
                        let newLicense = License(email: email, key: key, type: keyType)
                        Task {
                            if let result = await LicenseManager.shared.checkLicense(newLicense), result != .valid {
                                error = result
                            }
                            loading = false
                        }
                    }
                    .disabled(loading)
                    
                    if license != nil && keyType == .subscription {
                        Button(license == nil ? "Register" : "Manage Billing") {
                            if let url = URL(string: "https://pay.lo.cafe/p/login/aEU8xOfsWfSo3nO144?prefilled_email=\(email)") {
                                openURL(url)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .formStyle(.grouped)
        .defaultSettingsProps()
        .onAppear {
            if let license {
                email = license.email
                key = license.key
                keyType = license.type
            }
        }
    }
}
