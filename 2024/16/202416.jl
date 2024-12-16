#this looks like just classic Dijkstra's algorithm (or A* if we're being fancy?), with just a wrinkle on distance calculation.
# as such I'm not sure how *interesting* this is.

#the key trick here is that each node (which is a "crossway") adds two nodes to the graph - a "left-right" node and an "up-down" node. The two are connected by 
# an edge of weight 1000 (the rotation weight). Obviously, lr and ud nodes connect then directly to the corresponding paths that form edges to other node pairs. 

#this of course includes the start node (which is an lr node (the Reindeer starts facing E), paired with a ud node
#                   and the end nodes (both lr and ud versions are valid end states)