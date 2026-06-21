import ExcalidrawEditor
import SwiftUI
import UniformTypeIdentifiers

/// Modal sheets presented by `EditorView`: the library grid, the chart values
/// input, and the Mermaid diagram input. Split out of `EditorView` to keep it
/// small.
extension EditorView {
    var librarySheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 12) {
                    ForEach(Array(model.library.enumerated()), id: \.offset) { index, _ in
                        Button { model.stampLibraryItem(index) } label: {
                            Group {
                                if let cg = model.libraryThumbnail(index) {
                                    Image(decorative: cg, scale: 1).resizable().scaledToFit()
                                } else {
                                    Image(systemName: "square.on.square")
                                }
                            }
                            .frame(width: 90, height: 90)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .accessibilityIdentifier("library-item-\(index)")
                    }
                }
                .padding()
                if model.library.isEmpty {
                    Text("Select elements and tap “Add” to build your library.")
                        .foregroundStyle(.secondary).padding()
                }
            }
            .navigationTitle("Library")
            .toolbar {
                Button("Add") { model.addSelectionToLibrary() }
                    .accessibilityIdentifier("library-add")
                Menu {
                    Button("Import…") { importingLibrary = true }
                    Button("Export…") { exportingLibrary = true }.disabled(model.library.isEmpty)
                } label: {
                    Image(systemName: "square.and.arrow.up.on.square")
                }.accessibilityIdentifier("library-share")
                Button("Done") { model.showLibrary = false }
            }
        }
        .fileImporter(isPresented: $importingLibrary, allowedContentTypes: [.json, .item]) { result in
            guard let url = try? result.get(), url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            if let data = try? Data(contentsOf: url) { try? model.importLibrary(data) }
        }
        .fileExporter(
            isPresented: $exportingLibrary,
            document: LibraryDocument(data: model.exportLibraryData() ?? Data()),
            contentType: .json,
            defaultFilename: "library.excalidrawlib"
        ) { _ in }
    }

    var chartInputSheet: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $model.chartKind) {
                    Text("Bar").tag(ChartKind.bar)
                    Text("Line").tag(ChartKind.line)
                }.pickerStyle(.segmented)
                Section("Values") {
                    TextField("e.g. 4, 8, 15, 16, 23, 42", text: $model.chartValuesText, axis: .vertical)
                        .accessibilityIdentifier("chart-values")
                }
            }
            .navigationTitle("Insert Chart")
            .toolbar {
                Button("Cancel") { model.showChartInput = false }
                Button("Insert") { model.commitChart() }.accessibilityIdentifier("chart-insert")
            }
        }
        .presentationDetents([.medium])
    }

    var mermaidInputSheet: some View {
        NavigationStack {
            Form {
                Section("Mermaid flowchart") {
                    TextField(
                        "flowchart TD\n  A[Start] --> B{OK?}\n  B -->|Yes| C[Go]",
                        text: $model.mermaidText,
                        axis: .vertical
                    )
                    .lineLimit(4 ... 12)
                    .font(.system(.body, design: .monospaced))
                    .accessibilityIdentifier("mermaid-text")
                }
            }
            .navigationTitle("Insert Diagram")
            .toolbar {
                Button("Cancel") { model.showMermaidInput = false }
                Button("Insert") { model.commitMermaid() }.accessibilityIdentifier("mermaid-insert")
            }
        }
        .presentationDetents([.medium])
    }
}
