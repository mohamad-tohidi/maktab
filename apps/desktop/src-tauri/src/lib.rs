use tauri::Manager;
use std::process::{Command, Child};
use std::sync::Mutex;

struct OpencodeProcess(Mutex<Option<Child>>);

#[tauri::command]
fn get_opencode_port() -> u16 {
    4096
}

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .manage(OpencodeProcess(Mutex::new(None)))
        .setup(|app| {
            // Launch opencode server as a sidecar process
            let config_dir = app
                .path()
                .resource_dir()
                .expect("resource dir")
                .join(".opencode");

            let child = Command::new("opencode")
                .args(["serve", "--port", "4096", "--config"])
                .arg(config_dir.join("opencode.json"))
                .spawn()
                .expect("Failed to start opencode server");

            *app.state::<OpencodeProcess>().0.lock().unwrap() = Some(child);
            Ok(())
        })
        .on_window_event(|_window, event| {
            // Clean up opencode process on window close
            if let tauri::WindowEvent::Destroyed = event {
                // Process cleanup handled by OS when parent exits
            }
        })
        .invoke_handler(tauri::generate_handler![get_opencode_port])
        .run(tauri::generate_context!())
        .expect("error while running Maktab");
}
