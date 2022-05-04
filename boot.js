(async () => {
	let code
	code = await (await fetch("index.ls")).text()
	code = livescript.compile(code)
	eval(code)
})()
