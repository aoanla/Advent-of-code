/*
    Advent of Code 2023 Day7 Part 1 & 2 Solution in Rust
    Playing with winnow, might make this SIMD
*/


use std::fs;
use std::cmp::Ordering;
use winnow::{
    prelude::*,
    token::one_of,
    ascii::{alphanumeric1, digit1, line_ending, space1},
    combinator::{separated_pair,separated},
};
use std::collections::HashMap;



//lets parse efficiently into a Vec in two passes
pub fn parse_file(input: &mut &str) -> (Vec<u8>, Vec<usize>, Vec<usize>, Vec<(usize,usize)>) {
    let nodenums :HashMap<&str, usize> = HashMap::<&str,usize>::new();
    let startnums :Vec<usize> = vec![]; //the "A" nodes
    let endnums :Vec<usize> = vec![]; //the "Z" nodes

    let parse_direction = one_of(['L','R']).map(|x| if x=='R' {1} else {0} );
    let parse_directions = terminated(repeat(0..,parse_direction), line_ending);
    let parse_nodename = terminated(alphanumeric1, take_while(0..,not_line_ending)); //and discard line
    let parse_nodenames = separated(1.., parse_nodename, line_ending);


    let nodes = Vec<(usize,usize)>::new().resize(nodenames.length(), (0,0));
    for (i,n) in nodenames.iter().enumerate() {
        nodenums[n] = i;
        match n {
            "AAA" => startnums.push(i), //n[2] == 'A' for part 2
            "ZZZ" => endnums.push(i), //n[2] == 'Z' for part 2
            _ => continue, 
        }
    }


    let parse_node_to_num = alphanumeric1.map(|x| nodenums[x]);
    let parse_node = separated_pair(parse_node_to_num, " = ", delimited('(', separated_pair(parse_node_to_num, ', ', parse_node_to_num) ,')');
    let parsed_nodes = separated(1.., parse_node, line_ending).parse_next(input).unwrap();
    parsed_nodes.for_each(|(id,lr)| nodes[id] = lr );

    (directions, startnums, endnums, nodes) //for the first one we just need one startnum and one endnum but future expansion!
    
}


fn main() {


    let buffer = fs::read_to_string("input").unwrap(); 
    let mut inputs  = parse_file(&mut buffer.as_str()).unwrap();

    //
    let mut num = nodenums["AAA"];
    let end = nodenums["ZZZ"];
    for (i,n) in directions.cycle().enumerate() {
        num = nodevec[num][n];
        if num == end {
            println!("Found ZZZ at {}", i+1);
            break;
        }
    }

    println!("{partone}");

}

