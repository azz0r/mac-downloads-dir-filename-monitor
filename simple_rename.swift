#!/usr/bin/env swift

import Foundation
import Vision
import AppKit
import NaturalLanguage

let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!

// Get ALL files in Downloads
let files = try! FileManager.default.contentsOfDirectory(at: downloadsPath, includingPropertiesForKeys: nil)

for file in files {
    // Skip directories
    var isDir: ObjCBool = false
    guard FileManager.default.fileExists(atPath: file.path, isDirectory: &isDir), !isDir.boolValue else { continue }
    
    let fileName = file.lastPathComponent
    let ext = file.pathExtension
    
    // Skip if already renamed by us
    if fileName.contains("_2025-") { 
        print("Skipping already renamed: \(fileName)")
        continue 
    }
    
    print("Processing: \(fileName)")
    
    var description = ""
    
    // For images - use Vision to DESCRIBE the image content
    if ["png", "jpg", "jpeg", "heic", "gif"].contains(ext.lowercased()) {
        if let image = NSImage(contentsOf: file),
           let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            
            var descriptions: [String] = []
            
            // Image classification - what's IN the image
            let classifyRequest = VNClassifyImageRequest()
            
            // Text recognition - any text in the image
            let textRequest = VNRecognizeTextRequest()
            textRequest.recognitionLevel = .fast
            
            // Face detection
            let faceRequest = VNDetectFaceRectanglesRequest()
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([classifyRequest, textRequest, faceRequest])
            
            // Get image classifications (what the image contains)
            if let classifications = classifyRequest.results {
                let topItems = classifications.prefix(3)
                    .filter { $0.confidence > 0.3 }
                    .map { $0.identifier.replacingOccurrences(of: ", ", with: "_") }
                
                if !topItems.isEmpty {
                    descriptions.append(contentsOf: topItems)
                }
            }
            
            // Add face count if people in image
            if let faces = faceRequest.results, faces.count > 0 {
                descriptions.append("\(faces.count)_people")
            }
            
            // Add any text found
            if let textObs = textRequest.results {
                let text = textObs.prefix(3).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "_")
                if !text.isEmpty {
                    descriptions.append(text.prefix(20).description)
                }
            }
            
            // Combine all descriptions
            description = descriptions.joined(separator: "_")
                .replacingOccurrences(of: " ", with: "_")
                .prefix(80).description
        }
    }
    
    // For text files - read first line
    if ["txt", "md", "json"].contains(ext.lowercased()) {
        if let content = try? String(contentsOf: file).components(separatedBy: .newlines).first {
            description = content.prefix(30).replacingOccurrences(of: " ", with: "_")
        }
    }
    
    // Clean up description
    description = description
        .replacingOccurrences(of: "/", with: "-")
        .replacingOccurrences(of: ":", with: "-")
        .replacingOccurrences(of: "\"", with: "")
        .replacingOccurrences(of: "\n", with: "")
    
    // Generate new name
    let date = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none).replacingOccurrences(of: "/", with: "-")
    let category = ["png", "jpg", "jpeg", "heic", "gif"].contains(ext.lowercased()) ? "IMG" : "DOC"
    
    var baseName = description.isEmpty ? 
        "\(category)_\(date)" : 
        "\(category)_\(description)_\(date)"
    
    // Ensure unique name
    var counter = 1
    var newName = "\(baseName).\(ext)"
    var newURL = downloadsPath.appendingPathComponent(newName)
    
    while FileManager.default.fileExists(atPath: newURL.path) && newURL.path != file.path {
        newName = "\(baseName)_\(counter).\(ext)"
        newURL = downloadsPath.appendingPathComponent(newName)
        counter += 1
    }
    
    // Rename if different
    if newName != fileName {
        do {
            try FileManager.default.moveItem(at: file, to: newURL)
            print("✓ Renamed: \(fileName) → \(newName)")
        } catch {
            print("✗ Failed: \(fileName) - \(error.localizedDescription)")
        }
    }
}

print("\nDone!")