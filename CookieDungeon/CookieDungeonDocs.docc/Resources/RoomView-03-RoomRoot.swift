import ARKit
import RealityKit
import RealityKitContent
import SwiftUI

struct RoomView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        RealityView { content in
            content.add(appState.contentRoot)
            content.add(appState.roomRoot)
        }
        .task {
            await appState.checkWorldSensingAuthorization()
            
            if appState.worldSensingAuthorizationStatus == .notDetermined {
                await appState.requestWorldSensingAuthorization()
            }
            
            if appState.worldSensingAuthorizationStatus == .denied {
                openWindow(id: "permission-denied")
            } else if appState.worldSensingAuthorizationStatus == .allowed {
                await appState.runARKitSession()
            }
        }
    }
}

#Preview(immersionStyle: .mixed) {
    RoomView()
        .environment(AppState())
}
