// Testing assignments to a nested datatype when the right hand side of the assignment 
// is a side-effect free function with a nondeterministic choice inside.  
// Includes static error case that was not reported as such in nonDetFunctionInExpr_2.p

main machine M {
    fun F() : int {
	    if ($) {
		    return 0;
		} else {
		    return 1;
		}
	}
	
	fun foo() : int
    {
       return 1;
    }   
	
	var x: (f: (g: int));
	var i, j: int;
	var t, t1: (a: seq [int], b: map[int, seq[int]]);
	var ts: (a: int, b: int);
	var s, s1: seq[int];
	var m: map[int,any];
	//var m9, m10: map[int,any];
	//var s6: seq[map[int,any]];
	//var s3, s33: seq[seq[any]];
	
    start state S {
	    entry {
			i = default(int);
			//++++++++++++++++++++++++++++++++++++++++++3. Maps: 
			//+++++++++++++++++++++++++++++++3.2. Index for assigned into map value is non-det
			m = default(map[int,any]);
			m += (F(), 0);               //static error
			//m[F()] = 3;                  //static error
		}
	}
}