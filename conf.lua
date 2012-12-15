function love.conf(t)
	t.title             = "The other side"
	t.author            = "vrld"
	t.url               = "http://vrld.org/"
	t.identity          = "SpaceOut"
	--t.release           = true

	t.modules.physics   = false

	t.screen.width      = 800
	t.screen.height     = 600
	t.screen.fullscreen = false
	t.screen.fsaa       = 0
	t.screen.vsync      = false
end
