// This program is just a testbed for the library itself
// Refer to the lib.rs file for the actual implementation

use henx::{VideoEncoder, VideoEncoderOptions};
use scap::{
    capturer::{Area, Capturer, Options, Point, Size},
    frame::FrameType,
};

fn main() {
    // #1 Check if the platform is supported
    if !scap::is_supported() {
        println!("❌ Platform not supported by scap");
        return;
    }

    // #2 Check if we have permission to capture the screen
    if !scap::has_permission() {
        println!("❌ Permission not granted");
        return;
    }

    // #3 Get recording targets (WIP)
    let targets = scap::get_targets();
    println!("🎯 Targets: {:?}", targets);

    const FRAME_TYPE: FrameType = FrameType::BGRAFrame;
    // #4 Create Options
    let options = Options {
        fps: 60,
        targets,
        show_cursor: true,
        show_highlight: true,
        excluded_targets: None,
        output_type: FRAME_TYPE, // only works on macOS
        output_resolution: scap::capturer::Resolution::_720p,
        source_rect: Some(Area {
            origin: Point { x: 0.0, y: 0.0 },
            size: Size {
                width: 1280.0,
                height: 680.0,
            },
        }),
        ..Default::default()
    };

    // #5 Create Recorder
    let mut recorder = Capturer::new(options);
    let [output_width, output_height] = recorder.get_output_frame_size();

    // Create Encoder
    let mut encoder = VideoEncoder::new(VideoEncoderOptions {
        width: output_width as usize,
        height: output_height as usize,
        path: "output.mp4".to_string(),
    });

    // #6 Start Capture
    recorder.start_capture();

    // #7 Capture 100 frames
    for _ in 0..100 {
        let frame = recorder.get_next_frame().expect("Error");
        let _ = encoder
            .ingest_next_frame(&frame)
            .expect("frame couldn't be encoded");
    }

    // #8 Stop Capture
    recorder.stop_capture();

    // Stop Encoder
    let _ = encoder.finish();
}
