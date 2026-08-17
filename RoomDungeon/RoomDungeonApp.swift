//
//  RoomDungeonApp.swift
//  RoomDungeon
//
//  앱의 진입점(entry point). 두 개의 씬(Scene)으로 구성됨
//   1) 평면 창(WindowGroup) — 던전에 들어가기 전 사용자가 보는 입장 화면
//   2) 몰입 공간(ImmersiveSpace) — 룸/월드 트래킹이 실제로 도는 무대(ChilpoRoomView)
//  매니저(manager)는 딱 한 번만 만들어서 두 씬이 environment로 공유.
//

import SwiftUI

// @main: 이 구조체가 앱의 시작점임을 컴파일러에 알림. 프로젝트당 하나만 존재.
@main
struct RoomDungeonApp: App {

    // @State로 매니저를 앱 수명 내내 살아있는 단일 인스턴스로 소유.
    // 여기서 만들어 두 씬에 나눠줘야 세션/몹 상태가 한 곳에서 관리.
    @State private var manager = RoomDungeonManager()

    var body: some Scene {

        // (1) 평면 창: 앱을 켜면 가장 먼저 뜨는 2D 윈도우.
        WindowGroup {
            DungeonEntryView()
                .environment(manager)   // 하위 뷰들이 같은 매니저를 꺼내 쓸 수 있게 주입
        }
        .windowResizability(.contentSize)   // 창을 콘텐츠 크기에 고정

        // (2) 몰입 공간: id로 열고 닫음. 룸/월드 트래킹은 이 Full Space 안에서만 동작.
        ImmersiveSpace(id: "Dungeon") {
            ChilpoRoomView()
                .environment(manager)   // 같은 매니저 인스턴스를 무대에도 주입
        }
        // .mixed = 패스스루(실제 방)가 보이는 몰입. 몹이 "내 방 안에" 떠 보이려면
        // 화면을 가리는 .full이 아니라 .mixed여야 함.
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}

// 던전 입장 전에 보이는 평면 창.
// ImmersiveSpace는 앱을 켜자마자 자동으로 열 수 없어(사용자가 명시적으로 진입해야 함)
// 여기 "Enter Dungeon" 버튼을 두고, 매니저의 상태줄도 함께 보여줌.
struct DungeonEntryView: View {

    // 앱이 environment로 주입해 준 매니저. @Observable이라 statusMessage가 바뀌면 자동 갱신.
    @Environment(RoomDungeonManager.self) private var manager

    // 몰입 공간을 열고/닫는 시스템 함수. async라서 Task 안에서 await로 호출한다.
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    // 지금 던전 안에 들어와 있는지 여부. 버튼 라벨 전환에 쓴다.
    @State private var inDungeon = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Room Dungeon")
                .font(.extraLargeTitle)
                .fontWeight(.bold)

            // 매니저가 들고 있는 현재 상태 문구를 그대로 표시(세션 시작, 몹 고정 등).
            Text(manager.statusMessage)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            // 입장/퇴장 토글 버튼. 눌리면 async 작업을 Task로 감싸 실행.
            Button(inDungeon ? "Leave Dungeon" : "Enter Dungeon") {
                Task { await toggleDungeon() }
            }
            .font(.title2)
            // 룸/월드 트래킹을 지원하지 않는 기기(예: 시뮬레이터)에선 입장 버튼을 잠근다.
            .disabled(!manager.isSupported)
        }
        .padding(48)
    }

    // 버튼 동작: 들어와 있으면 나가고, 아니면 들어간다.
    private func toggleDungeon() async {
        if inDungeon {
            await dismissImmersiveSpace()   // 공간을 닫으면 무대의 .task가 취소되며 세션 루프도 끝난다
            manager.stop()
            inDungeon = false
        } else {
            switch await openImmersiveSpace(id: "Dungeon") {
            case .opened:
                inDungeon = true            // 성공적으로 열림
            default:
                inDungeon = false           // 사용자가 취소했거나 실패
            }
        }
    }
}
