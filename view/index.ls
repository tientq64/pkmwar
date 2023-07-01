toCamelCase = (text) ->
	text += ""
	text.0 + text.substring 1 .replace /[^a-zA-Z\d]+([a-zA-Z])?/g (, s1) ~>
		s1 and s1.toUpperCase! or ""

numtoHexColor = (num) ->
	\# + num.toString 16 .padStart 6 0

mdToHtml = (md) ->
	md
		.replace /\[(.*?)\]{([\w\-]+):([\w\-]+)}/g (s, text, kind, name) ~>
			switch kind
			| \move
				name = toCamelCase name
				color = \pink-600
			| \ability
				name = toCamelCase name
				color = \blue-600
			| \mechanic
				color = \slate-800
			text or= name
			"""
				<span
					class="text-#color cursor-copy"
					title="#{kind}: #{name}"
					onclick="copy(`#name`)"
				>#text</span>
			"""

window.copy = (text) !->
	try
		await navigator.clipboard.writeText text
	catch
		alert e + ""

for pkd, i in Pokedexs
	pkd.no = i + 1

for type in Types
	type.hexColor = numtoHexColor type.color

for category in Categories
	category.hexColor = numtoHexColor category.color

for k, eff of Effects
	eff.hasVar = /\$\w+/test eff.longText
	eff.lines = eff.longText.trim!split \\n .map (text) ~>
		isTableRow: text.includes " | "
		html: mdToHtml text

for move, i in Moves
	move.index = i
	move.powerNum = move.power or 0
	move.accNum = move.acc or 0
	if eff = Effects[move.eff]
		move.effText = eff.text
		move.effLines = eff.lines
		if eff.hasVar
			move.effLines .= map (line) ~>
				isTableRow: line.isTableRow
				html: line.html.replace /\$effect_chance/g move.effChance

HomePage =
	view: ->
		m \.cursor-default,
			for let path of routes
				m \.px-20.py-1.border-b.border-slate-300.border-dashed.odd:bg-slate-50.hover:bg-slate-200,
					onclick: !~>
						m.route.set path
					path

TypesPage =
	view: ->
		Types.map (type, i) ~>
			m \.px-3.py-1.border-b.border-slate-300.border-dashed.odd:bg-slate-50,
				m \.grid.items-center,
					style:
						gridTemplateColumns: "60px 200px 1fr"
					m \div i
					m \div,
						m \.px-2.inline-block.text-white.text-sm.text-center.w-16,
							style:
								backgroundColor: type.hexColor
							type.name
					m \.text-sm.text-slate-600,
						type.hexColor

CategoriesPage =
	view: ->
		Categories.map (category, i) ~>
			m \.px-3.py-1.border-b.border-slate-300.border-dashed.odd:bg-slate-50,
				m \.grid.items-center,
					style:
						gridTemplateColumns: "60px 200px 1fr"
					m \div i
					m \div,
						m \.px-2.inline-block.text-white.text-sm.text-center.w-16,
							style:
								backgroundColor: category.hexColor
							category.name
					m \.text-sm.text-slate-600,
						category.hexColor

StatsPage =
	view: ->
		Stats.map (stat, i) ~>
			m \.px-3.py-1.border-b.border-slate-300.border-dashed.odd:bg-slate-50,
				m \.grid,
					style:
						gridTemplateColumns: "60px 1fr"
					m \div i
					m \div,
						stat.name

TargetsPage =
	view: ->
		Targets.map (target, i) ~>
			m \.px-3.py-1.border-b.border-slate-300.border-dashed.odd:bg-slate-50,
				m \.grid.items-center,
					style:
						gridTemplateColumns: "60px 1fr"
					m \div i
					m \div,
						target.name

EfficacyPage =
	view: ->
		m \.flex.flex-col.h-full.divide-y.divide-slate-400.divide-dashed.bg-slate-50,
			m \.flex.flex-1.divide-x.divide-slate-400.divide-dashed,
				m \.flex.flex-1.justify-center.items-center
				Types.map (type) ~>
					m \.flex.flex-1.justify-center.items-center.text-white,
						style:
							backgroundColor: type.hexColor
						type.name
			Types.map (atkerType) ~>
				m \.flex.flex-1.divide-x.divide-slate-400.divide-dashed,
					m \.flex.flex-1.justify-center.items-center.text-white,
						style:
							backgroundColor: atkerType.hexColor
						atkerType.name
					Types.map (deferType) ~>
						factor = Efficacy[atkerType.name][deferType.name]
						m \.flex.flex-1.justify-center.items-center,
							class: m.class do
								switch factor
								| 2 => "bg-green-200 text-green-800"
								| 0.5 => "bg-red-200 text-red-800"
								| 0 => "bg-purple-200 text-purple-800"
							factor

MovesPage =
	oninit: !->
		@cols =
			* [\name \3fr 1]
			* [\type \1fr 1]
			* [\category \1fr -1]
			* [\power \1fr -1]
			* [\acc \1fr -1]
			* [\pp \1fr -1]
			* [\priority \1fr -1]
			* [\target \2fr 1]
			* [\eff \8fr 0]
		@gridTemplateColumns = @cols.map (.1) .join " "
		@sortName = ""
		@sortOrder = 1

	sortCol: (col) !->
		if @sortName is col.0
			@sortOrder *= -1
		else
			@sortOrder = 1
		@sortName = col.0
		switch @sortName
		| \name
			Moves.sort (a, b) ~>
				(a.name.localeCompare b.name) * @sortOrder
		| \type
			Moves.sort (a, b) ~>
				(a.type - b.type) * @sortOrder or
				b.category - a.category or
				b.powerNum - a.powerNum or
				a.index - b.index
		| \category
			Moves.sort (a, b) ~>
				(b.category - a.category) * @sortOrder or
				a.type - b.type or
				b.powerNum - a.powerNum or
				a.index - b.index
		| \power
			Moves.sort (a, b) ~>
				(b.powerNum - a.powerNum) * @sortOrder or
				a.type - b.type or
				b.category - a.category or
				a.index - b.index
		| \acc
			Moves.sort (a, b) ~>
				(b.accNum - a.accNum) * @sortOrder or
				a.index - b.index
		| \pp
			Moves.sort (a, b) ~>
				(b.pp - a.pp) * @sortOrder or
				a.index - b.index
		| \priority
			Moves.sort (a, b) ~>
				(b.priority - a.priority) * @sortOrder or
				a.index - b.index
		| \target
			Moves.sort (a, b) ~>
				(a.target - b.target) * @sortOrder or
				a.index - b.index
		m.redraw!

	view: ->
		m \div,
			m \.px-3.py-1.border-b.border-slate-300.border-solid.bg-slate-50.sticky.top-0.select-none,
				m \.grid,
					style:
						gridTemplateColumns: @gridTemplateColumns
					@cols.map (col) ~>
						m \.flex.items-center.gap-2,
							onclick: (event) !~>
								if col.2
									@sortCol col
							col.0
							m \div,
								if @sortName is col.0
									@sortOrder is col.2 and \\u2193 or \\u2191
			Moves.map (move) ~>
				m \.px-3.py-1.border-b.border-slate-300.border-dashed.odd:bg-slate-50,
					m \.grid,
						style:
							gridTemplateColumns: @gridTemplateColumns
						m \div,
							m \a.cursor-alias,
								href: "https://bulbapedia.bulbagarden.net/wiki/#{move.text.replace /\ /g \_}_(move)"
								# href: "https://pokemon.fandom.com/wiki/#{move.text.replace /\ /g \_}"
								target: \_blank
								move.text
							m \.text-sm.text-pink-600.cursor-copy,
								onclick: (event) !~>
									copy move.name
								move.name
						m \div,
							m \.px-2.inline-block.text-white.text-sm.text-center.w-16,
								style:
									backgroundColor: Types[move.type]hexColor
								Types[move.type]name
						m \div,
							m \.px-2.inline-block.text-white.text-sm.text-center.w-16,
								style:
									backgroundColor: Categories[move.category]hexColor
								Categories[move.category]name
						m \.text-sm.text-slate-600,
							move.power or \\ufe58
						m \.text-sm.text-slate-600,
							move.acc and move.acc + \% or \\ufe58
						m \.text-sm.text-slate-600,
							move.pp or \\ufe58
						m \.text-sm.text-slate-600,
							(move.priority > 0 and \+ or "") + move.priority
						m \.text-sm.text-slate-600,
							Targets[move.target]name
						m \.text-sm.text-slate-600,
							m \.cursor-copy,
								onclick: (event) !~>
									if move.effText
										copy move.effText
								move.effText
							m \ul.ml-4.list-disc.text-sm.text-slate-500.whitespace-pre-wrap,
								move.effLines?map (line) ~>
									m \li,
										class: m.class do
											"list-none font-mono text-xs": line.isTableRow
										m.trust line.html

PokedexsPage =
	view: ->
		Pokedexs.map (pkd) ~>
			m \.px-3.py-1.border-b.border-slate-300.border-dashed.odd:bg-slate-50,
				m \.grid,
					style:
						gridTemplateColumns: "60px 1fr 2fr 2fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr"
					m \.text-slate-600.text-sm,
						\# + pkd.no
					m \div,
						m \.w-16.h-16,
							style: m.style do
								backgroundImage: "url(https://cdn.jsdelivr.net/gh/tiencoffee/data/pkd/#{pkd.no}.png)"
								backgroundPosition: "bottom left"
								backgroundSize: 128
								imageRendering: \pixelated
					m \div,
						pkd.name
					m \div,
						pkd.types.map (type) ~>
							m \.px-2.inline-block.text-white.text-sm.text-center.w-16,
								style:
									backgroundColor: Types[type]hexColor
								Types[type]name
					m \div,
						m \.inline-block.text-center,
							m \.text-xs.text-slate-400,
								"Height"
							m \.text-sm.text-slate-600,
								pkd.height + " m"
					m \div,
						m \.inline-block.text-center,
							m \.text-xs.text-slate-400,
								"Weight"
							m \.text-sm.text-slate-600,
								pkd.weight + " kg"
					m \div,
						m \.inline-block.text-center,
							m \.text-xs.text-slate-400,
								"HP"
							m \.text-sm.text-slate-600,
								pkd.hp
					m \div,
						m \.inline-block.text-center,
							m \.text-xs.text-slate-400,
								"Atk"
							m \.text-sm.text-slate-600,
								pkd.atk
					m \div,
						m \.inline-block.text-center,
							m \.text-xs.text-slate-400,
								"Def"
							m \.text-sm.text-slate-600,
								pkd.def
					m \div,
						m \.inline-block.text-center,
							m \.text-xs.text-slate-400,
								"SAt"
							m \.text-sm.text-slate-600,
								pkd.sat
					m \div,
						m \.inline-block.text-center,
							m \.text-xs.text-slate-400,
								"SDf"
							m \.text-sm.text-slate-600,
								pkd.sdf
					m \div,
						m \.inline-block.text-center,
							m \.text-xs.text-slate-400,
								"Spe"
							m \.text-sm.text-slate-600,
								pkd.spe
					m \div,
						m \.inline-block.text-center,
							m \.text-xs.text-slate-400,
								"Total"
							m \.text-sm.text-slate-600,
								pkd.hp + pkd.atk + pkd.def + pkd.sat + pkd.sdf + pkd.spe

routes =
	"/": HomePage
	"/types": TypesPage
	"/categories": CategoriesPage
	"/stats": StatsPage
	"/targets": TargetsPage
	"/efficacy": EfficacyPage
	"/moves": MovesPage
	"/pokedexs": PokedexsPage

m.route document.body, \/ routes
