import Foundation
import SwiftUI

struct UserScript: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var source: String
    var enabled: Bool = true
    var matches: [String] = ["*://*/*"]

    static func from(source: String, fallbackName: String) -> UserScript {
        let meta = UserscriptMetadata.parse(source)
        return UserScript(
            name: meta.name ?? fallbackName,
            source: source,
            enabled: true,
            matches: meta.matches.isEmpty ? ["*://*/*"] : meta.matches
        )
    }

    func matches(url: URL) -> Bool {
        guard enabled else { return false }
        let s = url.absoluteString
        return matches.contains { MatchPattern.matches(pattern: $0, url: s) }
    }
}

enum UserscriptMetadata {
    struct Result {
        var name: String?
        var matches: [String] = []
    }

    static func parse(_ source: String) -> Result {
        var result = Result()
        var inBlock = false

        for rawLine in source.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.contains("==UserScript==") {
                inBlock = true
                continue
            }
            if line.contains("==/UserScript==") {
                break
            }
            guard inBlock else { continue }

            if line.hasPrefix("// @name ") {
                result.name = String(line.dropFirst("// @name ".count)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("// @match ") {
                let value = String(line.dropFirst("// @match ".count)).trimmingCharacters(in: .whitespaces)
                if !value.isEmpty { result.matches.append(value) }
            } else if line.hasPrefix("// @include ") {
                let value = String(line.dropFirst("// @include ".count)).trimmingCharacters(in: .whitespaces)
                if !value.isEmpty { result.matches.append(value) }
            }
        }
        return result
    }
}

enum MatchPattern {
    static func matches(pattern: String, url: String) -> Bool {
        if pattern == "<all_urls>" || pattern == "*://*/*" { return true }

        // Convert a simple userscript-style wildcard pattern into regex.
        var regex = NSRegularExpression.escapedPattern(for: pattern)
        regex = regex.replacingOccurrences(of: "\\*", with: ".*")
        regex = "^" + regex + "$"

        return url.range(of: regex, options: .regularExpression) != nil
    }
}

@MainActor
final class ScriptStore: ObservableObject {
    @Published var scripts: [UserScript] = [] {
        didSet { save() }
    }

    private let key = "userscriptbrowser.scripts.v1"

    init() {
        load()
    }

    func add(source: String, name: String) {
        scripts.append(UserScript.from(source: source, fallbackName: name))
    }

    func delete(at offsets: IndexSet) {
        scripts.remove(atOffsets: offsets)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(scripts) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let saved = try? JSONDecoder().decode([UserScript].self, from: data)
        else { return }
        scripts = saved
    }
}
