/* We're going to try to elide the tedium of yet another ranges processing question by doing it in Rust from the off.

    (This is also because I find it more comfy writing an actual tree in a language with explicit pointers)

*/

// Stuff we need for range
// ranges are split by > or < into two ranges (careful with those off-by-one errors!)
//   R[x,y] => (> n) => R[n+1,y] :Left , R[x, n] :Right 
//   R[x,y] => (< n) => R[x, n-1] :Left , R[n, y] :Right 

//these are *inclusive* Ranges
#[derive(Copy, Clone, Debug)]
struct Range {
    l: i16, //low end 
    h: i16, //high end   
}

#[derive(Copy, Clone, Debug)]
struct XMASRange {
    x: Range, 
    m: Range, 
    a: Range,
    s: Range, 
}

impl Range {
    fn gt(&self, lim: i16) -> (Some<Range>, Some<Range>){
        if self.h <= lim { //all of the range is below lim, so none goes left
            (None, Some(self))
        } else if self.l > lim { //all of the range is above lim, so none goes right
            (Some(self),None)
        } else {
            (Some(Range(lim+1,self.h)), Some(Range(self.l,lim)))
        }
    }

    fn lt(&self, lim: i16) -> (Some<Range>, Some<Range>){
        if self.l >= lim { //all of the range is above lim, so none goes left
            (None, Some(self))
        } else if self.h < lim { //all of the range is below lim, so none goes right
            (Some(self),None)
        } else {
            (Some(Range(self.l,lim-1)), Some(Range(lim,self.h)))
        }
    }
}

// Stuff we need for tree
enum Item {
    X,
    M,
    A,
    S,
}


impl XMASRange {
    fn gt(&self, lim: i16, selector: Item) -> (Some<XMASRange>, Some<XMASRange>) {
        //item select logic here  - or could just use map_or(None, XMASRange(.... r.....)) instead
        match item.gt(lim) {
            (None, None)    => (None, None), //this should never happen!
            (None, Some(r)) => (None, Some(XMASRange(item: r, ..self)) ) , //how do we express this "update this named field" in Rust? I don't think we can - this is suited to a HashMap or something
            (Some(r), None) => (Some(XMASRange(item: r, ..self)), None ), 
            (Some(r), Some(t)) => (Some(XMASRange(item: r, ..self)), Some(XMASRange(item: t, ..self)))
        }

    }

    //and the same for lt here

}



enum Cmp {
    GT,
    LT, 
}

enum Node {
    Accept{state: XMASRange},
    Reject,
    // "state" here is the state of the Range when entering this node so we can do a cheaper DFS
    Split{state: XMASRange, item: Item, cmp: Cmp, val: i16, left: Box<Node>, right: Box<Node>},
}


impl Node {
    fn process(&mut self) -> .... {
        match self {
            Accept(s) => push s -> acceptlist     ,/*push to Accept list */
            Reject(_) => (),  /* don't do anything */
            n => {

                    (L, R) = n.state.{gt or lt}(val, item)

                    //*if node gets Some(state), bother to push it to the queue*/
                }
            }


    }


}
