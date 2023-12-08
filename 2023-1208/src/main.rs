/*
    Advent of Code 2023 Day8 Part 1 Solution in Rust
    Playing with winnow, and remembering how Rust "monads" are supposed to pass through function returns...
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
pub fn parse_file(input: &mut &str) -> PResult<(Vec<usize>, Vec<usize>, Vec<usize>, Vec<[usize;2]>)> {
    let mut nodenums :HashMap<&str, usize> = HashMap::<&str,usize>::new();
    let mut startnums :Vec<usize> = vec![]; //the "A" nodes
    let mut endnums :Vec<usize> = vec![]; //the "Z" nodes

    let parse_direction = one_of(['L','R']).map(|x| if x=='R' {1} else {0} );
    let directions: Vec<usize> = terminated(repeat(0.., parse_direction), line_ending).parse_next(input)?;

    let _ = line_ending.parse_next(input)?;

    let parse_nodename = terminated(alphanumeric1, take_till(0..,|c: char| c.is_ascii_control())); //and discard line
    let nodenames: Vec<&str> = peek(separated(1.., parse_nodename, line_ending)).parse_next(input)?;

    let mut nodes = Vec::<[usize;2]>::new();

    nodes.resize(nodenames.len(), [0,0]);


    for (i,&n) in nodenames.iter().enumerate() {
        nodenums.insert(n,i);
        match n {
            "AAA" => startnums.push(i), //n[2] == 'A' for part 2
            "ZZZ" => endnums.push(i), //n[2] == 'Z' for part 2
            _ => continue, 
        }
    } 

    //I absolutely should not need to do this... (and I don't think I did with nom...)
    //using by_ref() doesn't help because we need to borrow mutably anyway [which is also once only]
    let parse_node_to_numa = alphanumeric1.map(|x| nodenums[x]);
    let parse_node_to_numb = alphanumeric1.map(|x| nodenums[x]);
    let parse_node_to_numc = alphanumeric1.map(|x| nodenums[x]);
    let parse_node = separated_pair(parse_node_to_numa, " = ", delimited('(', separated_pair(parse_node_to_numb, ", ", parse_node_to_numc) ,')') );
    let parsed_nodes :Vec<(usize, (usize,usize))>= separated(1.., parse_node, line_ending).parse_next(input)?;
    parsed_nodes.iter().for_each(|(id,lr)| nodes[*id] = [lr.0,lr.1] );
    

    Ok((directions, startnums, endnums, nodes)) //for the first one we just need one startnum and one endnum but future expansion!
    
}


fn main() {

    let buffer = fs::read_to_string("input").unwrap(); 
    let (directions, startnums, endnums, nodes)  = parse_file(&mut buffer.as_str()).unwrap();

    //
    let mut num = startnums[0];
    let end = endnums[0];
    let mut i = 1;
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

