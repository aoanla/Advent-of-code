use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;

fn main() {
    let mut accum = 0;

    if let Ok(lines) = read_lines("input") {
        for line in lines.flatten() {
            let tuples = line
                .rsplit(':')
                .next()
                .unwrap()
                .split(&[';', ','])
                .map(|x| x.split(' ').collect::<Vec<_>>()); //iterator over sequences
            let g = tuples
                .clone()
                .map(|s| {
                    if s[2] == "green" {
                        s[1].parse::<usize>().unwrap_or(0)
                    } else {
                        0
                    }
                })
                .max()
                .unwrap_or(0);
            let r = tuples
                .clone()
                .map(|s| {
                    if s[2] == "red" {
                        s[1].parse::<usize>().unwrap_or(0)
                    } else {
                        0
                    }
                })
                .max()
                .unwrap_or(0);
            let b = tuples
                .map(|s| {
                    if s[2] == "blue" {
                        s[1].parse::<usize>().unwrap_or(0)
                    } else {
                        0
                    }
                })
                .max()
                .unwrap_or(0);
            accum += g * r * b;
        }
    }

    println!("{accum}")
}

fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where
    P: AsRef<Path>,
{
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}
