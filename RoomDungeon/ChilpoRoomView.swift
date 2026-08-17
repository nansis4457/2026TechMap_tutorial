//
//  ChilpoRoomView.swift
//  RoomDungeon
//


import RealityKit
import SwiftUI

//   (쿠키를 추가하려면 여기 case 한 줄만 늘리면 됨)
enum CookieModel: String, CaseIterable {
    case prosciutto = "Prosciutto_Cookie"

    // 번들에서 쓰는 이름(= 원시값).
    var fileName: String { rawValue }
}

// 모델의 가장 긴 변을 `target` 미터에 맞추는 scale 값을 계산한다.
// (usdz마다 원본 크기가 제각각이라, 고정 배율 대신 이렇게 정규화하면 항상 같은 크기로 보임~)
@MainActor
func normalizedScale(_ entity: Entity, target: Float) -> Float {
    let e = entity.visualBounds(relativeTo: nil).extents
    let maxDim = max(e.x, e.y, e.z)
    return maxDim > 0 ? target / maxDim : 1
}

struct ChilpoRoomView: View {

    // 앱이 주입한 동일한 매니저. 여기서 세션을 시작하고 몹의 부모(rootEntity)를 화면에 올림
    @Environment(RoomDungeonManager.self) private var manager

    // 룸 트래킹 파이프라인에서 실제로 배치할 기본 쿠키(첫 번째 case).
    private let defaultCookie: CookieModel = .prosciutto

    var body: some View {
        // RealityView: SwiftUI 안에서 RealityKit 3D 콘텐츠를 그리는 컨테이너.
        // 몹은 매니저가 룸 트래킹으로 감지한 방 안에 WorldAnchor로 고정하므로,
        // 여기선 매니저의 rootEntity만 올리고 실제 배치는 파이프라인에 맡긴다.
        RealityView { content in
            content.add(manager.rootEntity)
        }
        // 몰입 공간이 열리면 세션 시작. 공간이 닫히면 이 .task가 취소되며 세션도 종료된다.
        .task {
            await manager.start(mobModelName: defaultCookie.fileName)
        }
    }
}

#Preview {
    ChilpoRoomView()
        .environment(RoomDungeonManager())   // 프리뷰에도 매니저를 주입해야 크래시 안 남
}
