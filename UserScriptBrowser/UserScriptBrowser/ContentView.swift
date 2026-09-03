import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var store: ScriptStore

    @State private var urlText = "https://example.com"
    @State private var showImporter = false
    @State private var showScripts = false
    @State private var browserID = UUID()

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    TextField("Website", text: $urlText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { browserID = UUID() }

                    Button("Go") {
                        browserID = UUID()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                BrowserView(
                    urlText: $urlText,
                    reloadToken: .constant(UUID()),
                    scripts: store.scripts
                )
                .id(browserID)
            }
            .navigationTitle("Userscript Browser")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showImporter = true
                    } label: {
                        Image(systemName: "plus")
                    }

                    Button {
                        showScripts = true
                    } label: {
                        Image(systemName: "scroll")
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.javaScript, .plainText],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    let gotAccess = url.startAccessingSecurityScopedResource()
                    defer { if gotAccess { url.stopAccessingSecurityScopedResource() } }

                    if let source = try? String(contentsOf: url, encoding: .utf8) {
                        store.add(source: source, name: url.deletingPathExtension().lastPathComponent)
                    }
                }
            case .failure(let error):
                print("Import failed: \(error)")
            }
        }
        .sheet(isPresented: $showScripts) {
            ScriptManagerView()
                .environmentObject(store)
        }
    }
}

struct ScriptManagerView: View {
    @EnvironmentObject private var store: ScriptStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if store.scripts.isEmpty {
                    ContentUnavailableView(
                        "No Scripts",
                        systemImage: "scroll",
                        description: Text("Tap + in the browser to import a .js or .user.js file.")
                    )
                }

                ForEach($store.scripts) { $script in
                    VStack(alignment: .leading, spacing: 5) {
                        Toggle(script.name, isOn: $script.enabled)
                            .font(.headline)

                        Text(script.matches.joined(separator: "\n"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
                .onDelete(perform: store.delete)
            }
            .navigationTitle("Scripts")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
