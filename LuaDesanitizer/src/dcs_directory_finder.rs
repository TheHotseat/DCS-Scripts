use winreg::enums::*;
use winreg::RegKey;

const MISSION_SCRIPTING_PATH: &str = "\\Scripts\\MissionScripting.lua";

pub fn get_mission_scripting_paths() -> Vec<String> {
    let mut paths = Vec::new(); 

    get_dcs_directories()
                        .iter()
                        .for_each(|path| {
                            paths.push((path.to_owned() + MISSION_SCRIPTING_PATH).to_owned());
                        });
    return paths;
}

fn get_dcs_directories() -> Vec<String> {
    let mut paths: Vec<String> = Vec::new();

    paths.push(get_path("SOFTWARE\\Eagle Dynamics\\DCS World OpenBeta"));
    paths.push(get_path("SOFTWARE\\Eagle Dynamics\\DCS World"));

    return paths;
}

fn get_path(registry_key: &str) -> Option<String> {
    let hklm = RegKey::predef(HKEY_LOCAL_MACHINE);

    match hklm.open_subkey(registry_key) {
        Ok(registry_path) => match registry_path.get_value("Path") {
            Ok(path) => return path,
            Err(_) => (),
        }
        Err(_) => (),
    }

    return None;
}
