/*
    Advent of Code 2023 Day7 Part 1 & 2 Solution in Rust
    Playing with winnow, might make this SIMD
*/


use std::fs;
use winnow::{
    prelude::*,
    token::{one_of, take_till},
    ascii::{alphanumeric1, line_ending},
    combinator::{repeat, separated_pair,separated, delimited, terminated, peek},
};
use std::collections::HashMap;



//lets parse efficiently into a Vec in two passes
pub fn parse_file(input: &mut &str) -> (Vec<usize>, Vec<usize>, Vec<usize>, Vec<[usize;2]>) {
    let nodenums :HashMap<&str, usize> = HashMap::<&str,usize>::new();
    let startnums :Vec<usize> = vec![]; //the "A" nodes
    let endnums :Vec<usize> = vec![]; //the "Z" nodes

    let parse_direction = one_of(|c| c=='L' || c=='R').map(|x| if x=='R' {1} else {0} );
    let directions = terminated(repeat(0..,parse_direction), line_ending).parse_next(input).unwrap();

    //let parse_nodename = terminated(alphanumeric1, take_till(0..,|c: char| c.is_ascii_control())); //and discard line
    //let nodenames: Vec<&str> = peek(separated(1.., parse_nodename, line_ending)).parse_next(input).unwrap();

    let nodes = Vec::<[usize;2]>::new();
    /* 
    nodes.resize(nodenames.len(), [0,0]);


    for (i,n) in nodenames.iter().enumerate() {
        nodenums[n] = i;
        match *n {
            "AAA" => startnums.push(i), //n[2] == 'A' for part 2
            "ZZZ" => endnums.push(i), //n[2] == 'Z' for part 2
            _ => continue, 
        }
    } 


    let parse_node_to_num = alphanumeric1.map(|x| nodenums[x]);
    let parse_node = separated_pair(parse_node_to_num, " = ", delimited('(', separated_pair(parse_node_to_num, ", ", parse_node_to_num) ,')') );
    let parsed_nodes :Vec<(usize, (usize,usize))>= separated(1.., parse_node, line_ending).parse_next(input).unwrap();
    parsed_nodes.iter().for_each(|(id,lr)| nodes[*id] = [lr.0,lr.1] );
    */

    (directions, startnums, endnums, nodes) //for the first one we just need one startnum and one endnum but future expansion!
    
}


fn main() {


    let buffer = fs::read_to_string("input").unwrap(); 
    let (directions, startnums, endnums, nodes)  = parse_file(&mut buffer.as_str());

    //
    let mut num = startnums[0];
    let end = endnums[0];
    let i = 1;
    for n in directions.iter().cycle() {
        num = nodes[num][*n];
        if num == end {
            println!("Found ZZZ at {}", i);
            break;
        }
        i+=1;
    }

    //println!("{partone}");

}

