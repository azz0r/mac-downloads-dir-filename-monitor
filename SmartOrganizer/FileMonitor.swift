import Foundation
import Combine

struct FileInfo {
    let url: URL
    let creationDate: Date?
    let size: Int64
    let type: String
}

class FileMonitor: ObservableObject {
    @Published var isMonitoring = false
    
    private var directoryWatcher: DirectoryWatcher?
    private let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    private var fileChangeHandler: (([FileInfo]) -> Void)?
    private var monitoringTimer: Timer?
    
    func startMonitoring(onChange: @escaping ([FileInfo]) -> Void) {
        print("Starting file monitoring for Downloads folder: \(downloadsURL.path)")
        self.fileChangeHandler = onChange
        self.isMonitoring = true
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            print("Timer fired - checking for new files...")
            self.checkForNewFiles()
        }
        
        print("Initial check for files...")
        checkForNewFiles()
    }
    
    func stopMonitoring() {
        self.isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        directoryWatcher?.stop()
    }
    
    func getEligibleFiles() -> [FileInfo] {
        // Try to use bookmarked URL if available
        var targetURL = downloadsURL
        
        if let bookmarkData = UserDefaults.standard.data(forKey: "DownloadsBookmark") {
            do {
                var isStale = false
                let bookmarkedURL = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                if !isStale {
                    _ = bookmarkedURL.startAccessingSecurityScopedResource()
                    targetURL = bookmarkedURL
                    print("Using bookmarked Downloads folder: \(targetURL.path)")
                }
            } catch {
                print("Failed to resolve bookmark: \(error)")
            }
        }
        
        print("Checking Downloads folder: \(targetURL.path)")
        guard let enumerator = FileManager.default.enumerator(
            at: targetURL,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey, .contentTypeKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { 
            print("Failed to create enumerator")
            return [] 
        }
        
        var eligibleFiles: [FileInfo] = []
        let fiveSecondsAgo = Date().addingTimeInterval(-5) // Changed to 5 seconds to avoid files being written
        print("Current time: \(Date())")
        print("Looking for files older than: \(fiveSecondsAgo)")
        
        var fileCount = 0
        for case let fileURL as URL in enumerator {
            fileCount += 1
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.creationDateKey, .fileSizeKey, .contentTypeKey, .isDirectoryKey])
                
                guard let isDirectory = resourceValues.isDirectory, !isDirectory else { 
                    print("Skipping directory: \(fileURL.lastPathComponent)")
                    continue 
                }
                
                let creationDate = resourceValues.creationDate
                print("File: \(fileURL.lastPathComponent), Creation date: \(creationDate?.description ?? "nil")")
                
                if let date = creationDate, date < fiveSecondsAgo {
                    let fileInfo = FileInfo(
                        url: fileURL,
                        creationDate: creationDate,
                        size: Int64(resourceValues.fileSize ?? 0),
                        type: resourceValues.contentType?.identifier ?? "unknown"
                    )
                    eligibleFiles.append(fileInfo)
                    print("Added eligible file: \(fileURL.lastPathComponent)")
                } else {
                    print("File too new or no date: \(fileURL.lastPathComponent)")
                }
            } catch {
                print("Error getting file info for \(fileURL.lastPathComponent): \(error)")
            }
        }
        
        print("Total files examined: \(fileCount), eligible: \(eligibleFiles.count)")
        return eligibleFiles
    }
    
    private func checkForNewFiles() {
        let files = getEligibleFiles()
        print("Found \(files.count) eligible files to check")
        if !files.isEmpty {
            for file in files {
                print("Eligible file: \(file.url.lastPathComponent)")
            }
            fileChangeHandler?(files)
        }
    }
}

class DirectoryWatcher {
    private var source: DispatchSourceFileSystemObject?
    private let url: URL
    private let queue = DispatchQueue(label: "com.smartorganizer.directorywatcher")
    
    init(url: URL) {
        self.url = url
    }
    
    func start(handler: @escaping () -> Void) {
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor != -1 else { return }
        
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .delete, .rename],
            queue: queue
        )
        
        source?.setEventHandler(handler: handler)
        source?.setCancelHandler {
            close(descriptor)
        }
        
        source?.resume()
    }
    
    func stop() {
        source?.cancel()
        source = nil
    }
}