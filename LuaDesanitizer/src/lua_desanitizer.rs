pub fn desanitize(script_to_desanitize: &str) -> String {
    let mut desanitized_lines: Vec<String> = Vec::new();

    for line in script_to_desanitize.lines() {
        match !line.trim().starts_with("--") && line.contains(" = nil") {
            true => {
                let mut desanitized_line: String = String::from("--");
    
                desanitized_line.push_str(&line);
                desanitized_lines.push(desanitized_line);
            }
            false => {
                desanitized_lines.push(line.to_owned());
            },
        }
    }

    return desanitized_lines.join("\r\n");
}