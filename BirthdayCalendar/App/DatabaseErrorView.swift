import SwiftUI

/// Shown when the SwiftData store fails to open (e.g. migration error).
/// Displays the full error so it can be reported / debugged.
struct DatabaseErrorView: View {
    let error: Error
    var diagnostics: String = ""

    @State private var copied = false

    private var errorText: String {
        """
        localizedDescription:
        \(error.localizedDescription)

        full error:
        \(String(describing: error))

        --- diagnostics ---
        \(diagnostics)
        """
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Database error")
                            .font(.title2.bold())
                        Text("Migration failed on launch")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("The app could not open your database. This is usually a SwiftData schema migration issue after an app update.")
                    .foregroundStyle(.secondary)

                Divider()

                Text("Error details")
                    .font(.headline)

                Text(errorText)
                    .font(.system(.caption, design: .monospaced))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .textSelection(.enabled)   // tap & hold to copy on device

                Button {
                    UIPasteboard.general.string = errorText
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                } label: {
                    Label(copied ? "Copied!" : "Copy error to clipboard",
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(copied ? .green : .orange)
            }
            .padding()
        }
        .navigationTitle("Startup Error")
    }
}
