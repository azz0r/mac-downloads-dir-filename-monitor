import Foundation
import NaturalLanguage
import Vision
import PDFKit
import CoreML
import CreateML
import CoreImage

enum FileCategory: String, CaseIterable {
    case documents = "Documents"
    case invoices = "Invoices"
    case receipts = "Receipts"
    case screenshots = "Screenshots"
    case photos = "Photos"
    case vacationPhotos = "Vacation Photos"
    case videos = "Videos"
    case music = "Music"
    case downloads = "Downloads"
    case code = "Code"
    case presentations = "Presentations"
    case spreadsheets = "Spreadsheets"
    case archives = "Archives"
    case installers = "Installers"
    case unknown = "Misc"
}

class IntelligenceManager {
    private let textClassifier: NLTagger
    private var documentClassifier: VNCoreMLModel?
    private var imageClassifier: VNCoreMLModel?
    
    init() {
        // Initialize NLTagger for advanced text analysis
        textClassifier = NLTagger(tagSchemes: [.nameType, .lexicalClass, .language, .script])
        setupMLModels()
    }
    
    private func setupMLModels() {
        // Use Vision's built-in classification capabilities
        print("Setting up Apple Intelligence models...")
        
        // Vision classification is ready to use without setup
        print("Vision classification ready")
    }
    
    func extractContext(from url: URL) async -> String {
        let fileName = url.lastPathComponent.lowercased()
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return await extractPDFContextWithAI(at: url)
        case "jpg", "jpeg", "png", "heic", "gif", "bmp", "tiff":
            return await extractImageContextWithAI(at: url)
        case "txt", "rtf", "doc", "docx":
            return await extractTextContextWithAI(at: url)
        default:
            return fileName
        }
    }
    
    private func extractPDFContextWithAI(at url: URL) async -> String {
        guard let document = PDFDocument(url: url),
              let page = document.page(at: 0) else {
            return ""
        }
        
        // Extract text from PDF
        let text = page.string ?? ""
        
        // Use Natural Language Processing to understand content
        let context = await analyzeTextWithAI(text)
        return context
    }
    
    private func extractImageContextWithAI(at url: URL) async -> String {
        guard let image = NSImage(contentsOf: url),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return ""
        }
        
        var extractedContext = ""
        
        // Create multiple Vision requests for comprehensive analysis
        let requests = createVisionRequests()
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform(requests)
            
            // Process results from all Vision requests
            for request in requests {
                if let textRequest = request as? VNRecognizeTextRequest,
                   let observations = textRequest.results {
                    let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                    extractedContext += "Text: \(recognizedText) "
                }
                
                if let classifyRequest = request as? VNClassifyImageRequest,
                   let observations = classifyRequest.results {
                    let topClassifications = observations.prefix(3).map { "\($0.identifier): \($0.confidence)" }.joined(separator: ", ")
                    extractedContext += "Classifications: \(topClassifications) "
                }
                
                if let facesRequest = request as? VNDetectFaceRectanglesRequest,
                   let faces = facesRequest.results, faces.count > 0 {
                    extractedContext += "Contains \(faces.count) face(s) "
                }
            }
        } catch {
            print("Vision processing error: \(error)")
        }
        
        return extractedContext
    }
    
    private func createVisionRequests() -> [VNRequest] {
        var requests: [VNRequest] = []
        
        // Text recognition request - FAST mode for quicker processing
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .fast // Changed to fast for quicker processing
        textRequest.recognitionLanguages = ["en-US"]
        requests.append(textRequest)
        
        // Only essential requests to speed up processing
        // Skip saliency and document detection for now
        
        // Image classification request
        let classificationRequest = VNClassifyImageRequest()
        requests.append(classificationRequest)
        
        // Face detection for photos with people
        let faceRequest = VNDetectFaceRectanglesRequest()
        requests.append(faceRequest)
        
        return requests
    }
    
    private func extractTextContextWithAI(at url: URL) async -> String {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        
        return await analyzeTextWithAI(text)
    }
    
    private func analyzeTextWithAI(_ text: String) async -> String {
        // Use NaturalLanguage framework for advanced text analysis
        textClassifier.string = text
        
        var context = ""
        
        // Detect language
        if let language = NLLanguageRecognizer.dominantLanguage(for: text) {
            context += "Language: \(language.rawValue) "
        }
        
        // Extract named entities (people, places, organizations)
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]
        let tags = textClassifier.tags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options)
        
        var entities: [String: Set<String>] = [:]
        for (tag, range) in tags {
            if let tag = tag {
                let entity = String(text[range])
                if entities[tag.rawValue] == nil {
                    entities[tag.rawValue] = Set<String>()
                }
                entities[tag.rawValue]?.insert(entity)
            }
        }
        
        // Add found entities to context
        if let people = entities["PersonalName"], !people.isEmpty {
            context += "People: \(people.joined(separator: ", ")) "
        }
        if let orgs = entities["OrganizationName"], !orgs.isEmpty {
            context += "Organizations: \(orgs.joined(separator: ", ")) "
        }
        if let places = entities["PlaceName"], !places.isEmpty {
            context += "Places: \(places.joined(separator: ", ")) "
        }
        
        // Sentiment analysis
        let sentimentPredictor = NLTagger(tagSchemes: [.sentimentScore])
        sentimentPredictor.string = text
        
        if let sentiment = sentimentPredictor.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore).0 {
            context += "Sentiment: \(sentiment.rawValue) "
        }
        
        // Topic extraction using tokenization and lemmatization
        let tokenizer = NLTagger(tagSchemes: [.lemma])
        tokenizer.string = text
        
        var importantWords: [String] = []
        tokenizer.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma, options: options) { tag, range in
            if let lemma = tag?.rawValue {
                let word = String(text[range])
                // Filter out common words
                if word.count > 4 && !isCommonWord(word.lowercased()) {
                    importantWords.append(lemma)
                }
            }
            return true
        }
        
        if !importantWords.isEmpty {
            let topWords = Array(Set(importantWords).prefix(5))
            context += "Keywords: \(topWords.joined(separator: ", ")) "
        }
        
        // Add first meaningful line if available
        let lines = text.components(separatedBy: .newlines)
        if let firstLine = lines.first(where: { $0.count > 10 && $0.count < 100 }) {
            context += "Title: \(firstLine) "
        }
        
        return context
    }
    
    private func isCommonWord(_ word: String) -> Bool {
        let commonWords = ["the", "and", "for", "are", "with", "this", "that", "have", "from", "will", "your", "which", "their", "been", "would", "there", "could", "where", "these", "those"]
        return commonWords.contains(word)
    }
    
    func analyzeFile(at url: URL) async -> FileCategory {
        let fileName = url.lastPathComponent.lowercased()
        let fileExtension = url.pathExtension.lowercased()
        let context = await extractContext(from: url)
        
        // Use AI context to determine category
        if context.contains("invoice") || context.contains("bill") || context.contains("payment due") {
            return .invoices
        }
        
        if context.contains("receipt") || context.contains("transaction") || context.contains("purchase") {
            return .receipts
        }
        
        if fileName.contains("screenshot") || context.contains("screenshot") {
            return .screenshots
        }
        
        if context.contains("vacation") || context.contains("holiday") || context.contains("beach") || context.contains("mountain") || context.contains("Landscape photo") {
            return .vacationPhotos
        }
        
        if context.contains("face") || context.contains("people:") {
            return .photos
        }
        
        // Check for code patterns
        if detectCodePatterns(in: context) || ["py", "js", "swift", "java", "cpp", "c", "go", "rs"].contains(fileExtension) {
            return .code
        }
        
        // Fallback to extension-based categorization
        return categorizeByExtension(fileExtension)
    }
    
    private func detectCodePatterns(in text: String) -> Bool {
        let codePatterns = [
            "function\\s+\\w+\\s*\\(",
            "class\\s+\\w+",
            "import\\s+\\w+",
            "var\\s+\\w+\\s*=",
            "let\\s+\\w+\\s*=",
            "const\\s+\\w+\\s*=",
            "if\\s*\\(",
            "for\\s*\\(",
            "while\\s*\\(",
            "def\\s+\\w+\\s*\\(",
            "public\\s+class",
            "private\\s+\\w+"
        ]
        
        for pattern in codePatterns {
            if let _ = text.range(of: pattern, options: .regularExpression) {
                return true
            }
        }
        
        return false
    }
    
    func categorizeByExtension(_ ext: String) -> FileCategory {
        switch ext {
        case "doc", "docx", "txt", "rtf", "odt":
            return .documents
        case "pdf":
            return .documents
        case "xls", "xlsx", "csv", "numbers":
            return .spreadsheets
        case "ppt", "pptx", "key":
            return .presentations
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "raw":
            return .photos
        case "mp4", "avi", "mov", "wmv", "flv", "mkv":
            return .videos
        case "mp3", "wav", "flac", "aac", "m4a":
            return .music
        case "zip", "rar", "tar", "gz", "7z":
            return .archives
        case "dmg", "pkg", "app", "exe", "msi":
            return .installers
        case "swift", "py", "js", "ts", "java", "cpp", "c", "h", "m", "go", "rs":
            return .code
        default:
            return .unknown
        }
    }
    
    func generateIntelligentName(for url: URL, context: String, category: FileCategory) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        var components: [String] = []
        
        // For images, extract AI classifications
        if context.contains("Classifications:") {
            if let classRange = context.range(of: "Classifications: ([^\\n]+)", options: .regularExpression) {
                let classifications = String(context[classRange])
                    .replacingOccurrences(of: "Classifications: ", with: "")
                    .components(separatedBy: ", ")
                    .compactMap { item -> String? in
                        let parts = item.components(separatedBy: ": ")
                        if parts.count == 2, let confidence = Float(parts[1]), confidence > 0.5 {
                            return parts[0].replacingOccurrences(of: " ", with: "_")
                        }
                        return nil
                    }
                    .prefix(2)  // Take top 2 classifications
                
                if !classifications.isEmpty {
                    components.append(contentsOf: classifications)
                }
            }
        }
        
        // Extract meaningful text snippets
        if context.contains("Text:") {
            if let textRange = context.range(of: "Text: ([^\\n]+)", options: .regularExpression) {
                let extractedText = String(context[textRange])
                    .replacingOccurrences(of: "Text: ", with: "")
                
                // Extract key words from text (prioritize capitalized words)
                let words = extractedText.components(separatedBy: .whitespacesAndNewlines)
                let meaningfulWords = words.filter { word in
                    !word.isEmpty && word.first?.isUppercase == true && word.count > 3 && word.count < 15
                }
                .prefix(3)
                .joined(separator: "_")
                
                if !meaningfulWords.isEmpty {
                    components.append(meaningfulWords)
                }
            }
        }
        
        // If we still don't have enough info, use category
        if components.isEmpty {
            components.append(category.rawValue)
        }
        
        // Add date
        components.append(dateString)
        
        // Clean up and join
        let baseName = components.joined(separator: "_")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "'", with: "")
        
        return String(baseName.prefix(100)) // Limit length
    }
}