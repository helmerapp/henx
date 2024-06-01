// This program is just a testbed for the library itself
// Refer to the lib.rs file for the actual implementation

use henx::{VideoEncoder, VideoEncoderOptions};
use scap::{
    capturer::{Capturer, Options},
    frame::FrameType,
};

fn main() {
    if !scap::is_supported() {
        println!("❌ Platform not supported");
        return;
    }

    if !scap::has_permission() {
        println!("❌ Permission not granted");
        return;
    }

    let options = Options {
        fps: 60,
        target: None,
        show_cursor: true,
        show_highlight: true,
        excluded_targets: None,
        output_type: FrameType::BGRAFrame,
        output_resolution: scap::capturer::Resolution::Captured,
        crop_area: None,
        ..Default::default()
    };

    let mut recorder = Capturer::new(options);
    let [output_width, output_height] = recorder.get_output_frame_size();

    let mut encoder = VideoEncoder::new(VideoEncoderOptions {
        width: output_width as usize,
        height: output_height as usize,
        path: "output.mp4".to_string(),
    });

    recorder.start_capture();

    // #7 Capture 100 frames
    for _ in 0..120 {
        let frame = recorder.get_next_frame().expect("Error");
        let _ = encoder
            .ingest_next_frame(&frame)
            .expect("frame couldn't be encoded");
    }

    recorder.stop_capture();

    encoder.finish().expect("Failed to finish encoding");
}
