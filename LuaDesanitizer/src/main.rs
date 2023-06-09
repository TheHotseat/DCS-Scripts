// DCS Lua Desanitizer
// Comments part of the MissionScripting.lua file to allow the use of any code in Lua scripts for DCS missions.

pub mod dcs_directory_finder;
pub mod file_monitor;
pub mod lua_desanitizer;

use std::{ffi::OsString, fs, sync::mpsc, time::Duration, time::SystemTime};

use windows_service::{
    define_windows_service,
    service::{
        ServiceControl, ServiceControlAccept, ServiceExitCode, ServiceState, ServiceStatus,
        ServiceType,
    },
    service_control_handler::{self, ServiceControlHandlerResult},
    service_dispatcher, Result,
};

#[cfg(windows)]
fn main() -> windows_service::Result<()> {
    run()
}

#[cfg(not(windows))]
fn main() {
    panic!("This program is only intended to run on Windows.");
}

#[cfg(windows)]
const SERVICE_NAME: &str = "dcs_lua_desanitizer";
const SERVICE_TYPE: ServiceType = ServiceType::OWN_PROCESS;

const FILE_POLLING_TIME_SECS: u64 = 1;
const DIRECTORY_POLLING_TIME_MINS: u64 = 10;

pub fn run() -> Result<()> {
    // Register generated `ffi_service_main` with the system and start the service, blocking
    // this thread until the service is stopped.
    service_dispatcher::start(SERVICE_NAME, ffi_service_main)
}

// Generate the windows service boilerplate.
// The boilerplate contains the low-level service entry function (ffi_service_main) that parses
// incoming service arguments into Vec<OsString> and passes them to user defined service
// entry (my_service_main).
define_windows_service!(ffi_service_main, my_service_main);

// Service entry function which is called on background thread by the system with service
// parameters. There is no stdout or stderr at this point so make sure to configure the log
// output to file if needed.
pub fn my_service_main(_arguments: Vec<OsString>) {
    if let Err(_e) = run_service() {
        // Handle the error, by logging or something.
    }
}

pub fn run_service() -> Result<()> {
    // Create a channel to be able to poll a stop event from the service worker loop.
    let (shutdown_tx, shutdown_rx) = mpsc::channel();

    // Define system service event handler that will be receiving service events.
    let event_handler = move |control_event| -> ServiceControlHandlerResult {
        match control_event {
            // Notifies a service to report its current status information to the service
            // control manager. Always return NoError even if not implemented.
            ServiceControl::Interrogate => ServiceControlHandlerResult::NoError,

            // Handle stop
            ServiceControl::Stop => {
                shutdown_tx.send(()).unwrap();
                ServiceControlHandlerResult::NoError
            }

            _ => ServiceControlHandlerResult::NotImplemented,
        }
    };

    // Register system service event handler.
    // The returned status handle should be used to report service status changes to the system.
    let status_handle = service_control_handler::register(SERVICE_NAME, event_handler)?;

    // Tell the system that service is running
    status_handle.set_service_status(ServiceStatus {
        service_type: SERVICE_TYPE,
        current_state: ServiceState::Running,
        controls_accepted: ServiceControlAccept::STOP,
        exit_code: ServiceExitCode::Win32(0),
        checkpoint: 0,
        wait_hint: Duration::default(),
        process_id: None,
    })?;

    let mut time_last_modified = SystemTime::UNIX_EPOCH;

    'read_path: loop {
        let dcs_paths = dcs_directory_finder::get_mission_scripting_paths();
        if dcs_paths.is_empty() {
            std::thread::sleep(Duration::from_secs(DIRECTORY_POLLING_TIME_MINS * 60));
            continue;
        }

        loop {
            // Poll shutdown event.
            match shutdown_rx.recv_timeout(Duration::from_secs(FILE_POLLING_TIME_SECS)) {
                // Break the loop either upon stop or channel disconnect
                Ok(_) | Err(mpsc::RecvTimeoutError::Disconnected) => break 'read_path,

                // Continue work if no events were received within the timeout
                Err(mpsc::RecvTimeoutError::Timeout) => (),
            };

            if !file_monitor::has_been_modified(&dcs_paths[0], time_last_modified) {
                continue;
            }

            let script_to_desanitize = fs::read_to_string(&dcs_paths[0])
                .expect(&format!("Unable to read file: {}.", &dcs_paths[0]));

            let desanitized_script = lua_desanitizer::desanitize(&script_to_desanitize);

            match fs::write(&dcs_paths[0], desanitized_script) {
                Ok(_) => (),
                Err(error) => {
                    println!("Error writing to {}, {}", &dcs_paths[0], error);
                    continue;
                }
            }

            time_last_modified = SystemTime::now();
        }
    }

    // Tell the system that service has stopped.
    status_handle.set_service_status(ServiceStatus {
        service_type: SERVICE_TYPE,
        current_state: ServiceState::Stopped,
        controls_accepted: ServiceControlAccept::empty(),
        exit_code: ServiceExitCode::Win32(0),
        checkpoint: 0,
        wait_hint: Duration::default(),
        process_id: None,
    })?;

    Ok(())
}
