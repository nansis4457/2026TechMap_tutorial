import ARKit
import RealityKit

extension SIMD4 {
    /// Retrieves first 3 elements
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}

extension GeometrySource {
    /// converts between ARKit and RealityKit types.
    func asArray<T>(ofType: T.Type) -> [T] {
        let bContents = self.buffer.contents()
        let offset = self.offset
        let stride = self.stride
        let count = self.count
        
        var result: [T] = Array()
        result.reserveCapacity(count)
        
        for index in 0..<count {
            result.append(bContents.advanced(by: offset + stride * index).assumingMemoryBound(to: T.self).pointee)
        }
        return result
    }
    
    func asSIMD3<T>(ofType: T.Type) -> [SIMD3<T>] {
        return asArray(ofType: (T, T, T).self).map { .init($0.0, $0.1, $0.2) }
    }
}

extension GeometryElement {
    func asIndexArray() -> [UInt32] {
        return (0..<self.count * self.primitive.indexCount).map {
            self.buffer.contents()
                .advanced(by: $0 * self.bytesPerIndex)
                .assumingMemoryBound(to: UInt32.self).pointee
        }
    }
}
