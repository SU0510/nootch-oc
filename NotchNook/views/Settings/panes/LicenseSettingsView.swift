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

private let starsCount = 7

struct License: Equatable, Codable, Defaults.Serializable, Hashable {
        var unregisterKey: String?
        var email: String?
        var key: String?
        var trialMinutesRemaining: Int?
        var firstNoConnectionCheck: Date?
        
        var status: LicenseStatus {
            return .activated
        }
        
        enum LicenseStatus: Codable {
                case activated
                case trial
                case trialExpired
                case fresh
                case noConnection
        }
        
        enum LicenseError: String, Codable {
                case activated
                case trial
                case trialExpired
                case fresh
                case noConnection
        }
}

class LicenseManager {
        var trialTimer: Timer?
        
        private let timeout = TimeInterval(10)
        
        init() {
        }
        
        func scheduleTrialTimer() {
        }
        
        func unregisterKey(completion: @escaping (Int?) -> Void) {
        }
        
        func checkRegisteredKey() {
        }
        
        func registerKey(email: String, key: String, completion: @escaping (Int?) -> Void) {
        }
        
        func updateTrial() {
        }
        
        struct UnregisterKeyRequestPayload: Codable {
                let email: String
                let key: String
                let unregisterKey: String
//                var appID: String = APP_API_ID
        }
        
        struct RegisterAndCheckKeyRequestPayload: Codable {
                let email: String
                let key: String
                let machine: String
//                var appID: String = APP_API_ID
        }
        
        struct RegisterKeyResponse: Codable {
                let unregisterKey: String
        }
        
        struct TrialRequestPayload: Codable {
                let machine: String
//                var appID: String = APP_API_ID
        }
        
        struct TrialResponse: Codable {
                let minutesRemaining: Int
        }
}


let bagesLabels: [License.LicenseStatus: String] = [
  .trialExpired: "EXPIRED",
  .trial: "TRIAL",
  .activated: "LICENSED",
  .noConnection: "OFF",
  .fresh: "FRESH",
]

let bagesColors: [License.LicenseStatus: Color] = [
  .trialExpired: .red,
  .trial: Color("simpleGray"),
  .activated: .green,
  .noConnection: .red,
  .fresh: Color("opaqueBlue"),
]

let bagesIcons: [License.LicenseStatus: String] = [
  .trialExpired: "clock.badge.xmark.fill",
  .trial: "clock.fill",
  .activated: "checkmark.seal.fill",
  .noConnection: "wifi.slash",
  .fresh: "leaf.fill",
]

struct LicenseBadge: View {
  
  var badge: License.LicenseStatus = .trial
  @State var kidBadge = false
  @State var kidTwisted = false
  @State var twisted = false
//  @Default(.license) var license
  @Environment (\.colorScheme) var colorScheme: ColorScheme

//  trialMinutesRemaining
  var body: some View {
    ZStack(alignment: .bottom) {
      VStack(spacing: 0) {
        Text("You're currently\(badge == .trial ? " on" : "")")
          .frame(maxWidth: .infinity)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(.secondary.opacity(0.25))
          .font(.system(size: 16, weight: .medium))
        
        HStack(spacing: 6) {
          Image(systemName: bagesIcons[badge]!)
          
          Text(bagesLabels[badge]!)
        }
        .font(.system(size: 32, weight: .bold))
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .padding(.top, 8)
        .frame(maxWidth: .infinity)
      }
      .fixedSize()
      .foregroundColor(badge == .trial || badge == .fresh ? .primary : .white)
      .mask(RR(16, .black))
      .background(
        RR(16, bagesColors[badge]!)
      )
      .overlay  (
        VStack {
          RoundedRectangle(cornerRadius: 15, style: .continuous)
            .stroke(Color.primary.opacity(0.15), lineWidth: 2)
            .blendMode(.softLight)
        }
          .padding(.all, 1)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous).fill(RadialGradient(gradient: Gradient(colors: [.black.opacity(0), .black]), center: .topTrailing, startRadius: 0, endRadius: 275))
          .frame(maxWidth: .infinity, alignment: .leading)
          .opacity(colorScheme == .dark ? 0.35 : 0.2)
          .blendMode(.darken)
      )
      .onChange(of: badge) { newValue in
        kidBadge = false
        kidTwisted = false
        twisted = false
        if newValue == .trial {
          doThisAfter(0.3) {
            withAnimation(HANG_ANIM) {
              kidBadge = true
            }
            doThisAfter(0.09) {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.25)) {
                twisted = true
              }
            }
            doThisAfter(0.1) {
              withAnimation(ROT_ANIM) {
                kidTwisted = true
              }
            }
          }
        }
      }
      .rotationEffect(Angle(degrees: twisted ? 6 : 0))
      
      if badge == .trial {
        VStack(spacing: 0) {
          VStack {
            Line()
              .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
              .frame(maxWidth: 2, minHeight: 50)
              .foregroundColor(.primary.opacity(0.45))
          }
          .frame(maxHeight: 20, alignment: .bottom)
          .fixedSize()
          .frame(alignment: .top)
          
          HStack {
//            if let trialMinutesRemaining = license.trialMinutesRemaining {
//              Text("\(trialMinutesRemaining)")
//            }
              Text("48H LEFT")
          }
          .font(.system(size: 12, weight: .semibold))
          .opacity(0.75)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(
            RR(8, Color("simpleGray"))
              .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(RadialGradient(gradient: Gradient(colors: [.black.opacity(0), .black]), center: .topTrailing, startRadius: 0, endRadius: 100))
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .opacity(0.4)
                  .blendMode(.darken)
              )
          )
          .overlay  (
            VStack {
              RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                .blendMode(.softLight)
            }
              .padding(.all, 1)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          )
          .rotationEffect(Angle(degrees: kidTwisted ? -3 : 8))
          .offset(x: -5)
          
        }
        .zIndex(-1)
        .offset(x: 50, y: kidBadge ? 45 : -15)
        .rotationEffect(Angle(degrees: kidTwisted ? 3 : 8), anchor: .top)
      }
    }
    
  }
}

struct Star: View {
  var number: Int
  @State var duration = CGFloat.random(in: 1.25...2)
  @State var up = false
  @State var rotation: CGFloat = 180
  @State var position = CGPoint(x: 0, y: 200 + 42)
  @State var size = CGFloat.rand(10...25)
  @State private var timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
  @State private var offset = CGFloat.rand(8...16) * ([-1, 1].randomElement())!
  @Environment (\.colorScheme) var colorScheme: ColorScheme
  
  func move() {
    withAnimation(.easeInOut(duration: duration)) {
      offset = CGFloat.rand(8...16)
      up.toggle()
      rotation = CGFloat.random(in: -20...20)
    }
  }
  
  var body: some View {
    Image(systemName: "star.fill")
      .resizable()
      .scaledToFit()
      .frame(width: size, height: size)
    //                        .foregroundColor(Color(NSColor(hex: colorScheme == .dark ? "F9EFBA" : "fafafa")))
      .foregroundColor(Color(NSColor(hex: colorScheme == .dark ? "F9EFBA" : "fafafa")))
      .rotationEffect(Angle(degrees: rotation))
    //                        .shadow(color: Color(NSColor(hex: colorScheme == .dark ? "FFA262" : "656565")), radius: size * 0.75, y: colorScheme == .dark ? 0 : size * 0.5)
      .shadow(color: Color(NSColor(hex: colorScheme == .dark ? "FFA262" : "A9A400")), radius: size * 0.75, y: colorScheme == .dark ? 0 : size * 0.5)
      .shadow(color: Color(NSColor(hex: colorScheme == .dark ? "FFA262" : "A9A400")).opacity(0.75), radius: size * 0.75, y: colorScheme == .dark ? 0 : size * 0.5)
      .offset(y: up ? offset : 0)
      .position(position)
      .onReceive(timer) { _ in
        move()
      }
      .onAppear {
        timer.upstream.connect().cancel()
        position.x = (((600 - 80) / CGFloat(starsCount - 1)) * CGFloat(number)) + 40 + (CGFloat.rand(0...40) * ([-1, 1].randomElement())!)
        DispatchQueue.main.asyncAfter(deadline: .now() + CGFloat.random(in: 0...0.75)) {
          timer = Timer.publish(every: duration, on: .current, in: .common).autoconnect()
          move()
          withAnimation(.spring(response: CGFloat.random(in: 0.5...0.7), dampingFraction: 2)) {
            position.y = CGFloat.rand(100...CGFloat(200 - Int(size) - 30))
          }
        }
      }
      .onDisappear { timer.upstream.connect().cancel() }
  }
}

let BG_GRAD_DARK = Color(nsColor: NSColor(hex: "FFB13D"))
let BG_GRAD_LIGHT = Color(nsColor: NSColor(hex: "FFCC02"))
let HANG_ANIM = Animation.spring(response: 0.3, dampingFraction: 0.5)
let ROT_ANIM = Animation.spring(response: 0.4, dampingFraction: 0.25)

enum RegisterError: String {
  case noConnection = "The server couldn't be contacted"
  case notFound = "License not found"
  case inUse = "That license is already in use"
  case badRequest = "Something went wrong with the request"
  case serverError = "There was a server error"
}

let errorMap: [Int?:RegisterError] = [
  400: .badRequest,
  404: .notFound,
  409: .inUse,
  500: .serverError,
  nil: .noConnection,
]

struct LicenseSettingsView: View {
  @Environment (\.colorScheme) var colorScheme: ColorScheme
  @Environment(\.controlActiveState) private var controlActiveState
  @State var email = ""
  @State var key = ""
  @State var hideFix = false
  @State var showStars = false
  @State var hanging = true
  @State var hidden = false
  @State var twisted = false
  @State var loading = false
  @State var error: RegisterError?
  @State var badge: License.LicenseStatus = .fresh
  
//  @ObservedObject var sharedContainer = SharedContainer.shared

  
  func hide() {
    withAnimation(.interactiveSpring()) {
      twisted = false
      hidden = true
    }
  }
  
  func switchBadge(_ b: License.LicenseStatus) {
    hide()
    doThisAfter(0.4) {
      badge = b
    }
    doThisAfter(0.401) {
      withAnimation(ROT_ANIM) {
        twisted = true
      }
      withAnimation(HANG_ANIM) {
        hidden = false
      }
    }
  }
  
  var body: some View {
    let BG_GRAD = colorScheme == .dark ? BG_GRAD_DARK : BG_GRAD_LIGHT
    VStack {
      HStack(spacing: 16) {
        VStack(spacing: 1) {
          VStack {
            Line()
              .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
              .frame(maxWidth: 2, minHeight: 300)
              .foregroundColor(.primary.opacity(0.45))
          }
          .frame(maxHeight: hanging ? 20 : 125, alignment: .bottom)
          .fixedSize()
          .frame(alignment: .top)
          LicenseBadge(badge: badge)
            .rotationEffect(Angle(degrees: twisted ? -3 : 3))
            .shadow(color: .black.opacity(0.1), radius: 2, x: -2, y: 4)
            .shadow(color: .black.opacity(0.1), radius: 5, x: -4, y: 8)
            .shadow(color: .black.opacity(0.1), radius: 17, x: -8, y: 24)
            .shadow(color: .black.opacity(0.1), radius: 20, x: -16, y: 32)
          Spacer()
            .frame(maxHeight: .infinity)
        }
        .scaleEffect()
        .rotationEffect(Angle(degrees: twisted ? 0 : 5), anchor: .top)
        .offset(y: hidden ? -290 : 0 )
        .frame(maxWidth: .infinity)
        VStack(alignment: .leading, spacing: 12) {
          Text("Do you have a license?")
            .font(.system(size: 18, weight: .semibold))

          VStack {
            VStack(alignment: .leading, spacing: 4) {
              Text("Email")
              TextInput(text: $email, hideFix: $hideFix)
            }
            VStack(alignment: .leading, spacing: 4) {
              Text("Key")
              TextInput(text: $key, hideFix: $hideFix)
            }
          }
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(.primary.opacity(0.75))

          HStack {
            MasterButton(icon: "key.horizontal.fill", label: "Register") {
              if email != "" && key != "" {
                withAnimation(.spring()) {
                  loading = true
                }
                hide()
//                sharedContainer.licenseManager.registerKey(email: email, key: key) { status in
//                  withAnimation(.spring()) {
//                    switch status {
//                    case 200:
//                      break
//                    default:
//                      error = errorMap[status]
//                    }
//                    loading = false
//                  }
//                }
              }
            }
            if badge == .fresh {
              MasterButton(icon: "clock", label: "Start trial", mode: .subtle, color: .secondary, textColor: .primary) {
                switchBadge(.trial)
              }
              .transition(.scaleAndBlur)
            }
          }
          .animation(.spring(), value: badge)
        }
//        .loader(loading)
        .padding([.vertical, .trailing], 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        
      }
      .padding(.bottom, 120)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .defaultSettingsProps()
    .overlay(
      ZStack {
        MasterButton(icon: "cart.fill", label: "Get a copy", color: .yellow, textColor: .black) {
          NSWorkspace.shared.open(URL(string: "https://lo.cafe/damage")!)
        }
        .zIndex(1)
        .shadow(radius: 16, y: 8)
        .offset(y: badge == .activated ? 200 : 40)
        .animation(.spring(), value: badge)
        if showStars {
          ZStack {
            ForEach(Array(0...starsCount - 1), id: \.self) { number in
              Star(number: number)
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .opacity(1)
          //                                        .drawingGroup()
        }
      }
        .frame(maxWidth: .infinity, maxHeight: 200)
        .background(
          LinearGradient(gradient: Gradient(stops: generateGradientStops(BG_GRAD)), startPoint: .top, endPoint: .bottom)
          .frame(maxWidth: .infinity, maxHeight: colorScheme == .dark ? 175 : .infinity)
          .opacity(colorScheme == .dark ? 0.5 : 1)
          , alignment: .bottom
        )
      , alignment: .bottom
    )
//    .overlay(
//      HStack {
//        MasterButton(label: "1") {
//          switchBadge(.trial)
//        }
//        MasterButton(label: "2") {
//          switchBadge(.activated)
//        }
//        MasterButton(label: "3") {
//          switchBadge(.trialExpired)
//        }
//        MasterButton(label: "4") {
//          switchBadge(.fresh)
//        }
//        MasterButton(label: "5") {
//          switchBadge(.noConnection)
//        }
//      }
//        .opacity(0.1)
//        .saturation(0)
//      , alignment: .bottomLeading
//    )
    .onChange(of: controlActiveState) { newValue in
      switch newValue {
      case .key, .active:
        if !showStars {
          showStars = true
          withAnimation(HANG_ANIM) {
            hanging = false
          }
          withAnimation(ROT_ANIM) {
            twisted = true
          }
        }
      default:
        break
      }
    }
    .onAppear {
      showStars = true
      withAnimation(HANG_ANIM) {
        hanging = false
      }
      withAnimation(ROT_ANIM) {
        twisted = true
      }
    }
    .onDisappear {
      showStars = false
      hanging = true
      twisted = false
    }
    .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { _ in
      showStars = false
      hanging = true
      twisted = false
    }
  }
}

//struct GeneralSettings_Previews: PreviewProvider {
//        static var previews: some View {
//                GeneralSettings()
//        }
//}


func generateGradientStops(_ color: Color) -> [Gradient.Stop] {
    let opacities = [
        0.0, 0.004, 0.014, 0.03, 0.051, 0.075, 0.102, 0.131, 0.159, 0.188, 0.215, 0.239, 0.26, 0.276, 0.286, 0.29
    ]
    let locations = [
        0.0, 0.081, 0.155, 0.225, 0.29, 0.353, 0.412, 0.471, 0.529, 0.588, 0.647, 0.71, 0.775, 0.845, 0.919, 1.0
    ]

    return zip(opacities, locations).map { Gradient.Stop(color: color.opacity($0.0), location: $0.1) }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
      path.addLine(to: CGPoint(x: 0, y: rect.height))
        return path
    }
}

extension CGFloat {
        static func random(_ range1: ClosedRange<CGFloat>, _ range2: ClosedRange<CGFloat>) -> CGFloat {
                let ranges = [range1, range2]
                let selectedRange = ranges.randomElement()!
                return CGFloat.random(in: selectedRange)
        }
        static func rand(_ range: ClosedRange<CGFloat>) -> CGFloat {
                return CGFloat(arc4random_uniform(UInt32(range.upperBound - range.lowerBound) + 1) + UInt32(range.lowerBound))
        }
}
