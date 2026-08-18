import ARKit
import RealityKit
import RealityKitContent
import SwiftUI

struct PermissionRerequestView: View {
    @Environment(AppState.self) private var appState
    
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
                    
            }
            .frame(width: 400)
            .layoutPriority(1)
        }
        .padding(20)
    }
}

#Preview(windowStyle: .automatic) {
    PermissionRerequestView()
        .environment(AppState())
}
