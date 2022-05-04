pages = <[types categories targets efficacy effects moves pkds pkdMoves]>

data = await Promise.all pages.map (page) ~>
	fetch "/data/#page.csv" .then (.text!)
data = data.map (text) ~>
	Papa.parse text,
		header: yes
		dynamicTyping: yes
	.data
[Types, Categories, Targets, Efficacy, Effects, Moves, Pkds, PkdMoves] = data

tmp = []
for eff in Effects
	tmp[eff.eff] = eff
Effects = tmp

for move in Moves
	move.type = Types[move.type]
	move.category = Categories[move.category]
	move.eff = Effects[move.eff]

tmp = []
for efficacy in Efficacy
	tmp[][efficacy.atker][efficacy.defer] = efficacy.factor
Efficacy = tmp

for pkd in Pkds
	pkd.types = [Types[pkd.type1]]
	delete pkd.type1
	if pkd.type2
		pkd.types.1 = Types[pkd.type2]
		delete pkd.type2
	pkd.height /= 10
	pkd.weight /= 10

toCamelCase = (text) ->
	(text + "")replace /[^a-zA-Z]+([a-zA-Z])?/g (, s1) ~>
		s1 and s1.toUpperCase! or ""

mdToHtml = (md, isTable) ->
	md.replace /\[(.*?)\]{([\w\-]+):([\w\-]+)}/g (s, text, kind, name) ~>
		switch kind
		| \move
			name = toCamelCase name
		text or= name
		"""
			<span class="text-pink-600" title="#{kind}: #{name}">#text</span>
		"""

HomePage =
	view: ->
		m \.cursor-default,
			pages.map (page) ~>
				m \.px-20.py-1.border-b.border-slate-300.border-dashed.odd:bg-slate-50.hover:bg-slate-200,
					onclick: !~>
						m.route.set "/#page"
					"/#page"

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
								backgroundColor: type.color
							type.name
					m \.text-sm.text-slate-600,
						type.color

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
								backgroundColor: category.color
							category.name
					m \.text-sm.text-slate-600,
						category.color

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
				Types.map (deferType) ~>
					m \.flex.flex-1.justify-center.items-center.text-white,
						style:
							backgroundColor: deferType.color
						deferType.name
			Efficacy.map (atker, i) ~>
				atkerType = Types[i]
				m \.flex.flex-1.divide-x.divide-slate-400.divide-dashed,
					m \.flex.flex-1.justify-center.items-center.text-white,
						style:
							backgroundColor: atkerType.color
						atkerType.name
					atker.map (factor) ~>
						m \.flex.flex-1.justify-center.items-center,
							class: m.class do
								switch factor
								| 2 => "bg-green-200 text-green-800"
								| 0.5 => "bg-red-200 text-red-800"
								| 0 => "bg-purple-200 text-purple-800"
							factor

EffectsPage =
	view: ->
		"empty"

MovesPage =
	getLinkMoveName: (name) ->
		name = name
			.replace /(?<=[a-z])[A-Z]/g (s) ~> "_#s"
			.replace /^[a-z]/ (.toUpperCase!)
		"https://bulbapedia.bulbagarden.net/wiki/#{name}_(move)"

	view: ->
		Moves.map (move) ~>
			m \.px-3.py-1.border-b.border-slate-300.border-dashed.odd:bg-slate-50,
				m \.grid,
					style:
						gridTemplateColumns: "3fr 1fr 1fr 1fr 1fr 1fr 8fr"
					m \div,
						m \a.cursor-alias,
							href: @getLinkMoveName move.name
							target: \_blank
							move.name
					m \div,
						m \.px-2.inline-block.text-white.text-sm.text-center.w-16,
							style:
								backgroundColor: move.type.color
							move.type.name
					m \div,
						m \.px-2.inline-block.text-white.text-sm.text-center.w-16,
							style:
								backgroundColor: move.category.color
							move.category.name
					m \div,
						m \.inline-block.text-center,
							m \.text-xs.text-slate-400,
								"Power"
							m \.text-sm.text-slate-600,
								move.power or \\ufe58
					m \div,
						m \.inline-block.text-center,
							m \.text-xs.text-slate-400,
								"Acc."
							m \.text-sm.text-slate-600,
								move.acc and move.acc + \% or \\ufe58
					m \div,
						m \.inline-block.text-center,
							m \.text-xs.text-slate-400,
								"PP"
							m \.text-sm.text-slate-600,
								move.pp or \\ufe58
					m \.text-sm.text-slate-600,
						m \div move.eff?text
						m \ul.ml-4.list-disc.text-sm.text-slate-500.whitespace-pre-wrap,
							move.eff?longText.trim!split \\n .map (text) ~>
								isTable = text.includes " | "
								m \li,
									class: m.class do
										"list-none font-mono text-xs": isTable
									m.trust mdToHtml text, isTable

PkdsPage =
	view: ->
		Pkds.map (pkd) ~>
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
									backgroundColor: type.color
								type.name
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

PkdMovesPage =
	view: ->
		"empty"

m.route document.body, \/,
	"/": HomePage
	"/types": TypesPage
	"/categories": CategoriesPage
	"/targets": TargetsPage
	"/efficacy": EfficacyPage
	"/effects": EffectsPage
	"/moves": MovesPage
	"/pkds": PkdsPage
	"/pkdMoves": PkdMovesPage
