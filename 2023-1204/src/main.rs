/*
    Advent of Code 2023 Day 4 Part 2 Solution in Rust
    Not efficient, using the DeQue I wanted to use in julia
*/

use std::collections::HashSet;
use std::collections::VecDeque;
use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;


fn main() {
    let mut accum = 0;
    let mut extra_copies :VecDeque<i32> = VecDeque::new();

    if let Ok(lines) = read_lines("input") {
        
        for line in lines.flatten() {

            let win_can = line.split(&[':','|']).collect::<Vec<_>>();
            let win_vals: HashSet<i32> = HashSet::from_iter(win_can[1].split_ascii_whitespace().map(|m| m.parse::<i32>().unwrap()));
            let can_vals: HashSet<i32> = HashSet::from_iter(win_can[2].split_ascii_whitespace().map(|m| m.parse::<i32>().unwrap()));

            let chain_length = win_vals.intersection(&can_vals).count();

            let extras = extra_copies.pop_front().unwrap_or(1);
            let cur_len = extra_copies.len();
            accum += extras;

            if chain_length > cur_len 
                 { for _ in std::iter::repeat(1).take(chain_length - cur_len) { extra_copies.push_back(1) } ; }            
            for e in extra_copies.iter_mut().take(chain_length) {
                *e += extras ;
            }

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
