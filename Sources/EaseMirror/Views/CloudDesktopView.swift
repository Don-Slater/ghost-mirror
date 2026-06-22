import SwiftUI
import WebKit

struct CloudDesktopView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Ghost Mirror Cloud", systemImage: "rectangle.on.rectangle.angled")
                    .font(.headline)
                Spacer()
                Text("Linux · XFCE · VNC")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Done") { dismiss() }
            }
            .padding(10)
            .background(.bar)

            CloudDesktopWebView(url: url)
        }
        .frame(minWidth: 1024, minHeight: 680)
    }
}

struct CloudDesktopWebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        let view = WKWebView(frame: .zero, configuration: config)
        view.load(URLRequest(url: url))
        return view
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
