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
	moves
	move_damage_classes
	move_effect_prose
	move_targets
]>

toCamelCase = (text) ->
	(text + "")replace /[^a-zA-Z]+([a-zA-Z])?/g (, s1) ~>
		s1 and s1.toUpperCase! or ""

writeCsv = (filename, data) !->
	data = papaparse.unparse data,
		newline: \\n
	fs.outputFileSync "data/#filename.csv" data

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
writeCsv \types Types

categoryColors =
	status: \#8c888c
	physical: \#c92112
	special: \#4f5870
Categories = db.move_damage_classes
	.map (moveDamClass) ~>
		name: moveDamClass.identifier
		color: categoryColors[moveDamClass.identifier]
writeCsv \categories Categories

Efficacy = db.type_efficacy
	.map (typeEfficacy) ~>
		atker: typeEfficacy.damage_type_id - 1
		defer: typeEfficacy.target_type_id - 1
		factor: typeEfficacy.damage_factor / 100
writeCsv \efficacy Efficacy

Moves = db.moves
	.filter (.id < 10000)
	.map (move) ~>
		name: toCamelCase move.identifier
		type: move.type_id - 1
		power: move.power
		pp: move.pp
		acc: move.accuracy
		priority: move.priority
		target: move.target_id - 1
		category: move.damage_class_id - 1
		eff: move.effect_id - 1
		effChance: move.effect_chance
writeCsv \moves Moves

pkdSizes = <[
	steelix lugia ho-oh wailord kyogre groudon rayquaza dialga
	palkia regigigas giratina arceus reshiram zekrom kyurem
]>
PokedexMoves = []
Pokedexs = db.pokemon_species
	.filter (pkmSp) ~>
		pkmSp.identifier in <[
			shedinja blissey gardevoir
			rampardos registeel
			mewtwo carvanha
			shuckle ninjask nidorino
			sunkern
			arceus darmanitan woobat swoobat nidoran-f rayquaza
			escavalier cofagrigus bisharp combusken durant shellos
		]>
	.map (pkmSp, i) ~>
		pkm = db.pokemon.find (pkm) ~>
			pkm.species_id is pkmSp.id and
			pkm.is_default
		pkmTypes = db.pokemon_types.filter (pkmType) ~>
			pkmType.pokemon_id is pkmSp.id
		pkmStats = db.pokemon_stats.filter (pkmStat) ~>
			pkmStat.pokemon_id is pkmSp.id
		pkmMoves = db.pokemon_moves
			.filter (pkmMove) ~>
				pkmMove.pokemon_id is pkmSp.id and
				pkmMove.version_group_id is 18 and
				pkmMove.pokemon_move_method_id is 1
			.sort (a, b) ~>
				a.level - b.level or a.order - b.order
		for pkmMove in pkmMoves
			PokedexMoves.push do
				pkd: i
				move: pkmMove.move_id - 1
		no: pkmSp.id
		name: toCamelCase pkmSp.identifier
		type1: pkmTypes.0.type_id - 1
		type2: pkmTypes.1 and pkmTypes.1.type_id - 1
		height: pkm.height
		weight: pkm.weight
		hp: pkmStats.0.base_stat
		atk: pkmStats.1.base_stat
		def: pkmStats.2.base_stat
		sat: pkmStats.3.base_stat
		sdf: pkmStats.4.base_stat
		spe: pkmStats.5.base_stat
		happiness: pkmSp.base_happiness
		size: 1 + pkdSizes.includes pkmSp.identifier
writeCsv \pkds Pokedexs
writeCsv \pkdMoves PokedexMoves

Effects = db.move_effect_prose
	.filter (.move_effect_id < 10000)
	.map (moveEffProse) ~>
		eff: moveEffProse.move_effect_id - 1
		text: moveEffProse.short_effect
			.replace /\n{2,}/g \\n
			.replace /\. {2,}/g " "
		longText: moveEffProse.effect
			.replace /\n{2,}/g \\n
			.replace /\. {2,}/g " "
writeCsv \effects Effects

Targets = db.move_targets
	.map (moveTarget) ~>
		name: moveTarget.identifier
writeCsv \targets Targets

console.log "Built"
