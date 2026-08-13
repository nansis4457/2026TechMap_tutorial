//
//  RoomDungeonApp.swift
//  RoomDungeon
//
//  앱의 진입점(entry point). 두 개의 씬(Scene)으로 구성된다.
//   1) 평면 창(WindowGroup) — 던전에 들어가기 전 사용자가 보는 입장 화면
//   2) 몰입 공간(ImmersiveSpace) — 룸 트래킹이 실제로 도는 무대
//  매니저(manager)는 딱 한 번만 만들어서 두 씬이 environment로 공유한다.
//

import SwiftUI

// @main: 이 구조체가 앱의 시작점임을 컴파일러에 알린다. 프로젝트당 하나만 존재.
@main
struct RoomDungeonApp: App {

    // @State로 매니저를 앱 수명 내내 살아있는 단일 인스턴스로 소유한다.
    // 여기서 만들어 두 씬에 나눠줘야 세션/몹 상태가 한 곳에서 관리된다.
    @State private var manager = RoomDungeonManager()

    // App 프로토콜이 요구하는 씬 정의. 여기 나열된 게 앱의 화면 구성이다.
    var body: some Scene {

        // (1) 평면 창: 앱을 켜면 가장 먼저 뜨는 2D 윈도우.
        WindowGroup {
            ContentView()
                .environment(manager)   // 하위 뷰들이 같은 매니저를 꺼내 쓸 수 있게 주입
        }
        // 창 크기를 콘텐츠에 맞게 고정(사용자가 마음대로 늘리지 못하게).
        .windowResizability(.contentSize)

        // (2) 몰입 공간: id로 열고 닫는다. 룸 트래킹은 이 Full Space 안에서만 동작.
        ImmersiveSpace(id: "Dungeon") {
            ImmersiveView()
                .environment(manager)   // 같은 매니저 인스턴스를 무대에도 주입
        }
        // .mixed = 패스스루(실제 방)가 보이는 몰입. 몹이 "내 방 안에" 떠 보이려면
        // 화면을 가리는 .full이 아니라 .mixed여야 한다.
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
