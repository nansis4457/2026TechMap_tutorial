//
//  RoomDungeonManager.swift
//  RoomDungeon
//
//    ARKit 세션 실행 → 현재 방 감지(isCurrentRoom)
//    → 방 안의 한 점에 WorldAnchor를 추가해 몹 위치를 월드 공간에 고정하기
//    → 그 앵커를 방 id와 묶어(몹 ↔ 현재 방 연결) 입장 시 spawn / 퇴장 시 despawn



import ARKit          // ARKitSession, WorldTrackingProvider, WorldAnchor, RoomTrackingProvider, RoomAnchor
import RealityKit     // Entity, Transform
import SwiftUI        // @Observable

@Observable
@MainActor
final class RoomDungeonManager {

    // 씬 최상위 노드. ChilpoRoomView가 화면에 올리고, 몹 컨테이너는 여기 자식으로 붙도록
    let rootEntity = Entity()

    // 입장 창(DungeonEntryView)에 보여줄 상태 문구.
    private(set) var statusMessage = "Ready. Enter the dungeon to begin."

    // 선언
    private let session = ARKitSession()
    private let worldTracking = WorldTrackingProvider()   // 월드 앵커(위치 고정)
    private let roomTracking = RoomTrackingProvider()     // 방 감지

    // 몹 컨테이너: 월드 앵커가 이 엔티티의 위치를 잡도록 선언
    private let mobHolder = Entity()

    // 몹을 고정한 월드 앵커와, 그 앵커가 속한 방 id. nil이면 지금 몹이 안 떠 있는 것.
    private var mobAnchor: WorldAnchor?
    private var spawnedRoomID: UUID?

    // 두 트래킹 모두 지원돼야 한다(둘 다 월드 센싱 권한을 공유).
    var isSupported: Bool {
        WorldTrackingProvider.isSupported && RoomTrackingProvider.isSupported
    }


    func start(mobModelName: String) async {
        guard isSupported else {
            statusMessage = "Room tracking isn't supported on this device."
            return
        }

        do {
            // 센서를 켠다. 권한 거부/미지원이면 여기서 throw.
            try await session.run([worldTracking, roomTracking])
            statusMessage = "Session started. Walk into a room."
        } catch {
            statusMessage = "Couldn't start the session: \(error.localizedDescription)"
            return
        }

        // 몹 모델을 한 번만 로드해 컨테이너의 자식으로 붙임(실패해도 진행: 나중에 재시도 불필요).
        if let model = try? await Entity(named: mobModelName, in: .main) {
            model.scale = SIMD3<Float>(repeating: normalizedScale(model, target: 0.0055))  // 시뮬에서 맞춘 크기와 동일
            mobHolder.addChild(model)
        }

        // 두 스트림을 동시에 실행. 공간이 닫히면 이 task가 취소되며 둘 다 종료된다.
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.observeRooms() }
            group.addTask { await self.observeWorldAnchors() }
        }
    }

    func stop() {
        session.stop()
        mobHolder.removeFromParent()
        mobAnchor = nil
        spawnedRoomID = nil
        statusMessage = "Left the dungeon."
    }

    // - 현재 방 감지 → spawn / despawn 판단

    private func observeRooms() async {
        // 방 업데이트를 이벤트가 올 때마다 하나씩 받기
        for await update in roomTracking.anchorUpdates {
            let room = update.anchor

            if update.event == .removed {
                // 앵커가 사라짐. 그게 몹을 띄운 방이면 몹도 치움
                if spawnedRoomID == room.id { await despawn() }
                continue
            }

            // .added / .updated: 여기서 isCurrentRoom이 바뀜.
            if room.isCurrentRoom {
                // 지금 있는 방. 아직 이 방에 안 띄웠으면 새로 고정.
                if spawnedRoomID != room.id { await spawn(in: room) }
            } else {
                // 현재 방이 아님. 여기에 띄운 몹이 있으면 치움(= 나갈 때 despawn).
                if spawnedRoomID == room.id { await despawn() }
            }
        }
    }

    // - 월드 앵커 갱신 → 몹 위치를 그 좌표에 고정

    private func observeWorldAnchors() async {
        // ARKit이 앵커를 추적/보정할 때마다 이벤트가 온다. 지금 몹의 앵커만 반영.
        for await update in worldTracking.anchorUpdates {
            let anchor = update.anchor
            guard anchor.id == mobAnchor?.id else { continue }

            switch update.event {
            case .added, .updated:
                // 앵커가 알려주는 월드 변환을 컨테이너에 그대로 적용 → 실제 공간에 고정.
                mobHolder.transform = Transform(matrix: anchor.originFromAnchorTransform)
                mobHolder.isEnabled = anchor.isTracked          // 추적이 끊기면 잠깐 숨김
                if mobHolder.parent == nil { rootEntity.addChild(mobHolder) }
            case .removed:
                mobHolder.removeFromParent()
            }
        }
    }

    // - spawn / despawn (몹 ↔ 방 연결)

    /// 방 안 한 점을 골라 그 자리에 WorldAnchor를 추가하고, 그 앵커를 방 id와 묶음
    private func spawn(in room: RoomAnchor) async {
        guard let transform = spawnTransform(in: room) else {
            statusMessage = "In a room, but couldn't find a spot for the mob."
            return
        }

        // 방 안 좌표에 월드 앵커를 만들어 세션에 추가 → ARKit이 이 위치를 계속 추적.
        let anchor = WorldAnchor(originFromAnchorTransform: transform)
        do {
            try await worldTracking.addAnchor(anchor)
        } catch {
            statusMessage = "Couldn't anchor the mob: \(error.localizedDescription)"
            return
        }

        mobAnchor = anchor          // 몹 ↔ 앵커
        spawnedRoomID = room.id     // 앵커 ↔ 방
        statusMessage = "A Cookie is anchored in this room."
    }

    /// 몹의 월드 앵커를 제거하고 화면에서 떼.
    private func despawn() async {
        if let anchor = mobAnchor {
            try? await worldTracking.removeAnchor(anchor)
        }
        mobHolder.removeFromParent()
        mobAnchor = nil
        spawnedRoomID = nil
    }

    //  - 스폰 지점 (contains() 검증)

    /// 방 앵커 원점 주변 후보 점 몇 개를 만들고, contains()가 "방 안"이라고 가정
    /// 통과시키는 첫 점의 월드 변환(4x4)을 반환

    private func spawnTransform(in room: RoomAnchor) -> simd_float4x4? {
        let base = room.originFromAnchorTransform

        // 앵커 로컬 좌표 후보들: 중앙과 그 주변. 가운데 값(y)이 몹 높이(≈1.2m).
        let height: Float = 1.2
        let candidates: [SIMD3<Float>] = [
            [0, height, 0],
            [0.5, height, 0], [-0.5, height, 0],
            [0, height, 0.5], [0, height, -0.5],
        ]

        for local in candidates {
            // 로컬 후보를 월드 좌표로 변환. contains()는 월드 좌표계 점을 받음.
            let p = base * SIMD4<Float>(local.x, local.y, local.z, 1)
            let world = SIMD3<Float>(p.x, p.y, p.z)
            if room.contains(world) {
                // 통과한 점을 평행이동으로 갖는 4x4 변환을 만들어 WorldAnchor에 넘김.
                var t = matrix_identity_float4x4
                t.columns.3 = SIMD4<Float>(world.x, world.y, world.z, 1)
                return t
            }
        }
        return nil   // 후보가 전부 방 밖이면 실패
    }
}
