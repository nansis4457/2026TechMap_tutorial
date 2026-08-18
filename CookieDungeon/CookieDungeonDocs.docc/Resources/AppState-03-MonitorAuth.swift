import ARKit
import RealityKit
import SwiftUI

@Observable
@MainActor
class AppState {
    private let session = ARKitSession()
    
    private(set) var worldSensingAuthorizationStatus: ARKitSession.AuthorizationStatus = .notDetermined
    
    // 모든 가상 콘텐츠의 루트
    let contentRoot = Entity()
    
    func requestWorldSensingAuthorization() async {
        let authorizationResult = await session.requestAuthorization(for: [.worldSensing])
        
        worldSensingAuthorizationStatus = authorizationResult[.worldSensing] ?? .notDetermined
    }
    
    func checkWorldSensingAuthorization() async {
        let authorizationResult = await session.queryAuthorization(for: [.worldSensing])
        
        worldSensingAuthorizationStatus = authorizationResult[.worldSensing] ?? .notDetermined
    }
    
    func monitorAuthorizationUpdates() async {
        for await event in session.events {
            guard case let .authorizationChanged(type, status) = event, type == .worldSensing else { continue }
            
            worldSensingAuthorizationStatus = status
            print("World Sensing 권한 변경: \(status)")
        }
    }
}
