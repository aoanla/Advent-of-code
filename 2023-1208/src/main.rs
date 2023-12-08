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


pub fn 

//lets parse efficiently into a Vec in two passes
pub fn parse_hands(input: &mut &str) -> (Vec<u8>, Vec<usize>, Vec<usize>, Vec<(usize,usize)>) {
    let nodenums :HashMap<&str, usize> = HashMap::<&str,usize>::new();
    let startnums :Vec<usize> = vec![]; //the "A" nodes
    let endnums :Vec<usize> = vec![]; //the "Z" nodes

    let parse_direction = one_of(['L','R']).map(|x| if x=='R' {1} else {0} );
    let parse_directions = terminated(repeat(0..,parse_direction), line_ending);
    let parse_nodename = alphanumeric1; //and discard line


    let parse_node_to_num = alphanumeric1.map(|x| nodenums[x]);
    let parse_node = separated_pair(parse_node_to_num, " = ", delimited('(', separated_pair(parse_node_to_num, ', ', parse_node_to_num) ,')');
    let parse_nodes = separated(1.., parse_node, line_ending).parse_next(input).unwrap();
    
    
}

fn handbid(x: (usize,&Hand) ) -> i64 {
    (x.0 + 1) as i64 *x.1.bid 
} 

fn main() {


    let buffer = fs::read_to_string("input").unwrap(); 
    let mut handvec  = parse_hands(&mut buffer.as_str(), &cardtoval, &cardtohex).unwrap();

    

    println!("{partone}");

}

