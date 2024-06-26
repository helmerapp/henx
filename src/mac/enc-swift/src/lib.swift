import AVFoundation
import Foundation
import SwiftRs
import VideoToolbox

// TODO: handle errors better
class Encoder: NSObject {
  var width: Int
  var height: Int
  var assetWriter: AVAssetWriter
  var assetWriterInput: AVAssetWriterInput
  var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor

  init(_ width: Int, _ height: Int, _ outFile: URL) {
    self.width = width
    self.height = height

    // Setup AVAssetWriter
    // Create AVAssetWriter for a mp4 file
    self.assetWriter = try! AVAssetWriter(url: outFile, fileType: .mp4)

    // Prepare the AVAssetWriterInputPixelBufferAdaptor
    let outputSettings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: width,
      AVVideoHeightKey: height,
    ]

    self.assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
    self.assetWriterInput.expectsMediaDataInRealTime = true

    let sourcePixelBufferAttributes: [String: Any] = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    ]

    self.pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: self.assetWriterInput,
      sourcePixelBufferAttributes: sourcePixelBufferAttributes
    )

    if self.assetWriter.canAdd(self.assetWriterInput) {
      self.assetWriter.add(self.assetWriterInput)
    }

    self.assetWriter.startWriting()
    self.assetWriter.startSession(atSourceTime: CMTime.zero)
  }
}

@_cdecl("encoder_init")
func encoderInit(_ width: Int, _ height: Int, _ outFile: SRString) -> Encoder {
  return Encoder(
    width,
    height,
    URL(fileURLWithPath: outFile.toString())
  )
}

// NOTE: make any timestamp adjustments in Rust before passing here

@_cdecl("encoder_ingest_yuv_frame")
func encoderIngestYuvFrame(
  _ enc: Encoder,
  _ width: Int,
  _ height: Int,
  _ displayTime: Int,
  _ luminanceStride: Int,
  _ luminanceBytesRaw: SRData,
  _ chrominanceStride: Int,
  _ chrominanceBytesRaw: SRData
) {
  let luminanceBytes = luminanceBytesRaw.toArray()
  let chrominanceBytes = chrominanceBytesRaw.toArray()

  // Create a CVPixelBuffer from YUV data
  var pixelBuffer = createCvPixelBufferFromYuvFrameData(
    width,
    height,
    displayTime,
    luminanceStride,
    luminanceBytes,
    chrominanceStride,
    chrominanceBytes
  )

  // Append the CVPixelBuffer to the AVAssetWriter
  if enc.assetWriterInput.isReadyForMoreMediaData {
    let frameTime = CMTimeMake(value: Int64(displayTime), timescale: 1_000_000_000)
    let success = enc.pixelBufferAdaptor.append(pixelBuffer!, withPresentationTime: frameTime)
    if !success {
      print("AVAssetWriter: \(enc.assetWriter.error?.localizedDescription ?? "Unknown error")")
    }
  } else {
    print("AVAssetWriter: not ready for more data")
  }
}

@_cdecl("encoder_ingest_bgra_frame")
func encoderIngestBgraFrame(
  _ enc: Encoder,
  _ width: Int,
  _ height: Int,
  _ displayTime: Int,
  _ bytesPerRow: Int,
  _ bgraBytesRaw: SRData
) {
  let bgraBytes = bgraBytesRaw.toArray()

  // Create a CVPixelBuffer from BGRA data
  var pixelBuffer = createCvPixelBufferFromBgraFrameData(
    width,
    height,
    displayTime,
    bytesPerRow,
    bgraBytes
  )

  // Append the CVPixelBuffer to the AVAssetWriter
  if enc.assetWriterInput.isReadyForMoreMediaData {
    let frameTime = CMTimeMake(value: Int64(displayTime), timescale: 1_000_000_000)
    let success = enc.pixelBufferAdaptor.append(pixelBuffer!, withPresentationTime: frameTime)
    if !success {
      print("AVAssetWriter: \(enc.assetWriter.error?.localizedDescription ?? "Unknown error")")
    }
  } else {
    print("AVAssetWriter: not ready for more data")
  }
}

@_cdecl("encoder_finish")
func encoderFinish(_ enc: Encoder) {

  // TODO: figure out how to gracefully end session
  // enc.assetWriter.endSession(atSourceTime: CMTime)

  enc.assetWriterInput.markAsFinished()
  enc.assetWriter.finishWriting {}

  while enc.assetWriter.status == .writing {
    print("AVAssetWriter: still writing...")
    usleep(500000)
  }

  print("AVAssetWriter: finished writing!")
}
