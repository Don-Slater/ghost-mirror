import SwiftUI

enum MirrorTheme {
    static let border = Color.black.opacity(0.98)
    static let glossTop = Color(white: 0.15)
    static let glossMid = Color(white: 0.055)
    static let glossBottom = Color(white: 0.015)
    static let label = Color.white.opacity(0.92)
    static let muted = Color.white.opacity(0.46)
    static let line = Color.white.opacity(0.13)
    static let buttonFill = Color.white.opacity(0.075)
    static let buttonFillProminent = Color.white.opacity(0.15)
    static let buttonStroke = Color.white.opacity(0.24)
    static let buttonStrokeProminent = Color.white.opacity(0.36)
    static let fieldFill = Color.black.opacity(0.34)
}

struct GlossyBlackFrame<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    MirrorTheme.glossTop,
                    MirrorTheme.glossMid,
                    MirrorTheme.glossBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.10),
                        Color.white.opacity(0.025),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(height: 1)
                    .allowsHitTesting(false)
            }

            content
        }
        .overlay {
            Rectangle()
                .strokeBorder(MirrorTheme.border, lineWidth: 1)
                .allowsHitTesting(false)
        }
        .background(Color.black)
    }
}

struct MirrorActionButton: View {
    let title: String
    var prominent = false
    var width: CGFloat = 118
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MirrorTheme.label)
                .lineLimit(1)
                .frame(width: width, height: 38)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(prominent ? MirrorTheme.buttonFillProminent : MirrorTheme.buttonFill)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(prominent ? MirrorTheme.buttonStrokeProminent : MirrorTheme.buttonStroke, lineWidth: 1)
                        }
                        .overlay(alignment: .top) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(prominent ? 0.16 : 0.08), lineWidth: 1)
                                .blur(radius: 0.2)
                        }
                }
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .opacity(isEnabled ? 1 : 0.38)
    }
}

struct MirrorField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var secure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(MirrorTheme.muted)
            Group {
                if secure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(MirrorTheme.fieldFill)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(MirrorTheme.line, lineWidth: 1)
                    }
            }
            .foregroundStyle(MirrorTheme.label)
        }
    }
}
