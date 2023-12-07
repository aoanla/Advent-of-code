/*
    Advent of Code 2023 Day7 Part 1 & 2 Solution in Rust
    Playing with winnow, might make this SIMD
*/


use std::fs;
use nom::{
    character::complete::{digit1, space1},
    bytes::complete::tag,
    combinator::map_res,
    sequence::{pair, preceded},
    multi::separated_list1,
    IResult,
};
use std::str::FromStr;
use std::collections:HashMap;

pub fn parse_num(input: &str) -> IResult<&str, i64> {
    map_res(digit1, i64::from_str)(input)
}

const cardtoval = HashMap::<char,u32>::from( ('2',1), ('3',2), ('4',3), ('5',4), ('6',5), ('7',6), ('8',7), ('9'=>8, 'T'=>9, 'J'=>10, 'Q'=>11, 'K'=>12, 'A'=>13);

const cardtovaltwo = Dict{Char,UInt32}('J'=>1, '2'=>2, '3'=>3, '4'=>4, '5'=>5, '6'=>6, '7'=>7, '8'=>8, '9'=>9, 'T'=>10, 'Q'=>11, 'K'=>12, 'A'=>13);



fn main() {
    let buffer = fs::read_to_string("input").unwrap(); 

    let (buffer,time_chunks) = parse_time(&buffer).unwrap() ;
    let (_,dist_chunks) = parse_dist(&buffer).unwrap() ;
    
    let ts = time_chunks.iter().map(|x| i64::from_str(*x).unwrap_or(0i64)).collect::<Vec<i64>>();
    let ds = dist_chunks.iter().map(|x| i64::from_str(*x).unwrap_or(0i64)).collect::<Vec<i64>>();
    
    println!("{:?}", ts);
    println!("{:?}", ds);
    let partone: f64 = ts.iter().zip(ds).map(|(x,y)| solve(*x,y)).product();
    let parttwo = solve( time_chunks.join("").parse().unwrap_or(0i64), dist_chunks.join("").parse().unwrap_or(0i64)  );

    println!("{partone} {parttwo}");

}

