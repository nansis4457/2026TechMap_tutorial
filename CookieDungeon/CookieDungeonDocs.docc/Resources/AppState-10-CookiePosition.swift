import ARKit
import RealityKit
import SwiftUI

@Observable
@MainActor
class AppState {
    private let session = ARKitSession()
    private let worldTracking = WorldTrackingProvider()
    private let roomTracking = RoomTrackingProvider()
    
    private(set) var worldSensingAuthorizationStatus: ARKitSession.AuthorizationStatus = .notDetermined
    
    // 모든 가상 콘텐츠의 루트
    let contentRoot = Entity()
    // 방 범위 지오메트리의 루트
    let roomRoot = Entity()
    
    private var roomAnchors = [UUID: RoomAnchor]()
    private var worldAnchors = [UUID: WorldAnchor]()
    private var cookieEntities = [UUID: ModelEntity]()
    private var roomEntities = [UUID: ModelEntity]()
    
    private var discoveredRoomIDs: [UUID] = []
    
    private let occlusionMaterial = OcclusionMaterial()
    
    private var currentRoomID: UUID?
    
    func requestWorldSensingAuthorization() async {
        let authorizationResult = await session.requestAuthorization(for: [.worldSensing])
        
        worldSensingAuthorizationStatus = authorizationResult[.worldSensing] ?? .notDetermined
    }
    
    func checkWorldSensingAuthorization() async {
        let authorizationResult = await session.queryAuthorization(for: [.worldSensing])
        
        worldSensingAuthorizationStatus = authorizationResult[.worldSensing] ?? .notDetermined
    }
    
    func runARKitSession() async {
        guard worldSensingAuthorizationStatus == .allowed else {
            print("worldSending 권한 없음")
            
            return
        }
        
        do {
            try await session.run([worldTracking, roomTracking])
            
            Task {
                await processRoomTrackingUpdates()
            }
            
        } catch {
            print("ARKit 세션 실행 중 오류 발생: \(error)")
        }
    }
    
    func processRoomTrackingUpdates() async {
        for await update in roomTracking.anchorUpdates {
            let roomAnchor = update.anchor
            
            switch update.event {
            case .removed:
                roomAnchors.removeValue(forKey: roomAnchor.id)
                roomEntities[roomAnchor.id]?.removeFromParent()
                roomEntities.removeValue(forKey: roomAnchor.id)
                
                cookieEntities[roomAnchor.id]?.removeFromParent()
                cookieEntities.removeValue(forKey: roomAnchor.id)
                
            case .added, .updated:
                roomAnchors[roomAnchor.id] = roomAnchor
                
                if !discoveredRoomIDs.contains(roomAnchor.id) {
                    discoveredRoomIDs.append(roomAnchor.id)
                }
                
                guard let roomMeshResource = roomAnchor.geometry.asMeshResource() else { continue }
                
                let bounds = roomMeshResource.bounds
                let localPosition = SIMD3<Float>(
                    bounds.center.x,
                    bounds.min.y + 0.1,
                    bounds.center.z
                )
                
                let worldPosition4 =
                roomAnchor.originFromAnchorTransform
                * SIMD4(localPosition, 1)
                
                let worldPosition = worldPosition4.xyz
                
                print("방 ID: \(roomAnchor.id)")
                print("쿠키 위치: \(worldPosition)")
                
                await placeCookie(at: worldPosition, for: roomAnchor.id)
                
                guard let roomMeshResource = roomAnchor.geometry.asMeshResource() else { continue }
                
                if update.event == .added {
                    let roomEntity = ModelEntity(mesh: roomMeshResource, materials: [occlusionMaterial])
                    roomEntity.transform = Transform(matrix: roomAnchor.originFromAnchorTransform)
                    roomEntities[roomAnchor.id] = roomEntity
                    roomEntity.isEnabled = roomAnchor.isCurrentRoom
                    roomRoot.addChild(roomEntity)
                    print("방 추가됨")
                } else if update.event == .updated {
                    guard let roomEntity = roomEntities[roomAnchor.id] else { continue }
                    roomEntity.model?.mesh = roomMeshResource
                    roomEntity.transform = Transform(matrix: roomAnchor.originFromAnchorTransform)
                    roomEntity.isEnabled = roomAnchor.isCurrentRoom
                    print("방 업데이트됨")
                }
                
                if roomAnchor.isCurrentRoom {
                    currentRoomID = roomAnchor.id
                }
            }
        }
    }
    
    func monitorAuthorizationUpdates() async {
        for await event in session.events {
            guard case let .authorizationChanged(type, status) = event, type == .worldSensing else { continue }
            
            worldSensingAuthorizationStatus = status
            print("World Sensing 권한 변경: \(status)")
        }
    }
}
