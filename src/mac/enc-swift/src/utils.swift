import CoreVideo

func createCvPixelBufferFromYuvFrameData(
    _ width: Int,
    _ height: Int,
    _ displayTime: Int,
    _ luminanceStride: Int,
    _ luminanceBytes: [UInt8],
    _ chrominanceStride: Int,
    _ chrominanceBytes: [UInt8]
) -> CVPixelBuffer? {

    let pixelBufferAttributes: CFDictionary = [
        kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary,
        kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    ] as CFDictionary

    var pixelBuffer: CVPixelBuffer?

    let status = CVPixelBufferCreate(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
        pixelBufferAttributes,
        &pixelBuffer
    )

    if status != kCVReturnSuccess {
        print("Failed to create CVPixelBuffer")
        return nil
    }

    // Get the base addresses of the Y and UV planes
    CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    let yPlaneAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 0)
    let uvPlaneAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 1)

    // Copy the luminance (Y) data to the Y plane
    let yDestPointer = yPlaneAddress?.assumingMemoryBound(to: UInt8.self)
    yDestPointer?.update(from: luminanceBytes, count: luminanceBytes.count)

    // Copy the chrominance (UV) data to the UV plane
    let uvDestPointer = uvPlaneAddress?.assumingMemoryBound(to: UInt8.self)
    uvDestPointer?.update(from: chrominanceBytes, count: chrominanceBytes.count)

    CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

    return pixelBuffer
}


func createCvPixelBufferFromBgraFrameData(
    _ width: Int,
    _ height: Int,
    _ displayTime: Int,
    _ bytesPerRow: Int,
    _ bgraBytes: [UInt8]
) -> CVPixelBuffer? {
    let pixelBufferAttributes: CFDictionary = [
        kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary,
        kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA
    ] as CFDictionary

    var pixelBuffer: CVPixelBuffer?

    let status = CVPixelBufferCreateWithBytes(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_32BGRA,
        UnsafeMutableRawPointer(mutating: bgraBytes),
        width * 4,
        nil,
        nil,
        pixelBufferAttributes,
        &pixelBuffer
    )

    if status != kCVReturnSuccess {
        print("Failed to create CVPixelBuffer")
        return nil
    }

    // Get the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer!)

    // Copy the BGRA data to the pixel buffer
    let destPointer = baseAddress?.assumingMemoryBound(to: UInt8.self)
    destPointer?.update(from: bgraBytes, count: bgraBytes.count)

    CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

    return pixelBuffer
}
