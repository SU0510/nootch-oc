//
//  CalendarView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 04/06/24.
//

import SwiftUI
import AppKit
import EventKit
import SwiftDate

struct CalendarView: NSViewRepresentable {
    var size: CGSize
    var events: [EKEvent]
    @Binding var selectedDate: Date?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NMDatePicker {
        let datePicker = NMDatePicker(frame: .init(origin: .zero, size: size), dateValue: Date())
        events.forEach { datePicker.markDate($0.startDate) }
        return datePicker
    }
    
    
//    func updateNSView(_ nsView: FSCalendar, context: Context) {
    func updateNSView(_ datePicker: NMDatePicker, context: Context) {
        datePicker.unmarkAllDates()
        events.forEach { datePicker.markDate($0.startDate) }
    }
    
    class Coordinator: NSObject, NMDatePickerDelegate {
        func nmDatePicker(_ datePicker: NMDatePicker, selectedDate: Date) {
            self.parent.selectedDate = selectedDate
        }
        
        var parent: CalendarView
        
        init(_ parent: CalendarView) {
            self.parent = parent
        }
        
    }
    
}
