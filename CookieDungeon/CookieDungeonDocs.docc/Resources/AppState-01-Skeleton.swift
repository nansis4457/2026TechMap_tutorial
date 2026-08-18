import ARKit
import RealityKit
import SwiftUI

@Observable
@MainActor
class AppState {
    private let session = ARKitSession()
    
    // 모든 가상 콘텐츠의 루트
    let contentRoot = Entity()
}
