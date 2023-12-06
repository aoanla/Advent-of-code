/*
    Advent of Code 2023 Day 6 Part 1 & 2 Solution in Rust
    Playing with nom, not as clean as it could be (I wish I could keep things as i64 longer, I do worry about the precision...)
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

pub fn parse_num(input: &str) -> IResult<&str, i64> {
    map_res(digit1, i64::from_str)(input)
}


fn parse_time(input: &str) -> IResult<&str,Vec<&str>> {
    preceded(pair(tag("Time:"), space1), separated_list1(space1, digit1))(input)
}

fn parse_dist(input: &str) -> IResult<&str,Vec<&str>> {
    preceded(pair(tag("\nDistance:"), space1), separated_list1(space1, digit1))(input)
}

fn solve(x: i64, y: i64) -> f64 {
    let halfx = x as f64 /2.0;
    let s = ( (halfx*halfx - y as f64 - 1.0) as f64 ).sqrt(); //-1 because we want the solution that *beats* x[2]
    (halfx as f64 + s).floor() - (halfx as f64 -s).ceil() + 1.0  //I am sure I can make this shorter but... 
}


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

