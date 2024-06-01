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
            
            Section("License") {
                Group {
                    TextField(text: $email, prompt: Text("john.doe@email.com"), label: {
                        Label("Email", systemImage: "at")
                    })
                    SecureField(text: $key, prompt: Text("gjp1lh5dtzqp4yddn73uush9r4inv0"), label: {
                        Label("Key", systemImage: "key.horizontal.fill")
                    })
                    Picker("License Type", selection: $keyType) {
                        ForEach(License.KeyType.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.radioGroup)
                }
                .disabled(license != nil)
                
                Button(license == nil ? "Register" : "Unregister") {
                    if license != nil { license = nil; return }
                    loading = true
                    let newLicense = License(email: email, key: key, type: keyType)
                    Task {
                        if let result = await LicenseManager.shared.checkLicense(newLicense), result != .valid {
                            error = result
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
