//
//  ContentView.swift
//  RoomDungeon
//
//  던전 입장 전에 보이는 평면 창.
//  ImmersiveSpace는 앱을 켜자마자 자동으로 열 수 없다(사용자가 명시적으로 진입해야 함).
//  그래서 여기 "Enter Dungeon" 버튼을 두고, 매니저의 상태줄도 같이 보여준다.
//

import SwiftUI

struct ContentView: View {

    // 앱이 environment로 주입해 준 매니저를 꺼내 쓴다. @Observable이라 상태가 바뀌면
    // (예: statusMessage) 이 뷰가 자동으로 다시 그려진다.
    @Environment(RoomDungeonManager.self) private var manager

    // 몰입 공간을 열고/닫는 시스템 함수. async라서 Task 안에서 await로 호출한다.
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    // 지금 던전(몰입 공간) 안에 들어와 있는지 여부. 버튼 라벨 전환에 쓴다.
    @State private var inDungeon = false

    var body: some View {
        VStack(spacing: 24) {

   
            Text("Room Dungeon")
                .font(.extraLargeTitle)
                .fontWeight(.bold)

            // 매니저가 들고 있는 현재 상태 문구를 그대로 표시(세션 시작됨, 몹 등장 등).
            Text(manager.statusMessage)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)          // 너무 길어지지 않게 폭 제한

            // 입장/퇴장 토글 버튼. 눌리면 async 작업을 Task로 감싸 실행.
            Button(inDungeon ? "Leave Dungeon" : "Enter Dungeon") {
                Task { await toggleDungeon() }
            }
            .font(.title2)
            // 기기가 룸 트래킹을 지원하지 않으면 아예 못 누르게 비활성화.
            .disabled(!manager.isSupported)
        }
        .padding(48)
    }

    // 버튼 동작: 들어와 있으면 나가고, 아니면 들어간다.
    private func toggleDungeon() async {
        if inDungeon {
            // 나가기: 공간을 닫고 세션도 정리한다.
            await dismissImmersiveSpace()
            manager.stop()
            inDungeon = false
        } else {
            // 들어가기: 공간 열기를 시도하고, 결과에 따라 상태를 갱신.
            switch await openImmersiveSpace(id: "Dungeon") {
            case .opened:
                inDungeon = true                 // 성공적으로 열림
            case .userCancelled, .error:
                inDungeon = false                // 사용자가 취소했거나 실패
            @unknown default:
                // 미래에 새 케이스가 추가돼도 컴파일이 깨지지 않도록 방어.
                inDungeon = false
            }
        }
    }
}
