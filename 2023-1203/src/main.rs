/*
    Advent of Code 2023 Day 3 Part 2 Solution in Rust
    Not efficient...
*/

use regex::Regex;
use std::collections::HashMap;
use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;

struct FoundNum {
    start: i32,
    end: i32,
    contents: i32,
}

fn check_symbols(k: usize, pots: &Vec<FoundNum>) -> Vec<i32> {
    let mut list = Vec::new();
    for p in pots.iter() {
        if (k as i32) < (p.start - 1) || (k as i32) > p.end
        //match end is 1 past end
        {
            continue;
        }
        list.push(p.contents)
    }
    list
}

fn main() {
    let mut accum = 0;
    let re = Regex::new(r"[0-9]+").unwrap();
    let re_ast = Regex::new(r"[*]").unwrap();
    let mut old_potentials = Vec::new();
    let mut old_symbols = HashMap::<usize, Vec<i32>>::new();

    if let Ok(lines) = read_lines("input") {
        for line in lines.flatten() {

            let mut symbols = HashMap::from_iter(
                re_ast
                    .find_iter(line.as_str())
                    .map(|m| (m.start(), Vec::<i32>::new()))
            );

            let potentials = re
                .find_iter(line.as_str())
                .map(|m| FoundNum {
                    start: m.start() as i32,
                    end: m.end() as i32,
                    contents: m.as_str().parse::<i32>().unwrap_or(0),
                })
                .collect::<Vec<_>>();

            for (k, v) in symbols.iter_mut() {
                *v = check_symbols(*k, &potentials);
                v.extend(check_symbols(*k, &old_potentials));
            }

            for (k, v) in old_symbols.iter_mut() {
                v.extend(check_symbols(*k, &potentials));
                if v.len() == 2 {
                    accum += v[0] * v[1]
                };
            }

            old_potentials = potentials;
            old_symbols = symbols;
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
