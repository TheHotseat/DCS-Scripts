use std::fs;
use std::time::SystemTime;

pub fn has_been_modified(file_path: &str, time_last_modified_by_program: SystemTime) -> bool {
    match get_file_last_modified_time(&file_path) {
        Ok(time) => {
            return time > time_last_modified_by_program;
        },
        Err(err) => {
            println!("Failed to read file metadata. {}", err);
            return false;
        }
    }
}

fn get_file_last_modified_time(file_path: &str) -> std::io::Result<SystemTime> {
    let time = fs::metadata(&file_path)?.modified()?;

    return Ok(time);
}