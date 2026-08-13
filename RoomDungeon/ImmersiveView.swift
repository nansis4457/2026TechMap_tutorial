//
//  ImmersiveView.swift
//  RoomDungeon
//
//  실제 무대. 룸 트래킹은 Full Space(=ImmersiveSpace) 안에서만 돌기 때문에,
//  매니저를 시작시키고 몹을 화면에 렌더링하는 일이 모두 여기서 일어난다.


import RealityKit
import SwiftUI

struct ImmersiveView: View {

    // 앱이 주입한 동일한 매니저. 여기서 세션을 시작하고 몹의 부모(rootEntity)를 화면에 올린다.
    @Environment(RoomDungeonManager.self) private var manager

    var body: some View {
        // RealityView: SwiftUI 안에서 RealityKit 3D 콘텐츠를 그리는 컨테이너.
        RealityView { content in
            // 매니저가 소유한 씬 루트를 화면에 추가한다.
            // 이후 매니저가 이 rootEntity에 몹을 붙이면 곧바로 화면에 나타난다.
            content.add(manager.rootEntity)
        }
        // .task: 이 뷰가 나타날 때 실행되고, 뷰가 사라지면 자동으로 취소된다.
        .task {
            // 세션을 실행하고, 그 안에서 방 업데이트 루프가 계속 돈다.
            // 공간이 닫히면 task가 취소되면서 이 await도 함께 끝난다.
            await manager.start()
        }
    }
}
