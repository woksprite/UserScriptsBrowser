import SwiftUI
import WebKit
import UniformTypeIdentifiers

@main
struct UserScriptBrowserApp: App {
    @StateObject private var store = ScriptStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
