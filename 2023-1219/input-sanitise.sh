
prune_round() {
	#remove null lines that branch both to A or both to R
	sed -E "s/[a-z][><][0-9]+:R,R/R/g; s/[a-z][><][0-9]+:A,A/A/g" $1 > input3
	#build a stub replacer to turn things that now are just equiv to A or R into a regex to replace them
	egrep "^[a-z]+\{[AR]\}" input3 | sed -E 'sI([a-z]+)\{([AR])\}Is/\(^|[:,]\)\1\([{,}]\)/\\1\2\\2/gIg' > replace
	#and replace them
	sed -i -E -f replace input3 
	egrep -v "^[AR]" input3 > $2
}

prune_round input input_tmp
while true; do 
	prune_round input_tmp input_tmp2	
	[[ $(md5sum input_tmp | cut -d' ' -f1 ) != $(md5sum input_tmp2 | cut -d' ' -f1 ) ]] || break
	cp input_tmp2 input_tmp
done

cp input_tmp2 input_sanitized
