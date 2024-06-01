use swift_rs::swift;
pub use swift_rs::{Int, SRData, SRString};

use cidre::{av, cm, ns};

pub struct MacEncoder {
    width: u32,
    height: u32,
    asset_writer: av::AssetWriter,
    asset_writer_input: av::AssetWriterInput,
}

impl MacEncoder {
    pub fn init(width: u32, height: u32, outfile: String) -> Self {
        // Setup AVAssetWriter
        // Create AVAssetWriter for a mp4 file
        let url = ns::Url::with_string(outfile).expect("could not create NSURL");
        let asset_writer = av::AssetWriter::with_url_and_file_type(&url, av::FileType::mp4())
            .expect("could not create AVAssetWriter");

        // Prepare the AVAssetWriterInput Settings
        let media_type = av::MediaType::Video;

        // let output_settings = av::video_settings_keys::codec();

        // let output_settings = av::VideoCodec::h264();

        let output_settings = ns::Dictionary::with_keys_values(keys, objects);

        let asset_writer_input = unsafe {
            av::AssetWriterInput::with_media_type_output_settings_throws(
                media_type,
                output_settings,
            )
        };

        asset_writer_input.set_expects_media_data_in_real_time(true);

        if asset_writer.can_add_input(&asset_writer_input) {
            asset_writer.add_input(&asset_writer_input);
        }

        asset_writer.start_writing();
        asset_writer.start_session_at_src_time(cm::Time::zero());

        Self {
            width: 0,
            height: 0,
            asset_writer,
            asset_writer_input,
        }
    }

    pub fn ingest_yuv_frame(
        &mut self,
        width: u32,
        height: u32,
        display_time: u32,
        luminance_stride: u32,
        luminance_bytes: &[u8],
        chrominance_stride: u32,
        chrominance_bytes: &[u8],
    ) {
        if self.width == 0 {
            self.width = width;
            self.height = height;
        }

        let timestamp = display_time;

        // Create a CVPixelBuffer from YUV data

        if self.asset_writer_input.is_ready_for_more_media_data() {
            // TODO
            // Append the CVPixelBuffer to the AVAssetWriter
        } else {
            println!("AVAssetWriter: not ready for more data");
        }
    }

    pub fn finish(&mut self) {
        self.asset_writer_input.mark_as_finished();
        self.asset_writer.finish();

        while self.asset_writer.status() == av::AssetWriterStatus::Writing {
            println!("AVAssetWriter: still writing...");
            std::thread::sleep(std::time::Duration::from_millis(300));
        }

        println!("AVAssetWriter: finished writing!");
    }
}

swift!(pub fn encoder_init(
    width: Int,
    height: Int,
    out_file: SRString
) -> *mut std::ffi::c_void);

swift!(pub fn encoder_ingest_yuv_frame(
    enc: *mut std::ffi::c_void,
    width: Int,
    height: Int,
    display_time: Int,
    luminance_stride: Int,
    luminance_bytes: SRData,
    chrominance_stride: Int,
    chrominance_bytes: SRData
));

swift!(pub fn encoder_ingest_bgra_frame(
    enc: *mut std::ffi::c_void,
    width: Int,
    height: Int,
    display_time: Int,
    bytes_per_row: Int,
    bgra_bytes_raw: SRData
));

swift!(pub fn encoder_finish(enc: *mut std::ffi::c_void));
