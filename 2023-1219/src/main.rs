/* We're going to try to elide the tedium of yet another ranges processing question by doing it in Rust from the off.

    (This is also because I find it more comfy writing an actual tree in a language with explicit pointers)

*/

//use regex::Regex;
use std::collections::HashMap;
use std::fs::read_to_string;

// Stuff we need for range
// ranges are split by > or < into two ranges (careful with those off-by-one errors!)
//   R[x,y] => (> n) => R[n+1,y] :Left , R[x, n] :Right 
//   R[x,y] => (< n) => R[x, n-1] :Left , R[n, y] :Right 



//these are *inclusive* Ranges
#[derive(Copy, Clone, Debug)]
struct Interval {
    l: i16, //low end 
    h: i16, //high end   
}

// Stuff we need for tree
enum Item {
    X,
    M,
    A,
    S,
}




impl Interval {
    fn gt(&self, lim: i16) -> (Some<Interval>, Some<Interval>){
        if self.h <= lim { //all of the range is below lim, so none goes left
            (None, Some(self))
        } else if self.l > lim { //all of the range is above lim, so none goes right
            (Some(self),None)
        } else {
            (Some(Interval(lim+1,self.h)), Some(Interval(self.l,lim)))
        }
    }

    fn lt(&self, lim: i16) -> (Some<Interval>, Some<Interval>){
        if self.l >= lim { //all of the range is above lim, so none goes left
            (None, Some(self))
        } else if self.h < lim { //all of the range is below lim, so none goes right
            (Some(self),None)
        } else {
            (Some(Interval(self.l,lim-1)), Some(Interval(lim,self.h)))
        }
    }
}


type XMASRange [Interval ; 4] //X M A S



impl XMASRange {
    //Selector type for easily expressing "replace just one element of this array in the new array"
    fn sel(&self, index: Item, selector: Item, val: Interval) -> Interval {
        selector == index && return val 
        return self[index]
    }

    fn one_diff_range(&self, selector: Item, val: Interval ) -> XMASRange {
        [self.sel(X as usize, selector, val), self.sel(M as usize, selector, val), self.sel(A as usize, selector, val), self.sel(S as usize, selector, val)]
    }


    fn gt(&self, lim: i16, selector: Item) -> (Some<XMASRange>, Some<XMASRange>) {
        //item select logic here  - or could just use map_or(None, XMASRange(.... r.....)) instead
        match self[selector as usize].gt(lim) {
            (None, None)    => (None, None), //this should never happen!
            (None, Some(r)) => (None, Some(self.one_diff_range(selector, r)) ) , 
            (Some(r), None) => (Some(self.one_diff_range(selector, r)), None ), 
            (Some(r), Some(t)) => (Some(self.one_diff_range(selector, r)), Some(self.one_diff_range(selector, t))),
        }

    }

    //and the same for lt here
    fn lt(&self, lim: i16, selector: Item) -> (Some<XMASRange>, Some<XMASRange>) {
        //item select logic here  - or could just use map_or(None, XMASRange(.... r.....)) instead
        match self[selector as usize].lt(lim) {
            (None, None)    => (None, None), //this should never happen!
            (None, Some(r)) => (None, Some(self.one_diff_range(selector, r)) ) , 
            (Some(r), None) => (Some(self.one_diff_range(selector, r)), None ), 
            (Some(r), Some(t)) => (Some(self.one_diff_range(selector, r)), Some(self.one_diff_range(selector, t))),
        }

    }

}



enum Cmp{
    GT,
    LT, 
}

enum Node {
    Accept{state: Option<XMASRange>},
    Reject{state: Option<XMASRange>},
    // "state" here is the state of the Range when entering this node so we can do a cheaper DFS
    Split{state: Option<XMASRange>, item: Item, cmp: Cmp, val: i16, left: Box<Node>, right: Box<Node>},
}


impl Node {
    fn process(&mut self, queue: &mut Vec<XMASRange>, acceptlist: &mut HashSet<XMASRange>)  {
        match self {
            Accept(s) => acceptlist.insert(s)   ,/*push to Accept list */
            Reject(_) => {},  /* don't do anything */
            n => {
                    (L, R) = match self.cmp {
                                GT =>  n.state.gt(n.val, n.item)
                                LT =>  n.state.lt(n.val, n.item)
                    }
                    //*if node gets Some(state), bother to push it to the queue - L should be on the *top* of the queue for DFS */
                    if let Some(right_v) = R {self.right.state = right_v; queue.push(&mut self.right)};
                    if let Some(left_v) = L {self.left.state = left_v; queue.push(&mut self.left)};
                }
            };
    }


}


/* process input into tree */
fn recursive_parse(start: &str, lookup: &HashMap<&str, &str>) -> Node 
    parse_str = lookup[start];
    //begin parsing
    item = match parse_str[0] {
        'x' => X, 
        'm' => M,
        'a' => A,
        's' => S, 
    };
    condition = match parse_str[1] {
        '>' => GT, 
        '<' => LT,
    }
    value = //parse digits
    left = match {
        'A'     => Accept(None),
        'R'     => Reject(None),
        n       => recursive_parse(n, &lookup),
    }   
    right = match {
        'A' => Accept(None),
        'R' => Reject(None),
        'x'|'m' //argg, some of the names start with an m!
    }


//probably just recursively regex out the null operations first 
// ,[OP]A,A => ,A  etc

//for line, reading from the end
// while (items we don't recognise)
//      add that item from the list of items
// add our item we started with 
//
fn parse(s: &str) -> Tree {
    let buffer = fs::read_to_string(s).unwrap(); 

  /* stuff to remove the "null operations" that branch to the same thing (A or R) on both sides
        //just did this in bash, it was easier
    let regex_bothA = Regex::new(r"[a-z][><][0-9]+:A,A").unwrap();
    let regex_bothR = Regex::new(r"[a-z][><][0-9]+:R,R").unwrap();

    let tmp = regex_bothR.replace(regex_bothA.replace(line, "A"), "R")

    //match a stub that now is just an accept 
    let regex_stub = Regex::new(r"([a-z]+){([AR])})").unwrap();
    //if this matched, emit a new regex to reduce further strings
    if let Some(caps) = regex_stub.captures(tmp) {
        regexes.push( (Regex::new("[:," + &caps[1]).unwrap(), &caps[2])   )
    }
*/
    let temp_dict = HashMap::<&str, &str>::new();
    //stick our name -> { } stuff into this for easier lookup

    //I feel like we should sort this input somehow to make making the tree easier
    //maybe we at least ensure we start with "in" as the first node?
    in_node = recursive_parse("in", &temp_dict)


    //split line on 

    //winnow 
    separated(1.., op_and_left ,   ',')
    one_of(['x','m','a','s']).
}




/* process the tree, DFS */
fn get_ranges(in_node: &mut Node) -> HashSet<XMASRange> {
    /* then walk the tree */
    in_node.state = XMASRange(Interval(1,4000), Interval(1,4000), Interval(1,4000), Interval(1,4000));

    let accepts = HashSet<XMASRange>::new();
    let queue = Vec::<XMASRange>::new();
    queue.push(in_node);
    let mut node_now = queue.pop();
    while let Some(cursor) = node_now {
        cursor.process(queue, accepts);
        node_now = queue.pop();
    }
    accepts
}

//do Range coalescence stuff for 4d overlapping ranges (bleh)
fn distinct_ranges(xmas_set: &mut HashSet<XMASRange>) -> i64 {
    //urgh, of course we don't need to worry about interval intersections - this is a *tree* not a general graph, the intervals can't not be distinct!

    //and sum to get answer
    xmas_set.iter().fold(0, |acc, item| acc + item.iter().product())
}


fn main() {

    let tree_node = parse("input_sanitized");
    let intervals = get_ranges(&tree_node);
    let answer = distinct_ranges(&intervals);
    println!("{answer}");
}