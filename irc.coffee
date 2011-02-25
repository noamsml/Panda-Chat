parse_ircline = (line) ->
	rval = {from: "", fromusr: "", fromhost: "", args:[]}
	i = 0
	
	from_r = /^:([^! ]*)(!([^@ ]*)@([^ ]*))?$/
	sep_r = /[ ]+/ #for now
	endsep_r=/[ ]+:/
	
	if temp_parse = endsep_r.exec(line)
		spare = line.substring(temp_parse.index + temp_parse[0].length)
		line = line.substring(0, temp_parse.index)
	
	splitval = line.split(sep_r)
	if (fromparse = from_r.exec(splitval[0])) != null
		rval.from = fromparse[1]
		rval.fromusr = fromparse[3]
		rval.fromhost = fromparse[4]
		i++
	
	rval.cmd = splitval[i].toUpperCase()
	i++
	
	for i of splitval
		rval.args.push(splitval[i])
	
		
	
	if (spare) 
		rval.args.push(spare)
	
	return rval;
