import ExcalidrawModel
import ExcalidrawRender
import ExcalidrawUI
import SwiftUI

@main
struct ExcalidrawApp: App {
    var body: some SwiftUI.Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    private let scene = SampleScene.load()

    var body: some View {
        SceneCanvasView(scene: scene, viewport: Viewport(scrollX: 20, scrollY: 20, zoom: 1.4))
    }
}

/// Loads the bundled sample `.excalidraw` document, falling back to an empty
/// scene if it cannot be read. (A document browser arrives in Phase 5.)
enum SampleScene {
    static func load() -> ExcalidrawModel.Scene {
        guard let url = Bundle.main.url(forResource: "sample", withExtension: "excalidraw"),
              let data = try? Data(contentsOf: url),
              let file = try? ExcalidrawFile.decode(from: data) else {
            return ExcalidrawModel.Scene()
        }
        return ExcalidrawModel.Scene(file: Restore.restore(file))
    }
}
