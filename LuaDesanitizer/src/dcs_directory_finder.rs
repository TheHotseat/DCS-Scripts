use winreg::enums::*;
use winreg::RegKey;

const MISSION_SCRIPTING_PATH: &str = "Scripts\\MissionScripting.lua";

pub fn get_mission_scripting_paths() -> Vec<String> {
    let mut paths = Vec::new();

    get_dcs_directories().iter().for_each(|path| {
        paths.push((path.to_owned() + MISSION_SCRIPTING_PATH).to_owned());
    });

    return paths;
}

fn get_dcs_directories() -> Vec<String> {
    let mut paths: Vec<String> = Vec::new();

    match get_path(
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\DCS World OpenBeta_is1",
    ) {
        Ok(path) => paths.push(path),
        Err(error) => println!("{}", error),
    }

    match get_path("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\DCS World_is1") {
        Ok(path) => paths.push(path),
        Err(error) => println!("{}", error),
    }

    return paths;
}

fn get_path(registry_key: &str) -> std::io::Result<String> {
    let hklm = RegKey::predef(HKEY_LOCAL_MACHINE);
    let registry_path = hklm.open_subkey(registry_key)?;
    let dcs_path: String = registry_path.get_value("InstallLocation")?;

    return Ok(dcs_path);
}
