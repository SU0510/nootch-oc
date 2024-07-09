//
//  GIFViewer.swift
//  NotchNook
//
//  Created by Igor Marcossi on 07/07/24.
//

import SwiftUI
import AppKit
import Quartz

struct QLImage: NSViewRepresentable {
    var url: URL
    
    func makeNSView(context: NSViewRepresentableContext<QLImage>) -> QLPreviewView {
        let preview = QLPreviewView(frame: .zero, style: .normal)
        preview?.autostarts = true
        preview?.previewItem = url as QLPreviewItem
        preview?.layer?.magnificationFilter = .nearest
        preview?.layer?.minificationFilter = .nearest
        
        return preview ?? QLPreviewView()
    }
    
    func updateNSView(_ nsView: QLPreviewView, context: NSViewRepresentableContext<QLImage>) {
        nsView.previewItem = url as QLPreviewItem
        nsView.layer?.magnificationFilter = .nearest
        nsView.layer?.minificationFilter = .nearest
    }
    
    typealias NSViewType = QLPreviewView
}
