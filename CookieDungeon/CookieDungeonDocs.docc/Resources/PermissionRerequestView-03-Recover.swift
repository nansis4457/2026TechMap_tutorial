import ARKit
import RealityKit
import RealityKitContent
import SwiftUI

struct PermissionRerequestView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) var openURL
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    var body: some View {
        HStack (spacing: 40) {
            Model3D(named: "oven") { phase in
                switch phase {
                case .empty:
                    VStack (alignment: .center, spacing: 20) {
                        Text("로딩 중")
                            .font(.largeTitle)
                        ProgressView()
                    }
                case .failure(let error):
                    Text("오류 발생: \(error.localizedDescription)")
                case .success(let model):
                    model.resizable()
                @unknown default:
                    Text("알 수 없는 오류 발생")
                }
            }
            .scaledToFit3D()
            .frame(width: 340, height: 300)
            
            VStack (spacing: 20) {
                Text("권한이 거부됨")
                    .font(.largeTitle)
                
                Text("앗! 오븐이 잠겨있어요.\n오븐에서 쿠키가 탈출할 수 있도록 권한을 허용해주세요.")
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    
                Button("설정으로 이동하기") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            }
            .frame(width: 400)
            .layoutPriority(1)
        }
        .padding(20)
        .task {
            await appState.checkWorldSensingAuthorization()
            
            async let monitor: Void = appState.monitorAuthorizationUpdates()
            
            await monitor
        }
        .onChange(of: appState.worldSensingAuthorizationStatus) { _, status in
            guard status == .allowed else { return }
            
            Task {
                let result = await openImmersiveSpace(id: "room")
                
                switch result {
                case .opened, .error:
                    await appState.runARKitSession()
                    dismissWindow(id: "permission-denied")
                    
                case .userCancelled:
                    break
                    
                @unknown default:
                    break
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    PermissionRerequestView()
        .environment(AppState())
}
