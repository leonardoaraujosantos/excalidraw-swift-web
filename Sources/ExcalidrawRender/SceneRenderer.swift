import CoreGraphics
import ExcalidrawGeometry
import ExcalidrawMath
import ExcalidrawModel
import Foundation
import RoughKit

/// Maps scene coordinates to view coordinates given the current pan/zoom.
///
/// Single source of truth for the canvas transform: render, hit-testing, and
/// snapping all derive from a `Viewport`. Mirrors the scroll/zoom model in
/// `packages/excalidraw/renderer/staticScene.ts`.
public struct Viewport: Equatable, Sendable {
    public var scrollX: Double
    public var scrollY: Double
    public var zoom: Double

    public init(scrollX: Double = 0, scrollY: Double = 0, zoom: Double = 1) {
        self.scrollX = scrollX
        self.scrollY = scrollY
        self.zoom = zoom
    }

    public func sceneToView(_ point: Point) -> Point {
        Point((point.x + scrollX) * zoom, (point.y + scrollY) * zoom)
    }

    public func viewToScene(_ point: Point) -> Point {
        Point(point.x / zoom - scrollX, point.y / zoom - scrollY)
    }

    /// Affine transform applied to the static canvas before drawing elements.
    public var affineTransform: CGAffineTransform {
        CGAffineTransform(scaleX: zoom, y: zoom)
            .translatedBy(x: scrollX, y: scrollY)
    }
}

public enum ExcalidrawRender {
    public static let zoomRange: ClosedRange<Double> = 0.1...30
}

/// Renders a scene's static content (background, grid, elements) into a
/// `CGContext`. Assumes a y-down context (SwiftUI `Canvas` via `withCGContext`,
/// a UIKit view, or `UIGraphicsImageRenderer`). Ports the flow of
/// `packages/excalidraw/renderer/staticScene.ts`.
public final class SceneRenderer {
    private let shapeCache: ShapeCache
    private let imageDecoder: ImageDecoder

    public init(shapeCache: ShapeCache = ShapeCache(), imageDecoder: ImageDecoder = ImageDecoder()) {
        self.shapeCache = shapeCache
        self.imageDecoder = imageDecoder
    }

    public func render(_ scene: Scene, in ctx: CGContext, viewport: Viewport, size: CGSize) {
        // Background.
        let background = scene.appState.viewBackgroundColor.flatMap(ColorParser.cgColor)
            ?? CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        ctx.setFillColor(background)
        ctx.fill(CGRect(origin: .zero, size: size))

        ctx.saveGState()
        ctx.scaleBy(x: viewport.zoom, y: viewport.zoom)
        ctx.translateBy(x: viewport.scrollX, y: viewport.scrollY)

        if scene.appState.gridModeEnabled == true {
            drawGrid(in: ctx, viewport: viewport, size: size)
        }

        for element in scene.visibleElements {
            drawElement(element, in: ctx, files: scene.files)
        }
        ctx.restoreGState()
    }

    private func drawElement(_ element: ExcalidrawElement, in ctx: CGContext, files: [String: BinaryFileData]) {
        let base = element.base
        ctx.saveGState()
        defer { ctx.restoreGState() }

        ctx.translateBy(x: base.x, y: base.y)
        // Rotate about the element's local centre.
        let cx = base.width / 2, cy = base.height / 2
        if base.angle != 0 {
            ctx.translateBy(x: cx, y: cy)
            ctx.rotate(by: CGFloat(base.angle))
            ctx.translateBy(x: -cx, y: -cy)
        }
        ctx.setAlpha(CGFloat(base.opacity / 100))

        switch element.kind {
        case let .text(text):
            let color = ColorParser.cgColor(base.strokeColor) ?? CGColor(red: 0, green: 0, blue: 0, alpha: 1)
            TextLayout.draw(text, base: base, in: ctx, color: color)
        case let .image(image):
            drawImage(image, base: base, in: ctx, files: files)
        case let .freedraw(props):
            drawFreedraw(props, base: base, in: ctx)
        default:
            if let drawable = shapeCache.drawable(for: element) {
                drawDrawable(drawable, base: base, in: ctx)
            }
        }
    }

    private func drawDrawable(_ drawable: Drawable, base: BaseProperties, in ctx: CGContext) {
        let strokeColor = ColorParser.cgColor(base.strokeColor) ?? CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        let fillColor = drawable.options.fill.flatMap(ColorParser.cgColor)

        for set in drawable.sets {
            let path = RoughPath.cgPath(from: set.ops)
            switch set.type {
            case .fillPath:
                if let fillColor {
                    ctx.addPath(path)
                    ctx.setFillColor(fillColor)
                    ctx.fillPath()
                }
            case .fillSketch:
                if let fillColor {
                    ctx.addPath(path)
                    ctx.setStrokeColor(fillColor)
                    let weight = drawable.options.fillWeight > 0 ? drawable.options.fillWeight : base.strokeWidth / 2
                    ctx.setLineWidth(CGFloat(weight))
                    ctx.setLineDash(phase: 0, lengths: [])
                    ctx.strokePath()
                }
            case .path:
                ctx.addPath(path)
                ctx.setStrokeColor(strokeColor)
                ctx.setLineWidth(CGFloat(base.strokeWidth))
                ctx.setLineCap(.round)
                ctx.setLineJoin(.round)
                applyDash(drawable.options.strokeLineDash, in: ctx)
                ctx.strokePath()
            }
        }
    }

    private func drawFreedraw(_ props: FreedrawProperties, base: BaseProperties, in ctx: CGContext) {
        guard let first = props.points.first else { return }
        let strokeColor = ColorParser.cgColor(base.strokeColor) ?? CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: first.x, y: first.y))
        for p in props.points.dropFirst() { path.addLine(to: CGPoint(x: p.x, y: p.y)) }
        ctx.addPath(path)
        ctx.setStrokeColor(strokeColor)
        ctx.setLineWidth(CGFloat(base.strokeWidth))
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.strokePath()
    }

    private func drawImage(
        _ image: ImageProperties, base: BaseProperties, in ctx: CGContext, files: [String: BinaryFileData]
    ) {
        guard let fileId = image.fileId, let file = files[fileId],
              let cgImage = imageDecoder.image(fileId: fileId, dataURL: file.dataURL) else { return }
        // CGContext.draw flips images in a y-down context; flip back so it is upright.
        let rect = CGRect(x: 0, y: 0, width: base.width, height: base.height)
        ctx.saveGState()
        ctx.translateBy(x: 0, y: base.height)
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(cgImage, in: rect)
        ctx.restoreGState()
    }

    private func drawGrid(in ctx: CGContext, viewport: Viewport, size: CGSize) {
        let gridSize = 20.0
        ctx.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.1))
        ctx.setLineWidth(1 / viewport.zoom)
        let path = CGMutablePath()
        // Visible scene bounds.
        let topLeft = viewport.viewToScene(Point(0, 0))
        let bottomRight = viewport.viewToScene(Point(size.width, size.height))
        var x = (topLeft.x / gridSize).rounded(.down) * gridSize
        while x <= bottomRight.x {
            path.move(to: CGPoint(x: x, y: topLeft.y))
            path.addLine(to: CGPoint(x: x, y: bottomRight.y))
            x += gridSize
        }
        var y = (topLeft.y / gridSize).rounded(.down) * gridSize
        while y <= bottomRight.y {
            path.move(to: CGPoint(x: topLeft.x, y: y))
            path.addLine(to: CGPoint(x: bottomRight.x, y: y))
            y += gridSize
        }
        ctx.addPath(path)
        ctx.strokePath()
    }

    private func applyDash(_ dash: [Double]?, in ctx: CGContext) {
        if let dash, !dash.isEmpty {
            ctx.setLineDash(phase: 0, lengths: dash.map { CGFloat($0) })
        } else {
            ctx.setLineDash(phase: 0, lengths: [])
        }
    }
}
