import RealityKit
import RealityKitContent
import SwiftUI

struct RoomView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        RealityView { content in
            content.add(appState.contentRoot)
        }
    }
}

#Preview(immersionStyle: .mixed) {
    RoomView()
        .environment(AppState())
}
