//
//  RoomDungeonManager.swift
//  RoomDungeon
//
//  Phase 1 파이프라인 전체.
//    세션 실행 → anchorUpdates 구독 → 현재 방 감지(isCurrentRoom)
//    → 방 안의 후보 점을 contains()로 검증 → 몹 스폰 / 디스폰
//

import ARKit          // ARKitSession, RoomTrackingProvider, RoomAnchor
import RealityKit     // Entity
import SwiftUI        // @Observable

@Observable
@MainActor
final class RoomDungeonManager {

    // 씬 최상위 노드. ImmersiveView가 화면에 올리고, 몹은 여기 자식으로 붙는다.
    let rootEntity = Entity()

    // 입장 창(ContentView)에 보여줄 상태 문구.
    private(set) var statusMessage = "Ready. Enter the dungeon to begin."

    // 센서 엔진과, "방 정보" 데이터 구독권.
    private let session = ARKitSession()
    private let roomTracking = RoomTrackingProvider()

    // 몹은 항상 화면에 하나뿐이라, 한 번 로드해 두고 add/remove로 재사용한다.
    private var mob: Entity?
    // 몹을 띄운 방의 id. nil이면 지금 몹이 안 떠 있는 것.
    private var spawnedRoomID: UUID?

    var isSupported: Bool { RoomTrackingProvider.isSupported }

    // - 시작

    func start() async {
        guard RoomTrackingProvider.isSupported else {
            statusMessage = "Room tracking isn't supported on this device."
            return
        }

        do {
            // 센서를 켠다. 권한 거부/미지원이면 여기서 throw.
            try await session.run([roomTracking])
            statusMessage = "Room tracking started. Walk into a room."
        } catch {
            statusMessage = "Couldn't start room tracking: \(error.localizedDescription)"
            return
        }

        // 몹 모델을 한 번만 로드.
        mob = await Mob.load()

        // 방 업데이트를 이벤트가 올 때마다 하나씩 받는다(공간이 닫히면 취소됨).
        for await update in roomTracking.anchorUpdates {
            let room = update.anchor

            if update.event == .removed {
                // 앵커가 사라짐. 그게 몹을 띄운 방이면 몹도 치운다.
                if spawnedRoomID == room.id { despawnMob() }
                continue
            }

            // .added / .updated: 여기서 isCurrentRoom이 바뀐다.
            if room.isCurrentRoom {
                // 지금 있는 방. 아직 이 방에 안 띄웠으면 새로 띄운다.
                if spawnedRoomID != room.id { spawnMob(in: room) }
            } else {
                // 현재 방이 아님. 여기에 띄운 몹이 있으면 치운다(= 나갈 때 despawn).
                if spawnedRoomID == room.id { despawnMob() }
            }
        }
    }

    func stop() {
        session.stop()
        despawnMob()
        statusMessage = "Left the dungeon."
    }

    // 스폰 / 디스폰

    private func spawnMob(in room: RoomAnchor) {
        // 몹 로드 실패 또는 방 안 점을 못 찾으면 스폰하지 않는다.
        guard let mob, let point = spawnPoint(in: room) else {
            statusMessage = "In a room, but couldn't place the mob."
            return
        }

        mob.removeFromParent()      // 이전 방에 남아 있었다면 떼고
        mob.position = point        // 검증 통과한 좌표에 놓고
        rootEntity.addChild(mob)    // 다시 붙인다 → 화면에 나타남
        spawnedRoomID = room.id
        statusMessage = "A turtle is floating in this room."
    }

    private func despawnMob() {
        mob?.removeFromParent()     // 부모에서 떼면 화면에서 사라짐
        spawnedRoomID = nil
    }

    // 스폰 지점 (contains() 검증)

    /// 방 앵커 원점을 기준으로 후보 점 몇 개를 만들고,
    /// contains()가 "방 안"이라고 통과시키는 첫 점을 고른다.
    /// 메시를 직접 파싱하지 않고, 앵커 변환 + contains()만 쓴다.
    /// 이 contains() 게이트가 룸 트래킹이 실제로 동작한다는 화면상의 증거다.
    ///
    private func spawnPoint(in room: RoomAnchor) -> SIMD3<Float>? {
        let transform = room.originFromAnchorTransform

        // 앵커 로컬 좌표의 후보들: 중앙과 그 주변 몇 곳.
        // 가운데 값(y)이 몹 높이. 낮추면 쿠키가 아래로 내려간다.
        let spawnHeight: Float = 0.2
        let candidates: [SIMD3<Float>] = [
            [0, spawnHeight, 0],
            [0.5, spawnHeight, 0], [-0.5, spawnHeight, 0],
            [0, spawnHeight, 0.5], [0, spawnHeight, -0.5],
        ]

        for local in candidates {
            // 로컬 후보를 월드 좌표로 변환. contains()는 월드 좌표계 점을 받는다.
            let p = transform * SIMD4<Float>(local.x, local.y, local.z, 1)
            let world = SIMD3<Float>(p.x, p.y, p.z)
            if room.contains(world) { return world }
        }
        return nil   // 후보가 전부 방 밖이면 실패
    }
}
