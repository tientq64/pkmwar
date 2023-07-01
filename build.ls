require! {
	"fs-extra": fs
	"node-fetch": fetch
	papaparse
}

names = <[
	pokemon
	pokemon_species
	pokemon_types
	pokemon_stats
	pokemon_moves
	types
	type_efficacy
	stats
	natures
	moves
	move_names
	move_damage_classes
	move_effect_prose
	move_targets
]>

toCamelCase = (text) ->
	text += ""
	text.0 + text.substring 1 .replace /[^a-zA-Z\d]+([a-zA-Z])?/g (, s1) ~>
		s1 and s1.toUpperCase! or ""

db = await Promise.all names.map (name) ~>
	fetch "https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/#name.csv"
		.then (.text!)
db = db.map (data) ~>
	papaparse.parse data,
		header: yes
		dynamicTyping: yes
		skipEmptyLines: yes
	.data
for name, i in names
	db[name] = db[i]

dataCode = ""

addDataCode = (varName, code) ->
	dataCode += """
		var #varName = #{JSON.stringify code};\n
	"""

typeColors =
	normal: 0xa8a878
	fighting: 0xc03028
	flying: 0xa890f0
	poison: 0xa040a0
	ground: 0xe0c068
	rock: 0xb8a038
	bug: 0xa8b820
	ghost: 0x705898
	steel: 0xb8b8d0
	fire: 0xf08030
	water: 0x6890f0
	grass: 0x78c850
	electric: 0xf8d030
	psychic: 0xf85888
	ice: 0x98d8d8
	dragon: 0x7038f8
	dark: 0x705848
	fairy: 0xee99ac
Types = db.types
	.filter (.id < 10000)
	.sort (a, b) ~>
		a.id - b.id
	.map (type) ~>
		name: type.identifier
		color: typeColors[type.identifier]
addDataCode \Types Types

categoryColors =
	status: 0x8c888c
	physical: 0xc92112
	special: 0x4f5870
Categories = db.move_damage_classes
	.map (moveDamClass) ~>
		name: moveDamClass.identifier
		color: categoryColors[moveDamClass.identifier]
addDataCode \Categories Categories

Efficacy = {}
for typeEfficacy in db.type_efficacy
	Efficacy{}[Types[typeEfficacy.damage_type_id - 1]name][Types[typeEfficacy.target_type_id - 1]name] =
		typeEfficacy.damage_factor / 100
addDataCode \Efficacy Efficacy

statNames =
	"hp": \hp
	"attack": \atk
	"defense": \def
	"special-attack": \sat
	"special-defense": \sdf
	"speed": \spe
	"accuracy": \acc
	"evasion": \eva
Stats = db.stats
	.map (stat) ~>
		name: statNames[stat.identifier]
addDataCode \Stats Stats

Targets = db.move_targets
	.map (moveTarget) ~>
		name: toCamelCase moveTarget.identifier
			.replace /[Pp]okemon/g (s) ~>
				s.0 + \km
addDataCode \Targets Targets

Natures = db.natures.map (nature2) ~>
	nature =
		name: nature2.identifier
		hp: 1
		atk: 1
		def: 1
		sat: 1
		sdf: 1
		spe: 1
	decrStat = db.stats.find (.id is nature2.decreased_stat_id)
	incrStat = db.stats.find (.id is nature2.increased_stat_id)
	unless decrStat is incrStat
		nature[statNames[decrStat.identifier]] = 0.9
		nature[statNames[incrStat.identifier]] = 1.1
	nature
addDataCode \Natures Natures

Moves = db.moves
	.filter (.id < 10000)
	.map (move2) ~>
		move =
			name: toCamelCase move2.identifier
			type: move2.type_id - 1
			pp: move2.pp
			priority: move2.priority
			target: move2.target_id - 1
			category: move2.damage_class_id - 1
			eff: move2.effect_id - 1
		move.power? = move2.power
		move.acc? = move2.accuracy
		move.effChance? = move2.effect_chance
		move
for moveName in db.move_names
	if move = Moves[moveName.move_id - 1]
		if moveName.local_language_id is 9
			move.text = moveName.name
addDataCode \Moves Moves

pkdSizes = <[
	steelix
	lugia
	hoOh
	wailord
	kyogre
	groudon
	rayquaza
	dialga
	palkia
	regigigas
	giratina
	arceus
	reshiram
	zekrom
	kyurem
]>
pkdFlyings = <[
	butterfree
	beedrill
	pidgeotto
	pidgeot
	fearow
	zubat
	golbat
	venomoth
	aerodactyl
	articuno
	zapdos
	moltres
	dragonite
	noctowl
	ledyba
	ledian
	crobat
	togetic
	yanma
	skarmory
	lugia
	hoOh
	beautifly
	dustox
	swellow
	wingull
	pelipper
	masquerain
	ninjask
	flygon
	swablu
	altaria
	staravia
	staraptor
	mothim
	combee
	vespiquen
	togekiss
	yanmega
	woobat
	swoobat
	archeops
	swanna
	braviary
	mandibuzz
]>
Pokedexs = []
for pkmSp in db.pokemon_species
	if pkmSp.id <= 251
		name = toCamelCase pkmSp.identifier
		pkd =
			name: name
			happiness: pkmSp.base_happiness
			types: []
			moves: []
			size: 1 + pkdSizes.includes name
		if pkdFlyings.includes name
			pkd.flying = yes
		Pokedexs[pkmSp.id - 1] = pkd
for pkm in db.pokemon
	if pkd = Pokedexs[pkm.species_id - 1]
		pkd <<<
			height: pkm.height / 10
			weight: pkm.weight / 10
for pkmType in db.pokemon_types
	if pkd = Pokedexs[pkmType.pokemon_id - 1]
		pkd.types[pkmType.slot - 1] = pkmType.type_id - 1
stats = [, \hp \atk \def \sat \sdf \spe]
for pkmStat in db.pokemon_stats
	if pkd = Pokedexs[pkmStat.pokemon_id - 1]
		pkd[stats[pkmStat.stat_id]] = pkmStat.base_stat
for pkmMove in db.pokemon_moves
	if pkd = Pokedexs[pkmMove.pokemon_id - 1]
		if pkmMove.version_group_id is 18 and pkmMove.pokemon_move_method_id is 1
			pkd.moves.push [pkmMove.level, pkmMove.order, pkmMove.move_id - 1]
for pkd in Pokedexs
	pkd.moves = pkd.moves
		.sort (a, b) ~>
			a.0 - b.0 or a.1 - b.1
		.map (.2)
addDataCode \Pokedexs Pokedexs

Effects = {}
for moveEffProse in db.move_effect_prose
	if moveEffProse.move_effect_id < 10000
		Effects[moveEffProse.move_effect_id - 1] =
			text: moveEffProse.short_effect
				.replace /\n{2,}/g \\n
				.replace /\. {2,}/g ". "
				.replace /\$effect_chance/ \$effChance
				.replace /\[(.*?)\]{([\w\-]+):([\w\-]+)}/g (s, text, kind, name) ~>
					text or name
				.replace /\.$/ ""
			longText: moveEffProse.effect
				.replace /\n{2,}/g \\n
				.replace /\. {2,}/g ". "
addDataCode \Effects Effects

Assets = {}
Assets.moves = fs.readdirSync \assets/moves .map (.split \. .0)
addDataCode \Assets Assets

fs.writeFileSync \data.js dataCode

console.log "Built"
