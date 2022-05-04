var game, scene

function preload
	scene := @

function create
	=>

game = new Phaser.Game do
	width: 1366
	height: 768
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
			gravity:
				y: 0
			debug: no
	scale:
		mode: Phaser.Scale.RESIZE
