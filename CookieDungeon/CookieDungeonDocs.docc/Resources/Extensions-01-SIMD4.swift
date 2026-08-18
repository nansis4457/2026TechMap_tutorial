import ARKit
import RealityKit

extension SIMD4 {
    /// Retrieves first 3 elements
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}
