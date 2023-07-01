Stats.all = Stats.slice!
Stats.splice 6
Stats.stage = Stats.map (.name isnt \hp)

for move in Moves
	move.type = Types[move.type]name
	move.category = Categories[move.category]name
	move.target = Targets[move.target]name
	move.eff = Effects[move.eff]?text
	Moves[move.name] = move

for pkd, i in Pokedexs
	pkd.no = i + 1
	pkd.types .= map ~> Types[it]name
	pkd.moves .= map ~> Moves[it]name
	Pokedexs[pkd.name] = pkd

Stages =
	"-6": 2 / 8
	"-5": 2 / 7
	"-4": 2 / 6
	"-3": 2 / 5
	"-2": 2 / 4
	"-1": 2 / 3
	"0": 1
	"1": 3 / 2
	"2": 4 / 2
	"3": 5 / 2
	"4": 6 / 2
	"5": 7 / 2
	"6": 8 / 2
Stages <<<
	accEva:
		"-6": 3 / 9
		"-5": 3 / 8
		"-4": 3 / 7
		"-3": 3 / 6
		"-2": 3 / 5
		"-1": 3 / 4
		"0": 1
		"1": 4 / 3
		"2": 5 / 3
		"3": 6 / 3
		"4": 7 / 3
		"5": 8 / 3
		"6": 9 / 3
	crit: [1 / 24 1 / 8 1 / 2 1 1]

Teams =
	* color: 0xff0000
	* color: 0xffff00
	* color: 0x00ff00
	* color: 0x0000ff

Teams <<<
	getTeam: (teamId) ->
		@[teamId] or color: 0x00ffff

game = void
scene = void
pkmsLayer = void
movesLayer = void

class Pokemon extends Phaser.GameObjects.Container
	(pkd, x, y, d, teamId) ->
		super scene, x, y
		scene.add.existing @
		pkmsLayer.add @
		@pkd = pkd
		@team = Teams.getTeam teamId
		@lv = 100
		@nature = Phaser.Math.RND.pick Natures
		@ivs =
			hp: Phaser.Math.Between 0 31
			atk: Phaser.Math.Between 0 31
			def: Phaser.Math.Between 0 31
			sat: Phaser.Math.Between 0 31
			sdf: Phaser.Math.Between 0 31
			spe: Phaser.Math.Between 0 31
		@evs =
			hp: 0
			atk: 0
			def: 0
			sat: 0
			sdf: 0
			spe: 0
		@stages =
			atk: 0
			def: 0
			sat: 0
			sdf: 0
			spe: 0
			crit: 0
		@bases = Object.defineProperties {},
			hp: get: ~>
				(2 * @pkd.hp + @ivs.hp + @evs.hp / 4) * @lv / 100 + @lv + 10
			atk: get: ~>
				((2 * @pkd.atk + @ivs.atk + @evs.atk / 4) * @lv / 100 + 5) * @nature.atk
			def: get: ~>
				((2 * @pkd.def + @ivs.def + @evs.def / 4) * @lv / 100 + 5) * @nature.def
			sat: get: ~>
				((2 * @pkd.sat + @ivs.sat + @evs.sat / 4) * @lv / 100 + 5) * @nature.sat
			sdf: get: ~>
				((2 * @pkd.sdf + @ivs.sdf + @evs.sdf / 4) * @lv / 100 + 5) * @nature.sdf
			spe: get: ~>
				((2 * @pkd.spe + @ivs.spe + @evs.spe / 4) * @lv / 100 + 5) * @nature.spe
		@moves = Phaser.Math.RND.shuffle @pkd.moves.slice! .slice 0 4
		@act = \idle
		@foe = void
		@speed = pkd.spe / 30
		@timo = void
		@init!

	hp:~ ->
		@bases.hp

	atk:~ ->
		@bases.atk * Stages[@stages.atk]

	def:~ ->
		@bases.def * Stages[@stages.def]

	sat:~ ->
		@bases.sat * Stages[@stages.sat]

	sdf:~ ->
		@bases.sdf * Stages[@stages.sdf]

	spe:~ ->
		@bases.spe * Stages[@stages.spe]

	init: !->
		scene.physics.world.enable @
		r = 16 * @pkd.size
		@body.setCircle r, -r, -r
		@body.setCollideWorldBounds yes void void yes
		@spr = scene.add.sprite 0, -r, "pkd-#{@pkd.no}"
		@spr.setScale 2
		@add @spr
		for i to 4
			@spr.anims.create do
				key: "walk-#i"
				frames: @spr.anims.generateFrameNumbers "pkd-#{@pkd.no}",
					frames: [i * 2, i * 2 + 1]
				frameRate: 8
				repeat: -1
		@hpBar = scene.add.image 0, -@body.height * (if @pkd.size is 1 => 1 else 0.8), \hpBar
		@hpBar.setOrigin 0.5
		@hpBar.setTintFill @team.color
		@add @hpBar
		@setHealth @hp
		@walkRandom @d

	setD: (d) !->
		unless @d is d
			@d = d
			@spr.setFrame d * 2
			@updateAnim!

	setDToPkm: (pkm) !->
		dx = Phaser.Math.Difference @x, pkm.x
		dy = Phaser.Math.Difference @y, pkm.y
		@setD do
			if dx < dy
				if @y < pkm.y => 3 else 2
			else
				if @x < pkm.x => 1 else 0

	setHealth: (health) !->
		if health < 0
			health = 0
		@health = health
		@hpBar.setScale health / 10, 3

	setDamage: (damage) !->
		@setHealth @health - damage

	clearTimo: !->
		if @timo
			@timo.remove!
			@timo = void

	updateAnim: !->
		if @act is \walk
			@spr.anims.play "walk-#@d"
		else
			if @pkd.flying
				@spr.anims.play do
					key: "walk-#@d"
					frameRate: 4
			else
				@spr.anims.stop!

	walkRandom: (d) !->
		d ?= Phaser.Math.Between 0 3
		@act = \walk
		@clearTimo!
		@setD d
		@updateAnim!
		duration = Phaser.Math.Between 400 1600
		@timo = scene.time.delayedCall duration, @walkComplete,, @

	walkComplete: (d) !->
		@act = \idle
		@clearTimo!
		@updateAnim!
		delay = Phaser.Math.Between 0 2000
		@timo = scene.time.delayedCall delay, @walkRandom, [d], @

	encounterPkms: (pkms) !->
		unless @act is \fight
			Phaser.Math.RND.shuffle pkms
			for pkm in pkms
				if pkm.team isnt @team
					@act = \fight
					@foe = pkm
					@clearTimo!
					@setDToPkm pkm
					@updateAnim!
					@fight!
					break

	fight: !->
		move = Moves[Phaser.Math.RND.pick @moves]
		foe = @foe
		if move.category is \status
			damage = 0
		else
			lv = @lv
			power = move.power
			atk = @atk
			def = foe.def
			targets = 1
			pb = 1
			weather = 1
			crit = 1
			if Phaser.Math.RND.frac! <= Stages.crit[@stages.crit]
				crit = 1.5
			random = (Phaser.Math.Between 85 100) / 100
			stab = 1
			if @pkd.types.includes move.type
				stab = 1.5
			efficacy = Efficacy[move.type][foe.pkd.types.0]
			efficacy *= Efficacy[move.type][foe.pkd.types.1] if foe.pkd.types.1
			burn = 1
			other = 1
			zmove = 1
			damage =
				((2 * lv / 5 + 2) * power * atk / def / 50 + 2) *
				targets * pb * weather * crit * random * stab * efficacy * burn * other * zmove
		switch move.name
		| \tackle move.name
			@tackle!
			@tween \hit 200,
				* pos: @foe
				* scale: 3
					alpha: [0 \Quad.In]
					duration: 500
		| \ember
			@stagger 5 50 0 !~>
				@tween \ember,,
					* pos: @getFaceMe
						scale: 1.5
					*	pos: @getRandomPosFoe 8
						scale: 3
						alpha: 0.2
						duration: 500
		| \flamethrower
			@stagger 5 50 0 !~>
				@tween \fire,,
					* pos: @getFaceMe
						scale: 1.5
					*	pos: @getRandomPosFoe 8
						scale: 3
						alpha: 0.2
						duration: 500
		| \hydroPump
			@stagger 5 50 0 !~>
				@tween \water,,
					* pos: @getFaceMe
						scale: 2
					*	pos: @getRandomPosFoe 8
						scale: 3
						alpha: 0.2
						duration: 500
					* scale: 4
						alpha: 0
						duration: 250
		scene.time.delayedCall 1000 !~>
			foe.setDamage damage
		@timo = scene.time.delayedCall 2000 @fight,, @

	delay: (time, cb, args) !->
		if time
			scene.time.delayedCall time, cb, args
		else cb!

	moveTo: (obj, time, cb) !->
		scene.physics.moveToObject @, obj,, time
		@delay time, !~>
			@body.stop!
			cb?!

	getVecMe: (len) ->
		vec = new Phaser.Math.Vector2 @foe.x - @x, @foe.y - @y
		if len?
			vec.setLength len
		vec

	getPosMe: (len) ->
		vec = @getVecMe len
		x: @x + vec.x
		y: @y + vec.y

	getFaceMe: ->
		@getPosMe @body.radius

	getRandomPos: (pos, radius) ->
		circ = new Phaser.Geom.Circle pos.x, pos.y, radius
		pt = circ.getRandomPoint!
		pt{x, y}

	getRandomPosFoe: (radius) ->
		@getRandomPos @foe, radius

	getRandomPosMe: (radius) ->
		@getRandomPos @, radius

	getRandomFaceFoe: ->
		@getRandomPosFoe @body.radius

	getRandomFaceMe: ->
		@getRandomPosMe @body.radius

	stagger: (total, delayEach, delay, cb) !->
		for i til total
			@delay delay + i * delayEach, cb, [i, total]

	tween: (obj, delay, ...tweens) !->
		@delay delay, !~>
			if typeof obj is \string
				obj := scene.add.image @x, @y, "moves-#obj"
				obj.setOrigin 0.5
				movesLayer.add obj
			next = (tween, i) !~>
				if typeof tween is \function
					tween = tween.call @
				if tween
					if pos = tween.pos
						if typeof pos is \function
							pos = pos.call @
						tween.x = pos.x
						tween.y = pos.y
						delete tween.pos
					if tween.duration
						tween.targets = obj
						tween.ease ?= \Quad.Out
						tween.onComplete = !~>
							next tweens[++i], i
						for k, val of tween
							if Array.isArray val
								tween[k] =
									value: val.0
									ease: val.1
						scene.tweens.add tween
					else
						obj <<< tween
						next tweens[++i], i
				else
					obj.destroy!
			next tweens.0, 0

	tackle: !->
		@moveTo @foe, 250 !~>
			pos = @getPosMe -32
			@moveTo pos, 250

	leaveFoe: !->
		if @act is \fight
			@foe = void
			@walkRandom!

	onWorldBounds: (up, down, left, right) !->
		if @act is \walk
			if @d is 0 and left or @d is 1 and right or @d is 2 and up or @d is 3 and down
				d = switch
					| up => 3
					| down => 2
					| left => 1
					| right => 0
				@walkComplete d

	onUpdateMove: !->
		switch @act
		| \walk
			switch @d
			| 0
				@x -= @speed
			| 1
				@x += @speed
			| 2
				@y -= @speed
			| 3
				@y += @speed
		| \fight
			@setDToPkm @foe
		@depth = @body.bottom

function preload
	scene := @
	for pkd in Pokedexs
		@load.spritesheet "pkd-#{pkd.no}" "https://cdn.jsdelivr.net/gh/tiencoffee/data/pkd/#{pkd.no}.png",
			frameWidth: 32 * pkd.size
	@load.image \hpBar \assets/hpBar.png
	for name in Assets.moves
		@load.image "moves-#name" "assets/moves/#name.png"

function create
	pkmsLayer := @add.layer!
	movesLayer := @add.layer!
	@scale.on \resize (gameSize) !~>
		@physics.world.setBounds 0 0 gameSize.width, gameSize.height
	@physics.world.on \worldbounds (body, up, down, left, right) !~>
		body.gameObject.onWorldBounds up, down, left, right
	for i to 48
		# pkd = Phaser.Math.RND.pick Pokedexs
		pkd = Pokedexs[i]
		x = Phaser.Math.Between 0 @scale.width
		y = Phaser.Math.Between 0 @scale.height
		d = Phaser.Math.Between 0 3
		pkm = new Pokemon pkd, x, y, d, i % 3

function update
	pkms = pkmsLayer.list
	for pkm in pkms
		pkm._encounters = []
		pkm.onUpdateMove!
	for i til pkms.length - 1
		pkmA = pkms[i]
		for j from i + 1 til pkms.length
			pkmB = pkms[j]
			dist = Phaser.Math.Distance.BetweenPoints pkmA, pkmB
			dist -= pkmA.body.radius + pkmB.body.radius
			if dist < 0
				@physics.world.separateCircle pkmA.body, pkmB.body
			if dist <= 32
				unless pkmA.act is \fight
					pkmA._encounters.push pkmB
				unless pkmB.act is \fight
					pkmB._encounters.push pkmA
			else if dist > 96
				if pkmA.foe is pkmB
					pkmA._leaveFoe = yes
				if pkmB.foe is pkmA
					pkmB._leaveFoe = yes
	for pkm in pkms
		if pkm._encounters.length
			pkm.encounterPkms pkm._encounters
			delete pkm._encounters
		else if pkm._leaveFoe
			pkm.leaveFoe!
			delete pkm._leaveFoe

game = new Phaser.Game do
	width: innerWidth
	height: innerHeight
	type: Phaser.AUTO
	scene:
		preload: preload
		create: create
		update: update
	disableContextMenu: yes
	banner: no
	render:
		pixelArt: yes
	physics:
		default: \arcade
		arcade:
			debug: no
	scale:
		mode: Phaser.Scale.RESIZE
