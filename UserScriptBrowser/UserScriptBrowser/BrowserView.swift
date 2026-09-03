import SwiftUI
import WebKit

struct BrowserView: UIViewRepresentable {
    @Binding var urlText: String
    @Binding var reloadToken: UUID
    let scripts: [UserScript]

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: BrowserView

        init(parent: BrowserView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let url = webView.url else { return }
            parent.urlText = url.absoluteString

            let applicable = parent.scripts.filter { $0.matches(url: url) }
            for script in applicable {
                webView.evaluateJavaScript(Self.wrapper(for: script.source)) { _, error in
                    if let error {
                        print("Userscript error (\(script.name)): \(error)")
                    }
                }
            }
        }

        static func wrapper(for source: String) -> String {
            let shim = """
            (() => {
              if (!window.__USB_GM__) {
                window.__USB_GM__ = true;

                window.GM_addStyle = function(css) {
                  const s = document.createElement('style');
                  s.textContent = css;
                  (document.head || document.documentElement).appendChild(s);
                  return s;
                };

                window.GM_setValue = function(key, value) {
                  try { localStorage.setItem('__gm__' + key, JSON.stringify(value)); } catch(e) {}
                };

                window.GM_getValue = function(key, fallback) {
                  try {
                    const v = localStorage.getItem('__gm__' + key);
                    return v === null ? fallback : JSON.parse(v);
                  } catch(e) { return fallback; }
                };

                window.GM_deleteValue = function(key) {
                  try { localStorage.removeItem('__gm__' + key); } catch(e) {}
                };

                window.GM_listValues = function() {
                  const out = [];
                  for (let i = 0; i < localStorage.length; i++) {
                    const k = localStorage.key(i);
                    if (k && k.startsWith('__gm__')) out.push(k.slice(6));
                  }
                  return out;
                };

                window.GM_openInTab = function(url) {
                  window.open(url, '_blank');
                };

                window.GM = window.GM || {};
                window.GM.addStyle = async (css) => window.GM_addStyle(css);
                window.GM.setValue = async (k,v) => window.GM_setValue(k,v);
                window.GM.getValue = async (k,d) => window.GM_getValue(k,d);
                window.GM.deleteValue = async (k) => window.GM_deleteValue(k);
                window.GM.listValues = async () => window.GM_listValues();
              }
            })();
            """

            return """
            \(shim)
            try {
              (() => {
                \(source)
              })();
            } catch (e) {
              console.error('Userscript error:', e);
            }
            """
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.allowsBackForwardNavigationGestures = true

        if let url = normalizedURL(urlText) {
            web.load(URLRequest(url: url))
        }
        return web
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self

        if context.coordinator.parent.reloadToken == reloadToken {
            // State change is intentionally lightweight; navigation is controlled by ContentView.
        }
    }

    private func normalizedURL(_ input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), url.scheme != nil { return url }
        return URL(string: "https://" + trimmed)
    }
}

struct WebViewContainer: View {
    @Binding var urlText: String
    let scripts: [UserScript]

    @State private var reloadToken = UUID()
    @State private var webViewID = UUID()

    var body: some View {
        BrowserView(urlText: $urlText, reloadToken: $reloadToken, scripts: scripts)
            .id(webViewID)
    }

    func reload() {
        reloadToken = UUID()
    }
}
