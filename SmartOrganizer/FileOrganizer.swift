import Foundation
import AppKit

struct RenameHistory: Codable {
    let originalName: String
    let newName: String
    let date: Date
    let reason: String
}

class FileOrganizer: ObservableObject {
    @Published var renameHistory: [RenameHistory] = []
    @Published var pendingRenames: [URL: String] = [:]
    
    private let intelligenceManager: IntelligenceManager
    private let fileManager = FileManager.default
    private let historyPath: URL
    
    init(intelligenceManager: IntelligenceManager) {
        self.intelligenceManager = intelligenceManager
        
        let tempPath = fileManager.temporaryDirectory
        self.historyPath = tempPath.appendingPathComponent("SmartOrganizer_rename_history.json")
        
        try? fileManager.createDirectory(at: historyPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        loadHistory()
    }
    
    func analyzeAndRenameFile(at url: URL) async -> Bool {
        let originalName = url.lastPathComponent
        let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.pathExtension
        
        print("Analyzing file: \(originalName)")
        
        // Always process generic names
        if isGenericName(nameWithoutExtension) {
            print("\(originalName) is generic - will rename")
        } else {
            // For non-generic names, only skip if already renamed by us
            let hasDatePattern = nameWithoutExtension.range(of: "_\\d{4}-\\d{2}-\\d{2}", options: .regularExpression) != nil
            let isOurFormat = nameWithoutExtension.range(of: "^(Documents|Photos|Screenshots|Invoices|Receipts|Archives|Videos|Music|Code|Presentations|Spreadsheets|Misc)_", options: .regularExpression) != nil
            
            if hasDatePattern && isOurFormat {
                print("Skipping \(originalName) - already renamed by SmartOrganizer")
                return false
            }
        }
        
        // Analyze file to get category and generate descriptive name
        let category = await intelligenceManager.analyzeFile(at: url)
        let context = await intelligenceManager.extractContext(from: url)
        
        print("AI Analysis - Category: \(category.rawValue), Context: \(context)")
        
        // Use AI to generate intelligent name
        let baseName = intelligenceManager.generateIntelligentName(for: url, context: context, category: category)
        
        // Ensure unique name with counter suffix if needed
        var finalName = "\(baseName).\(fileExtension)"
        var counter = 1
        var newURL = url.deletingLastPathComponent().appendingPathComponent(finalName)
        
        while fileManager.fileExists(atPath: newURL.path) && newURL.path != url.path {
            finalName = "\(baseName)_\(counter).\(fileExtension)"
            newURL = url.deletingLastPathComponent().appendingPathComponent(finalName)
            counter += 1
        }
        
        if finalName == originalName {
            return false
        }
        
        // Rename the file
        do {
            try fileManager.moveItem(at: url, to: newURL)
            
            let history = RenameHistory(
                originalName: originalName,
                newName: finalName,
                date: Date(),
                reason: "Categorized as \(category.rawValue): \(context)"
            )
            
            renameHistory.append(history)
            saveHistory()
            
            print("Renamed: \(originalName) → \(finalName)")
            return true
        } catch {
            print("Failed to rename file: \(error)")
            return false
        }
    }
    
    private func isGenericName(_ name: String) -> Bool {
        let genericPatterns = [
            "^IMG_\\d+$",
            "^DSC\\d+$",
            "^Screenshot.*\\d{4}-\\d{2}-\\d{2}",
            "^screencapture-.*\\d{4}-\\d{2}-\\d{2}",
            "^ChatGPT Image",
            "^Untitled",
            "^Document\\d*$",
            "^download",
            "^temp",
            "^Invoice-[A-Z0-9]+",
            "^NXT[a-zA-Z0-9]+",
            "^\\d+$",
            "^[a-f0-9]{32}$" // MD5 hash
        ]
        
        for pattern in genericPatterns {
            if name.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        return false
    }
    
    private func extractVendorName(from context: String) -> String? {
        // Look for common vendor patterns
        let patterns = [
            "(?:from|by|vendor:|company:)\\s*([A-Z][\\w\\s]+)",
            "([A-Z][\\w]+(?:\\s+[A-Z][\\w]+)*?)\\s+(?:Inc|LLC|Ltd|Corp|Company)"
        ]
        
        for pattern in patterns {
            if let match = context.range(of: pattern, options: .regularExpression) {
                let vendor = String(context[match])
                    .replacingOccurrences(of: "from", with: "")
                    .replacingOccurrences(of: "by", with: "")
                    .replacingOccurrences(of: "vendor:", with: "")
                    .replacingOccurrences(of: "company:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !vendor.isEmpty && vendor.count < 30 {
                    return vendor.replacingOccurrences(of: " ", with: "_")
                }
            }
        }
        
        return nil
    }
    
    private func extractAppName(from context: String) -> String? {
        // Extract app name from screenshot context
        let words = context.components(separatedBy: .whitespacesAndNewlines)
        if let appIndex = words.firstIndex(where: { $0.lowercased().contains("app") }) {
            if appIndex > 0 {
                return words[appIndex - 1].replacingOccurrences(of: " ", with: "_")
            }
        }
        return nil
    }
    
    private func extractLocation(from context: String) -> String? {
        // Look for location names
        let locationKeywords = ["beach", "mountain", "city", "park", "lake", "ocean", "forest"]
        for keyword in locationKeywords {
            if context.lowercased().contains(keyword) {
                return keyword.capitalized
            }
        }
        return nil
    }
    
    private func extractTitle(from context: String) -> String? {
        // Extract first meaningful line or title
        let lines = context.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 5 && trimmed.count < 50 {
                return trimmed.replacingOccurrences(of: " ", with: "_")
            }
        }
        return nil
    }
    
    private func detectProgrammingLanguage(from context: String, fileExtension: String) -> String? {
        switch fileExtension.lowercased() {
        case "swift": return "Swift"
        case "py": return "Python"
        case "js": return "JavaScript"
        case "ts": return "TypeScript"
        case "java": return "Java"
        case "cpp", "cc": return "CPP"
        case "c": return "C"
        case "go": return "Go"
        case "rs": return "Rust"
        case "rb": return "Ruby"
        case "php": return "PHP"
        default:
            // Try to detect from content
            if context.contains("func ") || context.contains("var ") || context.contains("let ") {
                return "Swift"
            } else if context.contains("def ") || context.contains("import ") {
                return "Python"
            } else if context.contains("function ") || context.contains("const ") {
                return "JavaScript"
            }
            return nil
        }
    }
    
    private func loadHistory() {
        if let data = try? Data(contentsOf: historyPath) {
            renameHistory = (try? JSONDecoder().decode([RenameHistory].self, from: data)) ?? []
        }
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(renameHistory) {
            try? data.write(to: historyPath)
        }
    }
    
    func clearHistory() {
        renameHistory.removeAll()
        saveHistory()
    }
}