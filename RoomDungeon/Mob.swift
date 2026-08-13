//
//  Mob.swift
//  RoomDungeon
//
//  앱 번들의 Turtle.usdz를 로드해 몹 엔티티로 만듦.
//  몹은 화면에 하나뿐이라 한 번만 로드하면 되고, 배치는 매니저가 맡도록.
//

import RealityKit

@MainActor
enum Mob {

    /// 거북이 모델을 로드하고 크기만 맞춰 반환한다. 실패하면 nil.
    /// (모델 파일 이름을 바꾸면 아래 문자열도 같이 바꿔야 함)
    static func load() async -> Entity? {
        // 번들 안의 "Turtle"(Turtle.usdz)을 이름으로 로드.
        guard let turtle = try? await Entity(named: "Turtle", in: .main) else {
            return nil
        }

        // 원래 크기의 40%로 축소. 더 키우거나 줄이려면 이 값만 조절하면 됨(예: 0.2, 0.6).
        turtle.scale = SIMD3<Float>(repeating: 0.4)

        return turtle
    }
}
