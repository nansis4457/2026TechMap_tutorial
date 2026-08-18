import SwiftUI

@main
struct CookieDungeonApp: App {

    @State private var appState = AppState()

    var body: some Scene {
        ImmersiveSpace(id: "room") {
            RoomView()
                .environment(appState)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
