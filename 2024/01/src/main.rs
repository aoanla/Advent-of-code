use winnow::combinator::{opt,separated_pair, terminated};
use winnow::ascii::{digit1, space1, multispace0};
use winnow::PResult;
use winnow::Parser;
use std::fs::File;
use std::io::Read;
use std::iter::zip;

fn parse_paired_list(input: &mut &str) -> PResult<(Vec<isize>,Vec<isize>)> {
    let mut list = (Vec::new(), Vec::new());

    while let Some(output) = opt(terminated(separated_pair(digit1, space1, digit1), multispace0)).parse_next(input)?
    {
        list.0.push(output.0.parse().unwrap());
        list.1.push(output.1.parse().unwrap());
    }
    Ok(list)
}

fn main() {
    
    let mut file = File::open("input").unwrap();

    let mut s = String::new();
    file.read_to_string(&mut s).unwrap();

    let (mut l,mut r) = parse_paired_list(&mut s.as_str()).unwrap(); 
    
    l.sort();
    r.sort();
    
    let pt1: isize = zip(&l,&r).map(|(li,ri)| (li-ri).abs()).sum();
    println!("Pt 1: {}", pt1);

    let mut tot = 0;
    let mut val = 0;
    let mut valmul = 0;
    let mut liter = l.iter();
    let mut lv = liter.next().unwrap();
    'outer: for ri in r.iter() {
        let mut brk = false;
        if *ri == val {
            tot+=valmul;
            continue;
        }
        valmul = 0;

        while ri > lv {
            match liter.next() {
                Some(ll) => { lv = ll; },
                None => { break 'outer; }
            }
        }
        while ri == lv {
            val = *ri;
            valmul += *lv;
            match liter.next() {
                Some(ll) => { lv = ll },
                None => { brk = true; break; }
            }
        }
        tot += valmul;
        if brk == true {
            break 'outer;
        }
    }
    
    println!("Pt2: {}",tot);
}
