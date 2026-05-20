#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    // Portable mode: when a "PORTABLE.txt" marker exists next to the .exe,
    // redirect the WebView2 user-data folder (cache, localStorage, cookies…)
    // to a `data/webview` subfolder next to the .exe instead of the default
    // `%LOCALAPPDATA%\com.ii.svg-viewer\EBWebView`. This keeps all state
    // contained inside the portable folder so the app leaves no traces on
    // the host system and can be moved freely (e.g. across USB drives).
    if let Ok(exe) = std::env::current_exe() {
        if let Some(dir) = exe.parent() {
            if dir.join("PORTABLE.txt").exists() {
                let data_dir = dir.join("data").join("webview");
                let _ = std::fs::create_dir_all(&data_dir);
                // WebView2 honours this environment variable as the user data folder.
                std::env::set_var("WEBVIEW2_USER_DATA_FOLDER", &data_dir);
            }
        }
    }

    svg_viewer_lib::run();
}
