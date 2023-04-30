use std::{thread, time::{self, SystemTime}, fs};

use crate::configuration_reader::Configuration;

pub mod configuration_reader;
pub mod file_monitor;
pub mod lua_desanitizer;

fn main() {
    let mut time_last_modified = SystemTime::UNIX_EPOCH;

    let configuration: Configuration = configuration_reader::get_configuration("./config.json");

    loop {
        thread::sleep(time::Duration::from_secs(configuration.polling_time));

        if !file_monitor::has_been_modified(&configuration.path, time_last_modified) {
            continue;
        }

        let script_to_desanitize = fs::read_to_string(&configuration.path)
            .expect(&format!("Unable to read file: {}.", &configuration.path));

        let desanitized_script = lua_desanitizer::desanitize(&script_to_desanitize);

        match fs::write(&configuration.path, desanitized_script) {
            Ok(_) => (),
            Err(error) => {
                println!("Error writing to {}, {}", &configuration.path, error);
                continue;
            }
        }

        time_last_modified = SystemTime::now();
    }
}
