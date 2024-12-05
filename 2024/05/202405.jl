#this is a topological sorting task
#if we assume the topological ordering of the requirements graph is unique (it possibly is, given how long it is)
#then we can just toposort that (into a dict of k->position pairs) and then check each candidate vector is ordered according to the dict directly 