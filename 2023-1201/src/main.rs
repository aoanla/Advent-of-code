use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;
use regex::Regex;
use std::collections::HashMap;

fn main() {

    let mut accum = 0;
    let re = Regex::new(r"[0-9]|one|two|three|four|five|six|seven|eight|nine").unwrap(); 
    let revre = Regex::new(r"[0-9]|eno|owt|eerht|ruof|evif|xis|neves|thgie|enin").unwrap();

    let num_dict = HashMap::from([
        ("1",1), ("2", 2), ("3", 3), ("4", 4), ("5", 5), ("6", 6), ("7", 7), ("8", 8), ("9", 9), 
        ("one", 1), ("two", 2), ("three", 3), ("four", 4), ("five", 5), ("six", 6), ("seven", 7), ("eight", 8), ("nine", 9),
    ]);

    if let Ok(lines) = read_lines("input") {
        for line in lines {
            if let Ok(input) = line {
                let digit = num_dict[re.find(&input).unwrap().as_str()];
                let lastdigit = num_dict[&revre.find(&(input.chars().rev().collect::<String>())).unwrap().as_str().chars().rev().collect::<String>() as &str];
                accum += digit * 10 + lastdigit; 
            }
        }
    }

    println!("{accum}")
}


fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where P: AsRef<Path>, {
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}