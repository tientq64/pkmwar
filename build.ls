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
	moves
	move_names
	move_damage_classes
	move_effect_prose
	move_targets
]>

toCamelCase = (text) ->
	(text + "")replace /[^a-zA-Z]+([a-zA-Z])?/g (, s1) ~>
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
	normal: \#a8a878
	fighting: \#c03028
	flying: \#a890f0
	poison: \#a040a0
	ground: \#e0c068
	rock: \#b8a038
	bug: \#a8b820
	ghost: \#705898
	steel: \#b8b8d0
	fire: \#f08030
	water: \#6890f0
	grass: \#78c850
	electric: \#f8d030
	psychic: \#f85888
	ice: \#98d8d8
	dragon: \#7038f8
	dark: \#705848
	fairy: \#ee99ac
Types = db.types
	.filter (.id < 10000)
	.sort (a, b) ~>
		a.id - b.id
	.map (type) ~>
		name: type.identifier
		color: typeColors[type.identifier]
addDataCode \Types Types

categoryColors =
	status: \#8c888c
	physical: \#c92112
	special: \#4f5870
Categories = db.move_damage_classes
	.map (moveDamClass) ~>
		name: moveDamClass.identifier
		color: categoryColors[moveDamClass.identifier]
addDataCode \Categories Categories

Efficacy = []
for typeEfficacy in db.type_efficacy
	Efficacy[][typeEfficacy.damage_type_id - 1][typeEfficacy.target_type_id - 1] =
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
		category: stat.damage_class_id - 1
		isBattleOnly: !!stat.is_battle_only
addDataCode \Stats Stats

Targets = db.move_targets
	.map (moveTarget) ~>
		name: toCamelCase moveTarget.identifier
addDataCode \Targets Targets

Moves = db.moves
	.filter (.id < 10000)
	.map (move2) ~>
		move =
			name: toCamelCase move2.identifier
			type: move2.type_id - 1
			pp: move2.pp
			target: move2.target_id - 1
			category: move2.damage_class_id - 1
			eff: move2.effect_id - 1
		move.power? = move2.power
		move.acc? = move2.accuracy
		move.priority? = move2.priority
		move.effChance? = move2.effect_chance
		move
for moveName in db.move_names
	if move = Moves[moveName.move_id - 1]
		if moveName.local_language_id is 9
			move.text = moveName.name
addDataCode \Moves Moves

pkdSizes = <[
	steelix lugia ho-oh wailord kyogre groudon rayquaza dialga
	palkia regigigas giratina arceus reshiram zekrom kyurem
]>
Pokedexs = []
for pkmSp in db.pokemon_species
	if pkmSp.id <= 251
		pkd =
			name: toCamelCase pkmSp.identifier
			happiness: pkmSp.base_happiness
			types: []
			moves: []
			size: 1 + pkdSizes.includes pkmSp.identifier
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
				.replace /\. {2,}/g " "
			longText: moveEffProse.effect
				.replace /\n{2,}/g \\n
				.replace /\. {2,}/g " "
addDataCode \Effects Effects

fs.writeFileSync \data.js dataCode

console.log "Built"
