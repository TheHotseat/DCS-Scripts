extern crate serde;

use std::fs;
use serde::Deserialize;
use serde_json;

#[derive(Deserialize, Debug)]
pub struct Configuration {
    pub path: String,
    #[serde(rename = "pollingTime")]
    pub polling_time: u64,
}

pub fn get_configuration(configuration_file_path: &str) -> Configuration {
    let configuration_file_contents = fs::read_to_string(configuration_file_path)
        .expect("Unable to read configuration file.");

    let configuration: Configuration = serde_json::from_str(&configuration_file_contents).unwrap();

    return configuration;
}