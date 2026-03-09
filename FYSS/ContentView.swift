//
//  ContentView.swift
//  FYSS
//
//  Created by vitriol towards YouTube's share sheet and AI on 08/03/26.
//

import SwiftUI

// MARK: - Main view

/// The app's single screen: configuration at the top, activity log at the bottom.
struct ContentView: View {

    /// The URL handler injected from `FYSSApp`, used to read last-activity state.
    @Environment(URLHandler.self) private var urlHandler

    /// Used to adapt the navigation title length to the available horizontal space
    /// (compact = iPhone, regular = iPad).
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// The base URL to which the extracted YouTube link is appended before opening.
    /// Persisted via `UserDefaults` under the key `targetURL`.
    @AppStorage("targetURL") private var targetURL: String = "unwatched://queue?url="

    /// When true, the forwarding URL is constructed using Shortcuts' x-callback-url scheme
    /// so that the Shortcuts app reopens YouTube after the shortcut completes.
    /// Persisted via `UserDefaults` under the key `returnToYouTube`.
    @AppStorage("returnToYouTube") private var returnToYouTube: Bool = false

    /// Controls visibility of the Unwatched setup sheet.
    @State private var showUnwatchedSheet = false

    /// Controls visibility of the intercepted-scheme info sheet.
    @State private var showSchemeInfoSheet = false

    /// The first non-fyss URL scheme registered in Info.plist — the scheme FYSS intercepts.
    ///
    /// Read at runtime from `CFBundleURLTypes` so that it stays accurate if the user changes
    /// the registered scheme in Xcode without touching the Swift code.
    private var interceptedScheme: String {
        let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]]
        return urlTypes?
            .compactMap { ($0["CFBundleURLSchemes"] as? [String])?.first }
            .first(where: { $0 != "fyss" }) ?? "tg"
    }

    var body: some View {
        NavigationStack {
            List {

                // MARK: Description

                Section {
                    Text("YouTube decided its share sheet should be better than the one Apple spent years perfecting. FYSS disagrees. It pretends to be Telegram — intercepting YouTube's \(interceptedScheme):// handshake — and sends video links wherever you actually want them to go.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .listRowBackground(Color.clear)
                }

                // MARK: Intercepted scheme

                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Intercepted Scheme", systemImage: "link.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(interceptedScheme)://")
                                .font(.system(.body, design: .monospaced))
                        }
                        Spacer()
                        // Info button opens a sheet explaining the scheme and how to change it.
                        Button {
                            showSchemeInfoSheet = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }

                // MARK: Target URL

                Section {
                    // axis: .vertical allows the field to grow to multiple lines on narrow screens.
                    TextField(
                        "e.g. unwatched://queue?url=",
                        text: $targetURL,
                        axis: .vertical
                    )
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    #endif

                    Toggle("Return to YouTube after forwarding", isOn: $returnToYouTube)
                } header: {
                    Label("Target URL", systemImage: "arrow.turn.up.right")
                } footer: {
                    Button {
                        showUnwatchedSheet = true
                    } label: {
                        Text("Show me how to use FYSS with Unwatched")
                            .font(.footnote)
                    }
                    .padding(.top, 6)
                }

                // MARK: Last activity

                Section {
                    URLRow(label: "Received", value: urlHandler.lastReceivedURL, icon: "arrow.down.circle", copyable: false)
                    URLRow(label: "Extracted", value: urlHandler.lastExtractedURL, icon: "scissors", copyable: true)
                    ResultRow(result: urlHandler.lastForwardResult)
                } header: {
                    Label("Last Activity", systemImage: "clock")
                }
            }
            .navigationTitle(horizontalSizeClass == .compact ? "FYSS 🤬" : "F🤬🤬k YouTube Share Sheet")
        }
        .sheet(isPresented: $showUnwatchedSheet) {
            UnwatchedSheet(targetURL: $targetURL)
        }
        .sheet(isPresented: $showSchemeInfoSheet) {
            SchemeInfoSheet(scheme: interceptedScheme)
        }
    }
}

// MARK: - Unwatched sheet

/// Sheet explaining how to use FYSS with Unwatched, with a one-tap setup button.
private struct UnwatchedSheet: View {

    /// Binding to the parent's `targetURL` so the setup button can write the Unwatched URL directly.
    @Binding var targetURL: String

    @Environment(\.dismiss) private var dismiss

    /// The direct URL scheme for adding a video to Unwatched's queue.
    private let unwatchedTargetURL = "unwatched://queue?url="

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Unwatched is a native iOS and visionOS YouTube client. FYSS can send video links directly to Unwatched using its built-in URL scheme.")
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section("Setup") {
                    // Writes the Unwatched target URL and closes the sheet in one tap.
                    Button {
                        targetURL = unwatchedTargetURL
                        dismiss()
                    } label: {
                        Label("Use Unwatched as target", systemImage: "checkmark.circle")
                    }
                }

                Section {
                    Text("FYSS is not affiliated with Unwatched!")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("FYSS with Unwatched")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Scheme info sheet

/// Sheet explaining what the intercepted scheme is and how to swap it in Xcode.
private struct SchemeInfoSheet: View {

    /// The URL scheme currently registered in Info.plist (e.g. `tg`).
    let scheme: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("FYSS is currently registered to intercept **\(scheme)://** URLs — the ones YouTube opens when you tap its Telegram button in the share sheet.")
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section("Changing the intercepted scheme") {
                    Text("If you have Telegram installed, iOS routes \(scheme):// to it and FYSS never sees the URL. In that case, pick a different app from YouTube's guest list whose app you don't have installed.\n\nTo swap the scheme, open **FYSS/Info.plist** in Xcode and replace `\(scheme)` with your chosen scheme under CFBundleURLSchemes.")
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section("YouTube's chosen ones") {
                    Text("We are aware of **tg://** (Telegram) and **reddit://** (Reddit) as URL schemes YouTube has graced with a button. It is entirely possible that Google has extended further privileges to other apps we don't know about. If you find one, consider opening an issue on GitHub.")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .navigationTitle("Intercepted Scheme")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Row subviews

/// A list row displaying a labelled URL string, optionally selectable for copying.
private struct URLRow: View {

    /// The label shown above the value (e.g. "Received", "Extracted").
    let label: String

    /// The URL string to display, or empty string when no value is available yet.
    let value: String

    /// SF Symbol name used in the label.
    let icon: String

    /// When `true`, the user can long-press to select and copy the displayed text.
    let copyable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            // `.textSelection` cannot be toggled with a ternary expression because
            // `.enabled` and `.disabled` are distinct concrete types, incompatible
            // in a conditional expression. An explicit if/else is required.
            if copyable {
                Text(value.isEmpty ? "None" : value)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(value.isEmpty ? .tertiary : .primary)
                    .textSelection(.enabled)
            } else {
                Text(value.isEmpty ? "None" : value)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(value.isEmpty ? .tertiary : .primary)
            }
        }
        .padding(.vertical, 2)
    }
}

/// A list row displaying the result of the last forwarding attempt with a dynamic icon and colour.
private struct ResultRow: View {

    /// The result string from the last forwarding attempt, or empty if none has occurred.
    let result: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Result", systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(result.isEmpty ? "None" : result)
                .font(.footnote)
                .foregroundStyle(color)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }

    /// `true` when the result string begins with "Error".
    private var isError: Bool { result.hasPrefix("Error") }

    /// SF Symbol name reflecting the current result state.
    private var icon: String {
        if result.isEmpty { return "minus.circle" }
        return isError ? "xmark.circle" : "checkmark.circle"
    }

    /// Text colour reflecting the current result state.
    private var color: Color {
        if result.isEmpty { return .secondary }
        return isError ? .red : .green
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(URLHandler())
}
