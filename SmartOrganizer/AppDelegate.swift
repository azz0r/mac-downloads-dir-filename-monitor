import Cocoa
import SwiftUI
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var fileMonitor: FileMonitor!
    private var fileOrganizer: FileOrganizer!
    private var intelligenceManager: IntelligenceManager!
    private var preferencesWindow: NSWindow?
    
    private var renameTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("SmartOrganizer starting...")
        setupMenuBar()
        setupServices()
        requestDownloadsAccess()
        print("SmartOrganizer started successfully")
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.badge.arrow.up", accessibilityDescription: "Smart File Renamer")
            button.action = #selector(toggleMenu)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    private func setupServices() {
        intelligenceManager = IntelligenceManager()
        fileOrganizer = FileOrganizer(intelligenceManager: intelligenceManager)
        fileMonitor = FileMonitor()
    }
    
    private func startMonitoring() {
        // Request permission for Downloads folder access
        requestDownloadsAccess()
        
        fileMonitor.startMonitoring { [weak self] files in
            guard let self = self else { return }
            
            Task {
                for file in files {
                    // Only process files older than 5 seconds to avoid renaming files being written
                    let fileAge = Date().timeIntervalSince(file.creationDate ?? Date())
                    if fileAge > 5 {
                        let _ = await self.fileOrganizer.analyzeAndRenameFile(at: file.url)
                    }
                }
            }
        }
    }
    
    private func hasDownloadsAccess() -> Bool {
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        
        do {
            _ = try FileManager.default.contentsOfDirectory(at: downloadsURL, includingPropertiesForKeys: nil)
            return true
        } catch {
            return false
        }
    }
    
    private func requestDownloadsAccess() {
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        
        // Try to access the Downloads folder
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: downloadsURL, includingPropertiesForKeys: nil)
            print("Downloads folder access granted. Found \(contents.count) items.")
        } catch {
            print("Downloads folder access denied or error: \(error)")
            showPermissionAlert()
        }
    }
    
    @objc private func requestPermissions() {
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        
        // First try to trigger permission dialog with NSOpenPanel
        let openPanel = NSOpenPanel()
        openPanel.message = "Please grant access to your Downloads folder"
        openPanel.prompt = "Grant Access"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.directoryURL = downloadsURL
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK {
            // Save bookmark for persistent access
            if let url = openPanel.url {
                do {
                    let bookmarkData = try url.bookmarkData(
                        options: .withSecurityScope,
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                    
                    UserDefaults.standard.set(bookmarkData, forKey: "DownloadsBookmark")
                    
                    showNotification(title: "Success", message: "Downloads folder access granted!")
                    
                    // Restart monitoring
                    fileMonitor.stopMonitoring()
                    startMonitoring()
                } catch {
                    print("Failed to save bookmark: \(error)")
                    showPermissionAlert()
                }
            }
        }
    }
    
    private func showPermissionAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Downloads Folder Access Required"
            alert.informativeText = "Smart File Renamer needs access to your Downloads folder to rename files.\n\nYou can grant access through:\n1. The 'Request Permissions' menu option\n2. System Settings > Privacy & Security > Files and Folders"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Try Again")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                // Open System Settings
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders") {
                    NSWorkspace.shared.open(url)
                }
            } else if response == .alertSecondButtonReturn {
                self.requestPermissions()
            }
        }
    }
    
    @objc private func toggleMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Rename Files Now", action: #selector(renameNow), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Request Permissions", action: #selector(requestPermissions), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        self.statusItem.menu = menu
        self.statusItem.button?.performClick(self)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.statusItem.menu = nil
        }
    }
    
    @objc private func renameNow() {
        Task {
            let count = await renameEligibleFiles()
            if count > 0 {
                print("Renamed \(count) files")
            }
        }
    }
    
    @objc private func openPreferences() {
        if preferencesWindow == nil {
            let preferencesView = PreferencesWindow(fileOrganizer: self.fileOrganizer)
            preferencesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered, defer: false
            )
            preferencesWindow?.contentView = NSHostingView(rootView: preferencesView)
            preferencesWindow?.title = "Smart File Renamer Preferences"
            preferencesWindow?.center()
        }
        preferencesWindow?.makeKeyAndOrderFront(nil)
    }
    
    @objc private func viewHistory() {
        let historyWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false
        )
        
        let historyView = RenameHistoryView(fileOrganizer: fileOrganizer)
        historyWindow.contentView = NSHostingView(rootView: historyView)
        historyWindow.title = "Rename History"
        historyWindow.center()
        historyWindow.makeKeyAndOrderFront(nil)
    }
    
    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        
        if service.status == .enabled {
            do {
                try service.unregister()
                showNotification(title: "Launch at Login", message: "Disabled")
            } catch {
                showNotification(title: "Error", message: "Failed to disable launch at login")
            }
        } else {
            do {
                try service.register()
                showNotification(title: "Launch at Login", message: "Enabled")
            } catch {
                showNotification(title: "Error", message: "Failed to enable launch at login")
            }
        }
    }
    
    private func renameEligibleFiles() async -> Int {
        print("Starting renameEligibleFiles...")
        
        // Get files directly from Downloads
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        var renamedCount = 0
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: downloadsURL, includingPropertiesForKeys: [.creationDateKey])
            
            for fileURL in contents {
                // Check if it's a file (not directory)
                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory), !isDirectory.boolValue {
                    // Check if file is old enough (5 seconds)
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                       let creationDate = attrs[.creationDate] as? Date,
                       Date().timeIntervalSince(creationDate) > 5 {
                        
                        // Process the file
                        if await fileOrganizer.analyzeAndRenameFile(at: fileURL) {
                            renamedCount += 1
                        }
                    }
                }
            }
        } catch {
            print("Error accessing Downloads folder: \(error)")
        }
        
        print("Finished renameEligibleFiles. Renamed \(renamedCount) files.")
        return renamedCount
    }
    
    private func showNotification(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            
            if let window = NSApplication.shared.keyWindow {
                alert.beginSheetModal(for: window)
            } else {
                alert.runModal()
            }
        }
    }
}

struct RenameHistoryView: View {
    @ObservedObject var fileOrganizer: FileOrganizer
    
    var body: some View {
        VStack {
            Text("Rename History")
                .font(.title)
                .padding()
            
            List(fileOrganizer.renameHistory.reversed(), id: \.date) { history in
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Original:")
                            .fontWeight(.semibold)
                        Text(history.originalName)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("New:")
                            .fontWeight(.semibold)
                        Text(history.newName)
                            .foregroundColor(.blue)
                    }
                    Text(history.reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(history.date, style: .date)
                        .font(.caption)
                }
                .padding(.vertical, 5)
            }
            
            HStack {
                Button("Clear History") {
                    fileOrganizer.clearHistory()
                }
                .disabled(fileOrganizer.renameHistory.isEmpty)
                
                Spacer()
                
                Text("\(fileOrganizer.renameHistory.count) renames")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}