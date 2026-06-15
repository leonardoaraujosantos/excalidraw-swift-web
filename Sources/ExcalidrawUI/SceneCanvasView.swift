import ExcalidrawModel
import ExcalidrawRender
import SwiftUI

/// Renders an Excalidraw `Scene` with the hand-drawn look using a SwiftUI
/// `Canvas` bridged to the Core Graphics `SceneRenderer` via `withCGContext`.
///
/// Includes basic view-only pan (drag) and zoom (pinch). The full interaction
/// loop — tools, selection, Apple Pencil — is Phase 3.
public struct SceneCanvasView: View {
    private let scene: ExcalidrawModel.Scene
    private let renderer = SceneRenderer()

    @State private var viewport: Viewport
    @State private var gestureScroll: CGSize = .zero
    @State private var gestureZoom: Double = 1

    public init(scene: ExcalidrawModel.Scene, viewport: Viewport = Viewport()) {
        self.scene = scene
        _viewport = State(initialValue: viewport)
    }

    public var body: some View {
        Canvas { context, size in
            context.withCGContext { cg in
                renderer.render(scene, in: cg, viewport: liveViewport, size: size)
            }
        }
        .accessibilityIdentifier("excalidraw-canvas")
        .gesture(panGesture)
        .gesture(zoomGesture)
        .ignoresSafeArea()
    }

    /// The viewport with the in-flight gesture deltas applied.
    private var liveViewport: Viewport {
        var v = viewport
        v.zoom = clampZoom(viewport.zoom * gestureZoom)
        v.scrollX = viewport.scrollX + gestureScroll.width / v.zoom
        v.scrollY = viewport.scrollY + gestureScroll.height / v.zoom
        return v
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { gestureScroll = $0.translation }
            .onEnded { _ in
                viewport = liveViewport
                gestureScroll = .zero
            }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { gestureZoom = $0 }
            .onEnded { _ in
                viewport.zoom = clampZoom(viewport.zoom * gestureZoom)
                gestureZoom = 1
            }
    }

    private func clampZoom(_ value: Double) -> Double {
        min(max(value, ExcalidrawRender.zoomRange.lowerBound), ExcalidrawRender.zoomRange.upperBound)
    }
}
