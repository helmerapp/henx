fn main() {
    #[cfg(target_os = "macos")]
    {
        const MIN_MACOS_VERSION: &str = "11"; // Ensure the same is specified in `Package.swift`

        swift_rs::SwiftLinker::new(MIN_MACOS_VERSION)
            .with_package("enc-swift", "./src/mac/enc-swift")
            .link();
    }
}
