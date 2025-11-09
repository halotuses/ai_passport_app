import Foundation

struct ChapterMetadata: Codable, Identifiable, Hashable {
    struct WordPair: Codable, Hashable {
        let primary: String
        let secondary: String
        
        init(primary: String, secondary: String) {
            self.primary = primary
            self.secondary = secondary
        }
        
        init(from decoder: Decoder) throws {
            if let keyed = try? decoder.container(keyedBy: CodingKeys.self) {
                let primary = Self.decodeValue(
                    from: keyed,
                    keys: [
                        .primary, .prompt, .question, .native, .first, .front, .jp, .term, .kana, .left, .leftText, .source, .from, .text1
                    ]
                ) ?? ""
                let secondary = Self.decodeValue(
                    from: keyed,
                    keys: [
                        .secondary, .response, .answer, .translation, .second, .back, .en, .definition, .meaning, .right, .rightText, .target, .to, .text2
                    ]
                ) ?? ""
                self.init(primary: primary, secondary: secondary)
                return
            }
            
            if var unkeyed = try? decoder.unkeyedContainer() {
                let primary = (try? unkeyed.decode(String.self)) ?? ""
                let secondary = (try? unkeyed.decode(String.self)) ?? ""
                self.init(primary: primary, secondary: secondary)
                return
            }
            
            let single = try decoder.singleValueContainer()
            let value = (try? single.decode(String.self)) ?? ""
            self.init(primary: value, secondary: "")
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(primary, forKey: .primary)
            try container.encode(secondary, forKey: .secondary)
        }
        
        var isEffectivelyEmpty: Bool {
            primary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            secondary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        var displayText: String {
            let trimmedPrimary = primary.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedSecondary = secondary.trimmingCharacters(in: .whitespacesAndNewlines)
            
            switch (trimmedPrimary.isEmpty, trimmedSecondary.isEmpty) {
            case (false, false):
                return "\(trimmedPrimary) / \(trimmedSecondary)"
            case (false, true):
                return trimmedPrimary
            case (true, false):
                return trimmedSecondary
            default:
                return ""
            }
        }
        
        private static func decodeValue(
            from container: KeyedDecodingContainer<CodingKeys>,
            keys: [CodingKeys]
        ) -> String? {
            for key in keys {
                if let value = try? container.decodeIfPresent(String.self, forKey: key),
                   let unwrappedValue = value {
                    return unwrappedValue
                }
            }
            return nil
        }
        
        enum CodingKeys: String, CodingKey {
            case primary
            case secondary
            case prompt
            case response
            case question
            case answer
            case native
            case translation
            case first
            case second
            case front
            case back
            case jp
            case en
            case term
            case definition
            case kana
            case meaning
            case left
            case right
            case leftText
            case rightText
            case source
            case target
            case from
            case to
            case text1
            case text2
        }
    }
    
    let id: String
    let title: String
    let file: String
    let wordPair: WordPair?
    
    init(id: String, title: String, file: String, wordPair: WordPair? = nil) {
        self.id = id
        self.title = title
        self.file = file
        self.wordPair = wordPair
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case file
        case wordPair
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        file = try container.decode(String.self, forKey: .file)
        
        let decodedPair = try container.decodeIfPresent(WordPair.self, forKey: .wordPair)
        if let resolvedPair = decodedPair, !resolvedPair.isEffectivelyEmpty {
            wordPair = resolvedPair
        } else {
            wordPair = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(file, forKey: .file)
        if let wordPair, !wordPair.isEffectivelyEmpty {
            try container.encode(wordPair, forKey: .wordPair)
        }
    }
}
