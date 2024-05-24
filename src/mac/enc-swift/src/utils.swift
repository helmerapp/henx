import CoreVideo

func createCVPixelBufferFromPNGData(_ pngData: Data, _ width: Int, _ height: Int) -> CVPixelBuffer?
{
  let options =
    [
      kCVPixelBufferCGImageCompatibilityKey: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey: true,
    ] as CFDictionary
  var pixelBuffer: CVPixelBuffer?

  let status = CVPixelBufferCreate(
    kCFAllocatorDefault,
    width,
    height,
    kCVPixelFormatType_32BGRA,
    options,
    &pixelBuffer)

  guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
    return nil
  }

  CVPixelBufferLockBaseAddress(buffer, .readOnly)
  let pixelData = CVPixelBufferGetBaseAddress(buffer)

  guard
    let context = CGContext(
      data: pixelData,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
  else {
    return nil
  }

  guard let imageSource = CGImageSourceCreateWithData(pngData as CFData, nil),
    let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
  else {
    return nil
  }

  context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
  CVPixelBufferUnlockBaseAddress(buffer, .readOnly)

  return buffer
}

func createCVPixelBufferFromYUVFrameData(
  _ width: Int,
  _ height: Int,
  _ displayTime: Int,
  _ luminanceStride: Int,
  _ luminanceBytes: [UInt8],
  _ chrominanceStride: Int,
  _ chrominanceBytes: [UInt8]
) -> CVPixelBuffer? {

  let pixelBufferAttributes: CFDictionary =
    [
      kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary,
      kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
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

func createCVPixelBufferFromBGRAFrameData(
  _ width: Int,
  _ height: Int,
  _ displayTime: Int,
  _ bytesPerRow: Int,
  _ bgraBytes: [UInt8]
) -> CVPixelBuffer? {
  let pixelBufferAttributes: CFDictionary =
    [
      kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary,
      kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
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
