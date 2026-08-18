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
        
        WindowGroup(id: "permission-denied") {
            PermissionRerequestView()
                .environment(appState)
        }
        .defaultSize(width: 860, height: 420)
        .windowResizability(.contentSize)
    }
}
