/* We're going to try to elide the tedium of yet another ranges processing question by doing it in Rust from the off.

    (This is also because I find it more comfy writing an actual tree in a language with explicit pointers)

*/
use once_cell::sync::Lazy; //for "static Regexes"
use regex::Regex;
use std::collections::{ HashSet, HashMap } ;
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
#[derive(Copy, Clone, PartialEq)]
enum Item {
    X,
    M,
    A,
    S,
}




impl Interval {
    fn gt(&self, lim: i16) -> (Option<Interval>, Option<Interval>){
        if self.h <= lim { //all of the range is below lim, so none goes left
            (None, Some(self))
        } else if self.l > lim { //all of the range is above lim, so none goes right
            (Some(self),None)
        } else {
            (Some(Interval{l:lim+1,h:self.h}), Some(Interval{l:self.l,h:lim}))
        }
    }

    fn lt(&self, lim: i16) -> (Option<Interval>, Option<Interval>){
        if self.l >= lim { //all of the range is above lim, so none goes left
            (None, Some(self))
        } else if self.h < lim { //all of the range is below lim, so none goes right
            (Some(self),None)
        } else {
            (Some(Interval{l:self.l, h:lim-1}), Some(Interval{l:lim,h:self.h}))
        }
    }
}


#[derive(Eq, PartialEq)]
type XMASRange = [Interval;4]; //X M A S

trait XMAS {
    fn sel(&self, index: Item, selector: Item, val: Interval) -> Interval;
    fn one_diff_range(&self, selector: Item, val: Interval ) -> Self ;
    fn gt(&self, lim: i16, selector: Item ) -> (Option<Self>, Option<Self>) where Self: Sized;
    fn lt(&self, lim: i16, selector: Item ) -> (Option<Self>, Option<Self>) where Self: Sized;
}

impl XMAS for XMASRange {
    //Selector type for easily expressing "replace just one element of this array in the new array"
    fn sel(&self, index: Item, selector: Item, val: Interval) -> Interval {
        selector == index && return val ;
        return self[index as usize]
    }

    fn one_diff_range(&self, selector: Item, val: Interval ) -> Self {
        [self.sel(Item::X, selector, val), self.sel(Item::M, selector, val), self.sel(Item::A, selector, val), self.sel(Item::S, selector, val)]
    }


    fn gt(&self, lim: i16, selector: Item) -> (Option<XMASRange>, Option<XMASRange>) {
        //item select logic here  - or could just use map_or(None, XMASRange(.... r.....)) instead
        match self[selector as usize].gt(lim) {
            (None, None)    => (None, None), //this should never happen!
            (None, Some(r)) => (None, Some(self.one_diff_range(selector, r)) ) , 
            (Some(r), None) => (Some(self.one_diff_range(selector, r)), None ), 
            (Some(r), Some(t)) => (Some(self.one_diff_range(selector, r)), Some(self.one_diff_range(selector, t))),
        }

    }

    //and the same for lt here
    fn lt(&self, lim: i16, selector: Item) -> (Option<XMASRange>, Option<XMASRange>) {
        //item select logic here  - or could just use map_or(None, XMASRange(.... r.....)) instead
        match self[selector as usize].lt(lim) {
            (None, None)    => (None, None), //this should never happen!
            (None, Some(r)) => (None, Some(self.one_diff_range(selector, r)) ) , 
            (Some(r), None) => (Some(self.one_diff_range(selector, r)), None ), 
            (Some(r), Some(t)) => (Some(self.one_diff_range(selector, r)), Some(self.one_diff_range(selector, t))),
        }

    }

}


#[derive(Copy, Clone, PartialEq)]
enum Cmp{
    GT,
    LT, 
}

enum Node {
    Accept(Option<XMASRange>),
    Reject(Option<XMASRange>),
    // "state" here is the state of the Range when entering this node so we can do a cheaper DFS
    Split{state: Option<XMASRange>, item: Item, cmp: Cmp, val: i16, left: Box<Node>, right: Box<Node>},
}


impl Node {
    fn process(&mut self, queue: &mut Vec<XMASRange>, acceptlist: &mut HashSet<XMASRange>)  {
        match self {
            Node::Accept(s) => acceptlist.insert(s)   ,/*push to Accept list */
            Node::Reject(_) => {},  /* don't do anything */
            n => {
                    let (L, R) = match self.cmp {
                                Cmp::GT =>  n.state.gt(n.val, n.item),
                                Cmp::LT =>  n.state.lt(n.val, n.item),
                    };
                    //*if node gets Some(state), bother to push it to the queue - L should be on the *top* of the queue for DFS */
                    if let Some(right_v) = R {self.right.state = right_v; queue.push(&mut self.right)};
                    if let Some(left_v) = L {self.left.state = left_v; queue.push(&mut self.left)};
                }
            };
    }


}

fn recursive_parse(start: &str, lookup: &HashMap<&str, &str>) -> Box<Node> {
    let parse_str = lookup[start];
    recursive_anon(&parse_str, &lookup)
}

/* process input into tree */
fn recursive_anon(parse_str: &str, lookup: &HashMap<&str, &str>) -> Box<Node> {
    static re: Lazy<Regex> = Lazy::new(|| Regex::new(r"([xmas])([><])([0-9]+):([^,]),(.*)$").unwrap() );
    let Some(captures) = re.captures(parse_str);
    //begin parsing
    let item = match &captures[1] {
        "x" => Item::X, 
        "m" => Item::M,
        "a" => Item::A,
        "s" => Item::S, 
    };
    let cmp = match &captures[2] {
        ">" => Cmp::GT, 
        "<" => Cmp::LT,
    };
    let val = &captures[3].parse::<i16>().unwrap(); //parse digits as i16
    //these need regexes so we can get the whole string & also check "x" versus "xjajaj"
    let left = match &captures[4] {
        "A"     => Box::new(Node::Accept(None)),
        "R"     => Box::new(Node::Reject(None)),
        n       => recursive_parse(n, &lookup),
    };
    //gnarly splitting on if there's a } or a <> in the second position of this capture 
    // either [xmas]<>... (in which case recursively expand)
    // or  [AR]} in which case we're at the end
    // or glarb} in which case we go to node glarb
    let right = match &captures[5][1 as usize] {
        '}' =>  match &captures[5][0 as usize] {
            'A' => Box::new(Node::Accept(None)),
            'R' => Box::new(Node::Reject(None)),
            },
        '<' | '>' => recursive_anon(&captures[5], &lookup), //make anonymous nodes for intermediate bits from the substring starting with this letter
        n => recursive_parse(&captures[5][:len(&captures[5])-1], &lookup),
    };

    Box::new(Node::Split{ 
        item: item, 
        cmp: cmp,
        left: left, 
        right: right, 
        val: *val,
        state: None, 
    })
}

//probably just recursively regex out the null operations first 
// ,[OP]A,A => ,A  etc

//for line, reading from the end
// while (items we don't recognise)
//      add that item from the list of items
// add our item we started with 
//
fn parse(s: &str) -> Box<Node> {
    let buffer = std::fs::read_to_string(s).unwrap(); 

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
    for line in buffer.readlines() {
        let (key, val) = line.split("{") ;
        temp_dict[key] = val;
    }

    //I feel like we should sort this input somehow to make making the tree easier
    //maybe we at least ensure we start with "in" as the first node?
    let in_node = recursive_parse("in", &temp_dict);
    //and return our in node (along with the rest of the tree?)
    in_node 
}




/* process the tree, DFS */
fn get_ranges(in_node: &mut Node) -> HashSet<XMASRange> {
    /* then walk the tree */
    in_node.state = [Interval{l: 1, h: 4000}, Interval{l:1, h:4000}, Interval{l:1, h:4000}, Interval{l:1, h:4000}];

    let accepts = HashSet::<XMASRange>::new();
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
fn distinct_ranges(xmas_set: &HashSet<XMASRange>) -> i64 {
    //urgh, of course we don't need to worry about interval intersections - this is a *tree* not a general graph, the intervals can't not be distinct!

    //and sum to get answer
    xmas_set.iter().fold(0, |acc, item| acc + item.iter().product::<i64>()) //need to impl the internal product here differently
}


fn main() {

    let mut tree_node = parse("input_sanitized");
    let intervals = get_ranges(&mut tree_node);
    let answer = distinct_ranges(&intervals);
    println!("{answer}");
}