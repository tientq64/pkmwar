for pkd, i in Pokedexs
	pkd.no = i + 1

game = void
scene = void
moveToPlugin = void
pkms = void
infos = void

class Pokemon extends Phaser.Physics.Arcade.Sprite
	(pkd, x, y, d, team) ->
		super scene, x, y, "pkd-#{pkd.no}" 6
		@pkd = pkd
		scene.add.existing @
		pkms.add @
		@setScale 2
		@setCircle @width / 4, @width / 4, @height / 2
		@body.setCollideWorldBounds yes void void yes
		for i to 4
			@anims.create do
				key: "walk-#i"
				frames: @anims.generateFrameNumbers "pkd-#{pkd.no}",
					frames: [i * 2, i * 2 + 1]
				frameRate: 8
				repeat: -1
		@moveTo = moveToPlugin.add @,
			speed: pkd.spe * 2
		@hpBar = infos.create 0 0 \hpBar
		@hpBar.setScale 40 2
		@hpBar.setOrigin 0.5
		@hpBar.depth = 10000
		console.log @body.transform
		@act = \walk
		@setD d
		@moveTo.on \complete @onMoveToComplete, @
		@walkRandom!

	setD: (d) !->
		@d = d
		@setFrame d * 2

	updateDByXY: (x, y) !->
		dx = Phaser.Math.Difference @x, x
		dy = Phaser.Math.Difference @y, y
		@setD do
			if dx > dy
				if @x < x => 1 else 0
			else
				if @y < y => 3 else 2

	walkRandom: !->
		x = @x + Phaser.Math.Between -200 200
		y = @y + Phaser.Math.Between -200 200
		@updateDByXY x, y
		@anims.play "walk-#@d"
		@moveTo.moveTo x, y

	onMoveToComplete: !->
		@onWalkComplete!

	onCollideWorldBounds: !->
		@onWalkComplete!

	onCollidePkm: (pkm) !->
		@onWalkComplete!

	onWalkComplete: !->
		if @act is \walk
			@walkRandom!

	update: !->
		@hpBar.setPosition @x, @y - 12
		@depth = @body.bottom

function preload
	scene := @
	for pkd in Pokedexs
		@load.spritesheet "pkd-#{pkd.no}" "https://cdn.jsdelivr.net/gh/tiencoffee/data/pkd/#{pkd.no}.png",
			frameWidth: 32 * pkd.size
	@load.image \hpBar \assets/hpBar.png
	@load.plugin \rexmovetoplugin,
		\https://cdn.jsdelivr.net/gh/rexrainbow/phaser3-rex-notes/dist/rexmovetoplugin.min.js

function create
	moveToPlugin := scene.plugins.get \rexmovetoplugin
	@scale.on \resize (gameSize) !~>
		@physics.world.setBounds 0 0 gameSize.width, gameSize.height
	pkms := @physics.add.group do
		runChildUpdate: yes
	infos := @add.group!
	@physics.add.collider pkms, pkms, (pkmA, pkmB) !~>
		pkmA.onCollidePkm pkmB
		pkmB.onCollidePkm pkmA
	@physics.world.on \worldbounds (body) !~>
		body.gameObject.onCollideWorldBounds!
	for i to 8
		pkd = Phaser.Math.RND.pick Pokedexs
		x = Phaser.Math.Between 0 @scale.width
		y = Phaser.Math.Between 0 @scale.height
		d = Phaser.Math.Between 0 3
		pkm = new Pokemon pkd, x, y, d, i % 2

game = new Phaser.Game do
	width: innerWidth
	height: innerHeight
	type: Phaser.AUTO
	scene:
		preload: preload
		create: create
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
