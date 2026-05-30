//
//  Tray.swift
//  NotchNook
//
//  Created by Igor Marcossi on 18/05/24.
//

import SwiftUI
import Cocoa
import Quartz

@Observable
class Tray {
    var editingFile: (file: TrayFile, newName: String)?
    
    private enum KeyCode: UInt16 {
        case a = 0
        case c = 8
        case v = 9
        case spaceBar = 49
        case returnKey = 36
        case esc = 53
        case delete = 51
        case leftArrow = 123
        case rightArrow = 124
    }
    
    private var tempDirectory: URL?
    private var folderMonitor: FolderMonitor?
    private var flagsChangedMonitor: Any?
    private var keyDownMonitor: Any?
    private var keyDownMonitorID: UUID?
    private var isMonitoring: Bool = false
    
    let activitiesManager: ActiveLiveActivitiesManager
    
    private(set) var files = [TrayFile]() {
        willSet {
            let newSelectedFiles = selectedFiles.filter { newValue.contains($0) }
            if selectedFiles.count != newSelectedFiles.count {
                selectedFiles = newSelectedFiles
            }
            
            if newValue.isEmpty {
                stopMonitoringEvents()
            }
            
            let isTrayActive = activitiesManager.activeLiveActivities.contains(.tray)
            if newValue.isEmpty {
                if isTrayActive {
                    MainActor.assumeIsolated { activitiesManager.removeSync(.tray) }
                }
            } else {
                if !isTrayActive {
                    MainActor.assumeIsolated { activitiesManager.insertSync(.tray) }
                }
            }
        }
        didSet {
            if !files.isEmpty && !isMonitoring {
                startMonitoringEvents()
            } else if files.isEmpty && isMonitoring {
                stopMonitoringEvents()
            }
            persist()
        }
    }
    private(set) var selectedFiles = [TrayFile]()
    private var baseFileIndex: Int?
    private var lastSelectedIndex: Int?
    private var pressedKeysEvent: NSEvent?
    
    private var isCommandPressed: Bool {
        NSEvent.modifierFlags.contains(.command)
    }
    private var isShiftPressed: Bool {
        NSEvent.modifierFlags.contains(.shift)
    }
    
    // MARK: - Stack helpers

    /// A logical tray item: either a single ungrouped file or a named stack of files.
    enum TrayItem: Identifiable {
        case single(TrayFile)
        case stack(id: UUID, files: [TrayFile], name: String)

        var id: AnyHashable {
            switch self {
            case .single(let f): return AnyHashable(f.id)
            case .stack(let id, _, _): return AnyHashable(id)
            }
        }
    }

    /// Derived list of tray items used by the scroll view. Preserves the insertion order
    /// of the first file in each group so the visual order is stable.
    var trayItems: [TrayItem] {
        var seen = Set<UUID>()
        var result: [TrayItem] = []
        // Collect files in their current order, grouping by stackID.
        var stackBuckets: [UUID: [TrayFile]] = [:]
        var stackOrder: [UUID] = []
        for file in files {
            if let sid = file.stackID {
                if stackBuckets[sid] == nil {
                    stackBuckets[sid] = []
                    stackOrder.append(sid)
                }
                stackBuckets[sid]!.append(file)
            }
        }

        for file in files {
            if let sid = file.stackID {
                guard !seen.contains(sid) else { continue }
                seen.insert(sid)
                let members = stackBuckets[sid] ?? []
                result.append(.stack(id: sid, files: members, name: stackName(for: members)))
            } else {
                result.append(.single(file))
            }
        }
        return result
    }

    /// Auto-generate a human-readable stack title.
    /// Rules: shared extension → "PDFs · 3"; shared parent dir → "FolderName · 3"; else "3 files".
    private func stackName(for stackFiles: [TrayFile]) -> String {
        let count = stackFiles.count
        guard count > 0 else { return "0 files" }

        let extensions = Set(stackFiles.map { $0.url.pathExtension.lowercased() }.filter { !$0.isEmpty })
        if extensions.count == 1, let ext = extensions.first {
            let label = ext.uppercased() + "s"
            return "\(label) · \(count)"
        }

        let parents = Set(stackFiles.map { $0.url.deletingLastPathComponent().lastPathComponent })
        if parents.count == 1, let parent = parents.first, !parent.isEmpty, parent != "/" {
            return "\(parent) · \(count)"
        }

        return "\(count) files"
    }

    // MARK: - Persistence helpers

    /// URL of the JSON state file that records which files live in the tray dir.
    private var stateFileURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let bundleID = Bundle.main.bundleIdentifier ?? "NotchNook"
        return appSupport
            .appendingPathComponent(bundleID, isDirectory: true)
            .appendingPathComponent("tray_state.json")
    }

    /// Codable envelope for one tray file entry in the JSON state.
    /// stackID was added in the Wave 3 multi-drop commit; old records without this key
    /// decode safely because it is optional (nil by default), so existing tray_state.json
    /// files continue to load without any migration.
    private struct TrayFileRecord: Codable {
        let url: URL
        let addedAt: Date
        let originalName: String
        // Optional: absent in records written before stacks were introduced → decodes as nil.
        var stackID: UUID?
    }

    /// Persist current file list. Called after every mutation.
    private func persist() {
        guard let dest = stateFileURL else { return }
        let records = files.map { TrayFileRecord(url: $0.url, addedAt: $0.addedAt, originalName: $0.name, stackID: $0.stackID) }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(records)
            try data.write(to: dest, options: .atomic)
        } catch {
            print("[Tray] Failed to persist tray state: \(error)")
        }
    }

    /// Load file list from disk, dropping any entries whose files no longer exist.
    private func loadPersistedFiles() {
        guard let src = stateFileURL,
              FileManager.default.fileExists(atPath: src.path) else { return }
        do {
            let data = try Data(contentsOf: src)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let records = try decoder.decode([TrayFileRecord].self, from: data)
            let fm = FileManager.default
            let valid = records.filter { record in
                let exists = fm.fileExists(atPath: record.url.path)
                if !exists { print("[Tray] Dropping missing file from persisted state: \(record.url.lastPathComponent)") }
                return exists
            }
            // List is typically < 100 files; safe to assign inline on the calling queue (main).
            self.files = valid.map { TrayFile(url: $0.url, stackID: $0.stackID) }
        } catch {
            print("[Tray] Failed to load tray state: \(error)")
        }
    }

    // MARK: - Initialization
    
    init(activitiesManager: ActiveLiveActivitiesManager = .shared) {
        self.activitiesManager = activitiesManager
        // Set up durable dir first so tempDirectory is ready for loadPersistedFiles.
        setupTempDirectory()
        loadPersistedFiles()
    }
    
    // MARK: - Setup methods
    
    private func startMonitoringEvents() {
        setupTempDirectory()
        setupEventMonitors()

        isMonitoring = true
    }
    
    // MARK: - Setup methods
    
    private func setupTempDirectory() {
        // Use Application Support so files survive reboots.
        // ~/Library/Application Support/<bundleID>/TrayFiles/
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("[Tray] Could not locate Application Support directory")
            return
        }
        let bundleID = Bundle.main.bundleIdentifier ?? "NotchNook"
        let trayDir = appSupport.appendingPathComponent(bundleID, isDirectory: true)
                                .appendingPathComponent("TrayFiles", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: trayDir, withIntermediateDirectories: true, attributes: nil)
            tempDirectory = trayDir
        } catch {
            print("[Tray] Failed to create tray directory: \(error)")
        }
    }
    
    func setupEventMonitors() {
        setupFlagsChangedMonitor()
        setupKeyDownMonitor()
        setupFolderMonitor()
    }
    
    func setupFlagsChangedMonitor() {
        flagsChangedMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.pressedKeysEvent = event
            return event
        }
    }
    
    private func setupKeyDownMonitor() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        guard accessEnabled else { return }
        
        // prevents monitoring events of any other monitor
        let monitorID = UUID()
        keyDownMonitorID = monitorID
            
        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard
                let self = self,
                let keyCode = KeyCode(rawValue: event.keyCode),
                self.keyDownMonitorID == monitorID
            else { return event }
                        
            if editingFile != nil {
                return handleEditingKeys(event: event, key: keyCode)
            } else {
                return handleNonEditingKeys(event: event, key: keyCode)
            }
        }
    }
    
    private func setupFolderMonitor() {
        guard let tempDirectory else { return }
        folderMonitor = FolderMonitor(path: tempDirectory.path()) { [weak self] in
            DispatchQueue.main.async { self?.updateFiles() }
        }
        folderMonitor?.start()
    }
    
    func stopMonitoringEvents() {
        if let flagsChangedMonitor = flagsChangedMonitor {
            NSEvent.removeMonitor(flagsChangedMonitor)
            self.flagsChangedMonitor = nil
        }
        
        if let keyDownMonitor = keyDownMonitor {
            NSEvent.removeMonitor(keyDownMonitor)
            self.keyDownMonitor = nil
            self.keyDownMonitorID = nil
        }
        
        folderMonitor?.stop()
        folderMonitor = nil
        
        isMonitoring = false
    }
    
    func rename() {
        guard let editingFile = editingFile else { return }
        editingFile.file.rename(to: editingFile.newName)
        self.editingFile = nil
    }
    
    // MARK: Keys handling
    
    private func handleEditingKeys(event: NSEvent, key: KeyCode) -> NSEvent? {
        guard selectedFiles.count == 1 else { return event }
        
        switch key {
            case .returnKey:
                rename()
                return nil
                
            case .esc:
                editingFile = nil
                return nil
                
            default: return event
        }
    }
    
    private func handleNonEditingKeys(event: NSEvent, key: KeyCode) -> NSEvent? {
        switch key {
            case .a where isCommandPressed:
                selectAllFiles()
                return nil
                
            case .c where isCommandPressed:
                copySelectedFilesToClipboard()
                return nil
                
            case .v where isCommandPressed:
                pasteFromClipboard()
                return nil
                
            case .spaceBar:
                toggleQuickLookState()
                return nil
                
            case .returnKey:
                if let file = selectedFiles.first, selectedFiles.count == 1 {
                    editingFile = (file, file.name)
                }
                return nil
                
            case .delete:
                removeSelectedFiles()
                return nil
                
            case .leftArrow, .rightArrow:
                let direction = key == .leftArrow ? -1 : 1
                if NSEvent.modifierFlags.contains(.shift) {
                    self.handleShiftArrowSelection(direction: direction)
                } else {
                    self.selectAdjacentFile(direction: direction)
                }
                return nil
                
            default: return event
        }
    }
    
    private func handleShiftArrowSelection(direction: Int) {
        guard !files.isEmpty else { return }
        
        if selectedFiles.isEmpty {
            lastSelectedIndex = 0
            selectedFiles = [files[0]]
        } else if lastSelectedIndex == nil {
            lastSelectedIndex = files.firstIndex(of: selectedFiles.last ?? files[0])
        }
        
        guard let currentIndex = lastSelectedIndex else { return }
        
        let newIndex = max(0, min(files.count - 1, currentIndex + direction))
        lastSelectedIndex = newIndex
        
        if baseFileIndex == nil {
            baseFileIndex = currentIndex
        }
        
        if let baseIndex = baseFileIndex {
            let rangeToSelect = min(baseIndex, newIndex)...max(baseIndex, newIndex)
            selectedFiles = Array(files[rangeToSelect])
        }
    }
    
    // MARK: Handling files methods
    
    func removeFile(_ file: TrayFile) {
        withAnimation(.smooth) {
            files.removeAll { $0 == file }
            selectedFiles.removeAll { $0 == file }
            baseFileIndex = nil
        }
        
        if files.isEmpty {
            cleanupTemporaryDirectory()
        }
    }
    
    private func addFile(_ file: TrayFile) {
        withAnimation(.smooth) {
            if !files.contains(file) {
                files.append(file)
            }
        }
    }
    
    func selectFile(_ file: TrayFile?) {
        guard let file else {
            selectedFiles.removeAll()
            baseFileIndex = nil
            lastSelectedIndex = nil
            return
        }
        
        if isShiftPressed {
            if let baseIndex = baseFileIndex, let currentIndex = files.firstIndex(of: file) {
                let rangeToSelect = min(baseIndex, currentIndex)...max(baseIndex, currentIndex)
                selectedFiles = Array(files[rangeToSelect])
                lastSelectedIndex = currentIndex
            } else {
                selectedFiles = [file]
                baseFileIndex = files.firstIndex(of: file)
                lastSelectedIndex = baseFileIndex
            }
        } else if isCommandPressed {
            if let index = selectedFiles.firstIndex(of: file) {
                selectedFiles.remove(at: index)
            } else {
                selectedFiles.append(file)
            }
            baseFileIndex = files.firstIndex(of: file)
            lastSelectedIndex = baseFileIndex
        } else {
            selectedFiles = [file]
            baseFileIndex = files.firstIndex(of: file)
            lastSelectedIndex = baseFileIndex
        }
        
        editingFile = nil
    }
    
    private func selectAdjacentFile(direction: Int) {
        guard !files.isEmpty else { return }
        
        let currentIndex = selectedFiles.isEmpty ? 0 : (files.firstIndex(of: selectedFiles.last!) ?? 0)
        let newIndex = max(0, min(files.count - 1, currentIndex + direction))
        
        selectFile(files[newIndex])
    }
    
    private func selectAllFiles() {
        selectedFiles = files
        baseFileIndex = 0
        lastSelectedIndex = files.count - 1
    }
    
    func openFile(_ file: TrayFile) {
        NSWorkspace.shared.open(file.url)
    }
    
    func removeSelectedFiles(currentFile: TrayFile? = nil) {
        withAnimation(.smooth) {
            guard let currentFile, !selectedFiles.contains(currentFile) else {
                files.removeAll { selectedFiles.contains($0) }
                selectedFiles.removeAll()
                baseFileIndex = nil
                return
            }
            removeFile(currentFile)
        }
    }
    
    func addFilesFromURLs(_ fileURLs: [URL]) {
        // Decision: COPY on drop.
        // URLs arriving here may point to anywhere on disk (external files, Downloads, etc.)
        // or to ephemeral NSTemporaryDirectory() paths that disappear on reboot.
        // We copy every file into our durable TrayFiles dir so persisted URLs always resolve.
        // The original file is left untouched; we only make a copy.
        // Security-scoped bookmarks are NOT needed because we own the copied file.
        let fm = FileManager.default
        let destDir = tempDirectory  // already set up in setupTempDirectory()

        let resolvedURLs: [URL] = fileURLs.compactMap { sourceURL in
            guard let destDir = destDir else { return sourceURL }
            // If the file is already inside our tray dir, use it directly.
            if sourceURL.path.hasPrefix(destDir.path) { return sourceURL }
            // Build a unique dest path to avoid collisions.
            var destURL = destDir.appendingPathComponent(sourceURL.lastPathComponent)
            var attempt = 0
            let base = destURL.deletingPathExtension().lastPathComponent
            let ext = destURL.pathExtension
            while fm.fileExists(atPath: destURL.path) {
                attempt += 1
                let candidate = ext.isEmpty ? "\(base) \(attempt)" : "\(base) \(attempt).\(ext)"
                destURL = destDir.appendingPathComponent(candidate)
            }
            do {
                try fm.copyItem(at: sourceURL, to: destURL)
                return destURL
            } catch {
                print("[Tray] Failed to copy \(sourceURL.lastPathComponent) into tray dir: \(error). Using original reference.")
                return sourceURL
            }
        }

        // If 2+ files arrive in a single drop gesture, assign them all the same stackID
        // so they render as a collapsed stack chip in the tray UI.
        let dropStackID: UUID? = resolvedURLs.count >= 2 ? UUID() : nil
        let newFiles = resolvedURLs.concurrentMap { TrayFile(url: $0, stackID: dropStackID) }
        for file in newFiles { self.addFile(file) }
    }
    
    func copySelectedFilesToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let urls = selectedFiles.map { $0.url }
        pasteboard.writeObjects(urls as [NSPasteboardWriting])
    }
    
    func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        guard let destDir = tempDirectory else { return }
        var pastedURLs: [URL] = []

        // 1. File URLs
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !fileURLs.isEmpty {
            pastedURLs.append(contentsOf: fileURLs)
        }

        // 2. Image data (png / tiff / NSImage)
        if pastedURLs.isEmpty {
            let imageTypes: [NSPasteboard.PasteboardType] = [.png, .tiff]
            var imageData: Data? = nil
            for type in imageTypes {
                if let data = pasteboard.data(forType: type) { imageData = data; break }
            }
            if imageData == nil, let img = NSImage(pasteboard: pasteboard) {
                imageData = img.tiffRepresentation
            }
            if let raw = imageData {
                let pngData: Data
                if let bitmap = NSBitmapImageRep(data: raw),
                   let png = bitmap.representation(using: .png, properties: [:]) {
                    pngData = png
                } else {
                    pngData = raw
                }
                let destURL = destDir.appendingPathComponent("\(UUID().uuidString).png")
                do {
                    try pngData.write(to: destURL, options: .atomic)
                    pastedURLs.append(destURL)
                } catch {
                    print("[Tray] Failed to write pasted image: \(error)")
                }
            }
        }

        // 3. Plain text
        if pastedURLs.isEmpty, let text = pasteboard.string(forType: .string), !text.isEmpty {
            let destURL = destDir.appendingPathComponent("\(UUID().uuidString).txt")
            do {
                try text.write(to: destURL, atomically: true, encoding: .utf8)
                pastedURLs.append(destURL)
            } catch {
                print("[Tray] Failed to write pasted text: \(error)")
            }
        }

        if pastedURLs.isEmpty {
            print("[Tray] Paste: pasteboard contained nothing usable.")
            return
        }

        // Files written directly to destDir (image/text cases) are already in our tray dir.
        // External file URLs (case 1) will be copied inside addFilesFromURLs.
        addFilesFromURLs(pastedURLs)
    }
    
    func airdropSelectedFiles() {
        airDropItems(items: selectedFiles.map { $0.url })
    }
    
    private func toggleQuickLookState() {
        guard let panel = QLPreviewPanel.shared() else { return }
        
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.dataSource = self
            panel.makeKeyAndOrderFront(nil)
        }
    }
    
    private func updateFiles() {
        DispatchQueue.global().async {
            let fileManager = FileManager.default
            var updatedFiles = [TrayFile]()
            
            guard let directory = self.tempDirectory else { return }
            let existingFiles = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            
            for file in self.files {
                let fileExists = existingFiles?.contains(where: { $0.lastPathComponent == file.url.lastPathComponent }) ?? false
                if fileExists {
                    updatedFiles.append(file)
                } else {
                    if let newURL = self.findExistingFile(for: file.url) {
                        updatedFiles.append(TrayFile(url: newURL))
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.files = updatedFiles
            }
        }
    }
    
    private func findExistingFile(for oldURL: URL) -> URL? {
        guard let directory = oldURL.deletingLastPathComponent() as URL?,
              let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else { return nil }
        for case let fileURL as URL in enumerator {
            if fileURL.lastPathComponent != oldURL.lastPathComponent && fileURL.deletingPathExtension().lastPathComponent == oldURL.deletingPathExtension().lastPathComponent {
                return fileURL
            }
        }
        return nil
    }
    
}

// MARK: - QuickLook Datasource

extension Tray: QLPreviewPanelDataSource {
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        selectedFiles.count
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        selectedFiles[selectedFiles.index(selectedFiles.startIndex, offsetBy: index)].url as QLPreviewItem
    }
}
