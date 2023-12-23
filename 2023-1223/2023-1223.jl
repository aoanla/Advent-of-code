#This is the longest path problem on a DAG, with the main problem being parsing the DAG
#DAG nodes are . with <>^V adjacent to them orthogonally. We can follow > to another > into another node. 
# (weight is obv. "# of .s", remembering that we also need to count the >^v< and the node's dot itself [which we'll count on the edges *out* from that node])

#Then topological sort and linear time longest path.