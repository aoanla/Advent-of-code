/*
    Advent of Code 2023 Day 5 Part 1 Solution in Rust
    Playing with nom because I got sick of writing janky parsers...
*/



use std::collections::VecDeque;
use std::fs;
use nom::{
    character::complete::{alpha1, digit1, space1, newline},
    bytes::complete::tag,
    combinator::{map, map_res, peek},
    sequence::{tuple, preceded, separated_pair},
    multi::{many1, separated_list1},
    IResult,
};
use std::str::FromStr;


#[derive(Debug, PartialEq, Eq)]
pub struct Lookup {
    pub dest_s: i64,
    pub dest_e: i64,
    pub src_s: i64,
    pub src_e: i64,
    pub offset: i64
}

#[derive(Debug, PartialEq, Eq)]
struct SeedRange {
    s: i64,
    e: i64
}

fn apply_lookup(v:&i64, aton:&VecDeque<Lookup>) -> i64 {
    for l in aton.iter() {
        if *v >= l.src_s && *v <= l.src_e { return *v+l.offset}
    }
    *v
}

pub fn parse_num(input: &str) -> IResult<&str, i64> {
    map_res(digit1, i64::from_str)(input)
}

impl Lookup {
    fn parse(input: &str) -> IResult<&str, Self> {
    

        let triple_parser = tuple((parse_num, preceded(space1, parse_num), preceded(space1, parse_num)));

        let mut lookup_parser = map(
            triple_parser, 
            |(d_s, s_s, l)| Self {
                dest_s: d_s,
                dest_e: d_s + l - 1,
                src_s: s_s,
                src_e: s_s + l - 1,
                offset: d_s - s_s,
            }, 
        );

        lookup_parser(input)
    }
}

impl SeedRange {
    fn parse(input: &str) -> IResult<&str,Self> {
        let mut seed_parser = map(
            separated_pair(parse_num, space1, parse_num),
            |(st,ln)| Self {
                s: st,
                e: st + ln -1,
            },
        );

        seed_parser(input)
    }
}

fn parse_seeds(input: &str) -> IResult<&str,Vec<i64>> {
    preceded(tag("seeds: "), separated_list1(space1, parse_num))(input)
}

fn parse_seed_range(input: &str) -> IResult<&str, VecDeque<SeedRange>> {
    let vec_parse = preceded(tag("seeds: "), separated_list1(space1, SeedRange::parse));
    let mut seed_range_deque = map(
        vec_parse, 
        |mut v| -> VecDeque<SeedRange> { v.sort_by(|x,y| (x.s).cmp(&y.s)); v.into()}
    );
    seed_range_deque(input)
}

fn parse_mapper(input: &str) -> IResult<&str, Vec<VecDeque<Lookup>>> {

    let lookup_deque = map(
        separated_list1(newline, Lookup::parse),
        |mut v| -> VecDeque<Lookup> { v.sort_by(|x,y| (x.src_s).cmp(&y.src_s)); v.into() }
    );

    many1(preceded(tuple((tag("\n\n"),separated_list1(tag("-"), alpha1), tag(" map:\n"))),lookup_deque))(input)
}



fn parse_input() -> (Vec<i64>, VecDeque<SeedRange>,Vec<VecDeque<Lookup>>) {   
    let buffer = fs::read_to_string("input").unwrap(); 

    let (buffer,seeds) = peek(parse_seeds)(&buffer).unwrap() ;

    let (buffer, seed_r) = parse_seed_range(&buffer).unwrap() ;

    let map_vec: Vec<VecDeque<Lookup>> = parse_mapper(&buffer).unwrap().1;
    (seeds, seed_r, map_vec)

}



fn main() {

    let (seeds, _seed_r, map_vec) = parse_input();

    let final_loc = map_vec.iter().fold(
        seeds,
        |s,m| -> Vec<i64> { let mut tmp = s.iter().map(|ss| apply_lookup(ss,m)).collect::<Vec<_>>(); tmp.sort(); tmp }
    );

    println!("{}", final_loc[0]);

}

