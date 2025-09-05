import SwiftUI

struct PreferencesWindow: View {
    @StateObject var fileOrganizer: FileOrganizer
    @State private var renameInterval = 30
    @State private var fileAgeThreshold = 60
    @State private var enableSmartRenaming = true
    @State private var skipDescriptiveNames = true
    
    var body: some View {
        TabView {
            GeneralSettingsView(
                renameInterval: $renameInterval,
                fileAgeThreshold: $fileAgeThreshold,
                enableSmartRenaming: $enableSmartRenaming,
                skipDescriptiveNames: $skipDescriptiveNames
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            RenameRulesView()
            .tabItem {
                Label("Rename Rules", systemImage: "textformat")
            }
            
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 600, height: 400)
    }
}

struct GeneralSettingsView: View {
    @Binding var renameInterval: Int
    @Binding var fileAgeThreshold: Int
    @Binding var enableSmartRenaming: Bool
    @Binding var skipDescriptiveNames: Bool
    @AppStorage("monitorDownloads") private var monitorDownloads = true
    @AppStorage("showNotifications") private var showNotifications = true
    
    var body: some View {
        Form {
            Section("Monitoring") {
                Toggle("Monitor Downloads Folder", isOn: $monitorDownloads)
                
                HStack {
                    Text("Check for files to rename every:")
                    Picker("", selection: $renameInterval) {
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                        Text("1 hour").tag(60)
                        Text("2 hours").tag(120)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                HStack {
                    Text("Only rename files older than:")
                    Picker("", selection: $fileAgeThreshold) {
                        Text("30 minutes").tag(30)
                        Text("1 hour").tag(60)
                        Text("2 hours").tag(120)
                        Text("1 day").tag(1440)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            Section("Renaming Options") {
                Toggle("Enable smart content-based renaming", isOn: $enableSmartRenaming)
                    .help("Analyzes file content to generate descriptive names")
                
                Toggle("Skip files with descriptive names", isOn: $skipDescriptiveNames)
                    .help("Won't rename files that already have meaningful names")
            }
            
            Section("Notifications") {
                Toggle("Show notifications when files are renamed", isOn: $showNotifications)
            }
        }
        .padding()
    }
}

struct RenameRulesView: View {
    @State private var genericPatterns = [
        "IMG_####",
        "DSC####",
        "Screenshot YYYY-MM-DD",
        "Untitled",
        "Document#",
        "download",
        "temp"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Generic Filename Patterns")
                .font(.title2)
                .bold()
                .padding(.top)
            
            Text("Files matching these patterns will be renamed:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            List(genericPatterns, id: \.self) { pattern in
                HStack {
                    Image(systemName: "textformat")
                        .foregroundColor(.blue)
                    Text(pattern)
                        .font(.system(.body, design: .monospaced))
                }
                .padding(.vertical, 4)
            }
            
            Text("Renaming Examples")
                .font(.title3)
                .bold()
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                RenameExampleRow(original: "IMG_1234.jpg", renamed: "Vacation_Beach_2025-01-05.jpg")
                RenameExampleRow(original: "invoice.pdf", renamed: "Invoice_Apple_2025-01-05.pdf")
                RenameExampleRow(original: "Screenshot 2025-01-05.png", renamed: "Screenshot_Xcode_2025-01-05.png")
                RenameExampleRow(original: "document.docx", renamed: "Document_Project_Proposal_2025-01-05.docx")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
    }
}

struct RenameExampleRow: View {
    let original: String
    let renamed: String
    
    var body: some View {
        HStack {
            Text(original)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
            
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(.blue)
            
            Text(renamed)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.blue)
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.arrow.up")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Smart File Renamer")
                .font(.title)
                .bold()
            
            Text("Version 1.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Automatically rename Downloads with intelligent, descriptive filenames")
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            
            Divider()
                .frame(width: 200)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Features:")
                    .bold()
                
                Label("AI-powered content analysis", systemImage: "brain")
                Label("Smart filename generation", systemImage: "textformat.abc")
                Label("Preserves original files", systemImage: "checkmark.shield")
                Label("No cloud processing", systemImage: "lock.shield")
            }
            .font(.caption)
            
            Spacer()
            
            Text("All processing happens locally on your Mac")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}