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

let cardtoval = HashMap::<char,u32>::from( ('2',1), ('3',2), ('4',3), ('5',4), ('6',5), ('7',6), ('8',7), ('9',8), ('T',9), ('J',10), ('Q',11), ('K',12), ('A',13));

let cardtovaltwo = HashMap::<char,u32>::from( ('J',1), ('2',2), ('3',3), ('4',4), ('5',5), ('6',6), ('7',7), ('8',8), ('9',9), ('T',10), ('Q',11), ('K',12), ('A',13));

//reduce into separate hex values per card, leftmost value largest
fn handconcat(x: Vec<u32>) {
    x.fold(0u32, |acc, card| (acc << 4) + card )
}

//u128 here
fn init_hex(valmap)
    HashMap::<char, u128>::from( valmap.iter().map(|(k,v)| (k,1<<((v-1)<<8))).collect::<Vec<_>>) 
}

let cardtohex = init_hex(cardtoval);
let cardtovaltwo = init_hex(cardtovaltwo);


pub struct Hand {
    value:u64,
    bid:i32 ,
};

//handbits are result of compact_h - a u128   
fn classify(handbits:u128) -> u64 {
    handbits.TOARRAYOFBYTES().map(|x| 1 << (x << 1)).sum()
}

fn compact_h(hand_str: &str) -> u128 {
    handstr.bytes().map(|x| cardtohex[x]).sum()
}
//compact_htwo(hand_str) = sum(map(x->cardtohextwo[x], collect(hand_str)));

fn handcmp(hone:u64,htwo:u64) -> bool {
    hone.value < htwo.value //the front 32 bits of value are the class of hand, the back 32 are the concatenated card values to break ties
}

fn handbid(x: (usize,Hand) ) -> usize {
    x.0*x.1.bid 
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

