/*
    Advent of Code 2023 Day7 Part 1 & 2 Solution in Rust
    Playing with winnow, might make this SIMD
*/


//SIMD Notes: 
// u128 -> u256 [SIMD]
// init_hex -> 16 bit offsets not 8
// classify() works as 
// input -> SIMD vector (16 words = 256b)
// mul all words in SIMD vector by 2 (PSLLW with count operand = 1)
// then 
//VPSLLVW __m256i _mm256_maskz_sllv_epi16( __mmask16 k, __m256i a, __m256i cnt); 
// with an input vector of words = 0x1 to shift [maybe via VBROADCAST? or just a literal?]
// and the result of the PSLLW as our count operand *vector*
//and then reduce sum over words into u16  (several [4] PHADDW (as each one sums adjacent pairs) in sequence? )

use std::fs;
use winnow::{
    prelude::*,
    ascii::{alphanumeric1, digit1, line_ending, space1},
    combinator::{separated_pair,separated},
};
use std::collections::HashMap;




//reduce into separate hex values per card, leftmost value largest  *WORKS*
fn handconcat(x: Vec<u32>) -> u64 {
    let tmp = x.iter().fold(0u32, |acc, card| (acc << 4) + card ) as u64;
    tmp
}

//u128 here *WORKS*
fn init_hex(valmap: &HashMap<char,u32>) -> HashMap<char, u128> {
    let mut hexmap = HashMap::new();
    for (k,v) in valmap.iter() {
        hexmap.insert(*k, 1u128 <<((v-1) * 8));
    } 
    hexmap
}



#[derive(Debug)]
pub struct Hand {
    value:u64,
    bid:i64 ,
}

//handbits are result of compact_h - a u128   
fn classify(handbits:u128) -> u64 {
    handbits.to_le_bytes().iter().map(|x| 1 << (x << 1)).sum()
}

// works correctly
fn compact_h(hand_str: &str, cth: &HashMap<char, u128>) -> u128 {
    hand_str.chars().map(|x| cth[&x]).sum()
}
//compact_htwo(hand_str) = sum(map(x->cardtohextwo[x], collect(hand_str)));



pub fn process_cards(asciicards: &str, ctv: &HashMap<char,u32>, cth: &HashMap<char, u128>) -> u64 {
    let r_h = handconcat(asciicards.chars().map(|x| ctv[&x]).collect::<Vec<_>>());
    ( classify(compact_h(asciicards, cth)) << 32 ) | r_h 
}


pub fn parse_hands(input: &mut &str, ctv: &HashMap<char,u32>, cth: &HashMap<char, u128>) -> PResult<Vec<Hand>> {
    let parse_num = digit1.parse_to();
    let parse_cards = alphanumeric1.map(|x| process_cards(x, ctv, cth));
    let parse_hand = separated_pair(parse_cards, space1, parse_num).map(|x| Hand{value: x.0, bid: x.1});

    separated(1.., parse_hand, line_ending).parse_next(input)
}

fn handbid(x: (usize,&Hand) ) -> i64 {
    (x.0 + 1) as i64 *x.1.bid 
} 

fn main() {
    let cardtoval: HashMap<char,u32> = HashMap::<char,u32>::from( [('2',1), ('3',2), ('4',3), ('5',4), ('6',5), ('7',6), ('8',7), ('9',8), ('T',9), ('J',10), ('Q',11), ('K',12), ('A',13) ]);
    //let cardtovaltwo: HashMap<char,u32>= HashMap::<char,u32>::from([ ('J',1), ('2',2), ('3',3), ('4',4), ('5',5), ('6',6), ('7',7), ('8',8), ('9',9), ('T',10), ('Q',11), ('K',12), ('A',13) ]);
    let cardtohex: HashMap<char, u128> = init_hex(&cardtoval);
    //let cardtohextwo: HashMap<char, u128> = init_hex(cardtovaltwo);

    let buffer = fs::read_to_string("input").unwrap(); 
    let mut handvec  = parse_hands(&mut buffer.as_str(), &cardtoval, &cardtohex).unwrap();
    handvec.sort_by_key(|k| k.value);   
    let partone: i64 = handvec.iter().enumerate().map(|x| handbid(x)).sum();

    println!("{partone}");

}

