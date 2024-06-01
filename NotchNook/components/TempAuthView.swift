////
////  TempAuthView.swift
////  NotchNook
////
////  Created by Ethan Bills on 5/23/24.
////
//
//import SwiftUI
//import Defaults
//import IOKit.ps
//
//enum KeyType: String, CaseIterable, Identifiable {
//    case license = "Lifetime License"
//    case subscription = "Subscription Key"
//    
//    var id: String { self.rawValue }
//}
//
//struct TempAuthView: View {
//    @Default(.email) private var email
//    @Default(.licenseKey) private var licenseKey
//    @Default(.keyActive) private var keyActive
//    @State private var statusMessage = ""
//    @State private var selectedKeyType: KeyType = .license
//
//    var body: some View {
//        VStack(spacing: 20) {
//            TextField("Email", text: $email)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//
//            TextField(selectedKeyType == .license ? "License Key" : "Subscription Key", text: $licenseKey)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//
//            Picker("Key Type", selection: $selectedKeyType) {
//                ForEach(KeyType.allCases) { keyType in
//                    Text(keyType.rawValue).tag(keyType)
//                }
//            }
//            .pickerStyle(SegmentedPickerStyle())
//            .padding()
//
//            Button(action: validateLicense) {
//                Text("Validate Key")
//                    .padding()
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//            }
//            
//            Text(statusMessage)
//                .foregroundColor(.red)
//                .padding()
//        }
//        .padding()
//    }
//
//    func validateLicense() {
//        guard !email.isEmpty, !licenseKey.isEmpty else {
//            statusMessage = "Email and key cannot be empty."
//            return
//        }
//        
//        let url = URL(string: "https://lo.cafe/api/notchnook-verify-key")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        guard let deviceIdentifier = getDeviceSerialNumber() else {
//            self.statusMessage = "Can't get device identifier."
//            return
//        }
//
//        var payload: [String: Any] = ["email": email, "deviceId": deviceIdentifier]
//        if selectedKeyType == .license {
//            payload["licenseKey"] = licenseKey
//        } else {
//            payload["subKey"] = licenseKey
//        }
//
//        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
//        
//        print(payload)
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                DispatchQueue.main.async {
//                    self.statusMessage = "Network error: \(error?.localizedDescription ?? "Unknown error")"
//                }
//                return
//            }
//
//            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//               let isValid = jsonResponse["valid"] as? Bool {
//                DispatchQueue.main.async {
//                    self.keyActive = isValid
//                    self.statusMessage = isValid ? "Key is valid!" : "Key is invalid."
//                }
//            } else {
//                DispatchQueue.main.async {
//                    self.statusMessage = "Invalid response from server."
//                }
//            }
//        }
//        
//        task.resume()
//    }
//}
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        TempAuthView()
//    }
//}
