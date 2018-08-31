// Generally useful functions

const DebugLevel = 5

function sprintf(format) {
    var args = Object.values(arguments)
    var outstring = args.shift()

    while(args.length) {
	var value = args.shift()
	var str = "(null)"
	if (value)
	    str = value.toString()
	outstring = outstring.replace("%s", str)
    }
    
    return outstring
}

function caller() {
    var e = new Error();
    return e.stack.split(/\n/)[3]
}

function reveal(message, priority) {
    priority = priority || 5
    if (priority > DebugLevel)
	return;
    console.log("reveal"+caller()+": "+message)
}

function as_string(o) {
    return JSON.stringify(o, null, 2)
}

function see(value) {
    return value
    if (DebugLevel < 5)
	return value
    console.log("see"+caller()+": "+as_string(value))
    return value
}

module.exports = {
    reveal,
    as_string,
    see,
    sprintf
}


