//
//  CalendarWidgetSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 08/06/24.
//

import SwiftUI
import Settings
import Defaults
import EventKit

struct CalendarWidgetSettingsView: View {
    
    @Default(.calendarWidgetSettings) private var settings
    
    @State private var availableCalendars: [EKCalendar] = []
    @State private var selectedCalendars: Set<String> = []
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Calendars to show:")
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(availableCalendars, id: \.calendarIdentifier) { calendar in
                            Toggle(isOn: Binding(
                                get: { selectedCalendars.contains(calendar.calendarIdentifier) },
                                set: { isOn in
                                    if isOn {
                                        selectedCalendars.insert(calendar.calendarIdentifier)
                                    } else {
                                        selectedCalendars.remove(calendar.calendarIdentifier)
                                    }
                                    updateSelectedCalendars()
                                }
                            )) {
                                Text(calendar.title)
                            }
                            .toggleStyle(ColoredToggleStyle(color: Color(calendar.cgColor)))
                            .frame(alignment: .leading)
                        }
                    }
                }
                .padding(.leading, 8)
            }
            .padding(32)
            .frame(width: 260)
            
            Divider()
            
            Settings.Container(contentWidth: 260) {
                Settings.Section(title: "", bottomDivider: true) {
                    Text("Width:")
                    SliderPlus(value: $settings.size.width.double, range: 3...12)
                }
                
                Settings.Section(title: "", bottomDivider: true) {
                    Toggle(String(localized: "Show today's past events"), isOn: $settings.shouldShowTodayPastEvents)
                        .padding(.vertical, 8)
                    
                    Toggle(String(localized: "Show all day events"), isOn: $settings.shouldShowAllDayEvents)
                        .padding(.vertical, 8)
                }
                
                Settings.Section(title: "", bottomDivider: true) {
                    Text("Number of days behind:")
                    SliderPlus(value: $settings.numberOfDaysBehindToDisplay, range: 0...21)
                }
                
                Settings.Section(title: "", bottomDivider: true) {
                    Text("Number of days ahead:")
                    SliderPlus(value: $settings.numberOfDaysAheadToDisplay, range: 0...21)
                }
                
                Settings.Section(title: "") {
                    Text("Other calendar settings:")
                    Button("Calendar Settings") {
                        openCalendarSettingsAccountsTab()
                    }
                }
            }
            .padding(0)
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            availableCalendars = CalendarManager.shared.availableCalendars
            selectedCalendars = Set(Defaults[.calendarWidgetSettings].selectedCalendars)
        }
    }
    
    private func updateSelectedCalendars() {
        let selected = availableCalendars.filter { selectedCalendars.contains($0.calendarIdentifier) }
        CalendarManager.shared.updateSelectedCalendars(selected)
    }
}

