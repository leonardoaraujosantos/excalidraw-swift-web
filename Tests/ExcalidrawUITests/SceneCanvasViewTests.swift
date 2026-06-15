import ExcalidrawModel
import ExcalidrawRender
import SwiftUI
import XCTest
@testable import ExcalidrawUI

final class SceneCanvasViewTests: XCTestCase {
    func testConstructsAndProducesBody() {
        var base = BaseProperties(id: "r")
        base.width = 100; base.height = 60
        let scene = ExcalidrawModel.Scene(elements: [ExcalidrawElement(base: base, kind: .rectangle)])
        let view = SceneCanvasView(scene: scene, viewport: Viewport(scrollX: 5, scrollY: 5, zoom: 2))
        _ = view.body
    }
}
