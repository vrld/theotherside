local function bitmap(bm, pixel_size)
	pixel_size = pixel_size or 1
	local h = #bm
	local w = #bm[1]
	local id = love.image.newImageData(w*pixel_size, h*pixel_size)

	id:mapPixel(function(x,y)
		x = math.floor(x/pixel_size)+1
		y = math.floor(y/pixel_size)+1
		local row = bm[y]
		assert(#row == w)
		if row:sub(x,x) == ' ' then
			return 0,0,0,0
		end
		return 255,255,255,255
	end)

	local img = love.graphics.newImage(id)
	img:setFilter('nearest', 'nearest')
	return img
end

Image.manpac = {}
Image.manpac.ghost = bitmap{
"    ########    ".."    ########    ",
"  ############  ".."  ############  ",
" ############## ".." ############## ",
"################".."################",
"####  ####  ####".."###   ####   ###",
"###    ##    ###".."###   ####   ###",
"###    ##    ###".."###   ####   ###",
"####  ####  ####".."################",
"################".."################",
"################".."################",
"################".."################",
"################".."################",
"################".."################",
"################".."################",
"## #### #### ###".."### #### #### ##",
"#   ##   ##   ##".."##   ##   ##   #",
}

-- binary code for wall neighbors:
-- 0001 - right neighbor
-- 0010 - bottom neighbor
-- 0100 - left neighbor
-- 1000 - top neighbor
Image.manpac.walls = {
	['^'] = bitmap{
		'########',
		'        ',
		'        ',
		'########',
		'        ',
		'        ',
		'        ',
		'        ',
	},
	['_'] = bitmap{
		'        ',
		'        ',
		'        ',
		'        ',
		'########',
		'        ',
		'        ',
		'########',
	},
	['-'] = bitmap{
		'        ',
		'        ',
		'        ',
		'        ',
		'########',
		'########',
		'########',
		'        ',
	},
	['j'] = bitmap{
		'    ####',
		'  ##    ',
		' #      ',
		' #   ###',
		'#   #   ',
		'#  #    ',
		'#  #    ',
		'#  #    ',
	},
	['a'] = bitmap{
		'        ',
		'        ',
		'        ',
		'        ',
		'      ##',
		'     #  ',
		'    #   ',
		'    #  #',
	},
	['k'] = bitmap{
		'####    ',
		'    ##  ',
		'      # ',
		'###   # ',
		'   #   #',
		'    #  #',
		'    #  #',
		'    #  #',
	},
	['s'] = bitmap{
		'        ',
		'        ',
		'        ',
		'        ',
		'##      ',
		'  #     ',
		'   #    ',
		'#  #    ',
	},
	['u'] = bitmap{
		'#  #    ',
		'#  #    ',
		'#  #    ',
		'#   #   ',
		' #   ###',
		' #      ',
		'  ##    ',
		'    ####',
	},
	['q'] = bitmap{
		'    #  #',
		'    #   ',
		'     #  ',
		'      ##',
		'        ',
		'        ',
		'        ',
		'        ',
	},
	['i'] = bitmap{
		'    #  #',
		'    #  #',
		'    #  #',
		'   #   #',
		'###   # ',
		'      # ',
		'    ##  ',
		'####    ',
	},
	['w'] = bitmap{
		'#  #    ',
		'   #    ',
		'  #     ',
		'##      ',
		'        ',
		'        ',
		'        ',
		'        ',
	},
	['t'] = bitmap{
		'#  #    ',
		'#  #    ',
		'#  #    ',
		'#   #   ',
		'#    ###',
		'#       ',
		'#       ',
		'#       ',
	},
	['y'] = bitmap{
		'#       ',
		'#       ',
		'#       ',
		'#       ',
		'#   ####',
		'#  #    ',
		'#  #    ',
		'#  #    ',
	},
	['g'] = bitmap{
		'    #  #',
		'    #  #',
		'    #  #',
		'   #   #',
		'###    #',
		'       #',
		'       #',
		'       #',
	},
	['h'] = bitmap{
		'       #',
		'       #',
		'       #',
		'       #',
		'####   #',
		'    #  #',
		'    #  #',
		'    #  #',
	},
	['N'] = bitmap{
		'        ',
		'        ',
		'        ',
		'        ',
		'########',
		'        ',
		'        ',
		'        ',
	},
	['M'] = bitmap{
		'        ',
		'        ',
		'        ',
		'########',
		'        ',
		'        ',
		'        ',
		'        ',
	},
	['|'] = bitmap{
		'    #   ',
		'    #   ',
		'    #   ',
		'    #   ',
		'    #   ',
		'    #   ',
		'    #   ',
		'    #   ',
	},
	['<'] = bitmap{
		'#  #    ',
		'#  #    ',
		'#  #    ',
		'#  #    ',
		'#  #    ',
		'#  #    ',
		'#  #    ',
		'#  #    ',
	},
	['>'] = bitmap{
		'    #  #',
		'    #  #',
		'    #  #',
		'    #  #',
		'    #  #',
		'    #  #',
		'    #  #',
		'    #  #',
	},
	['U'] = bitmap{
		'    #   ',
		'    #   ',
		'    #   ',
		'     #  ',
		'      ##',
		'        ',
		'        ',
		'        ',
	},
	['I'] = bitmap{
		'    #   ',
		'    #   ',
		'    #   ',
		'   #    ',
		'###     ',
		'        ',
		'        ',
		'        ',
	},
	['7'] = bitmap{
		'        ',
		'        ',
		'        ',
		'        ',
		'      ##',
		'     #  ',
		'    #   ',
		'    #   ',
	},
	['8'] = bitmap{
		'        ',
		'        ',
		'        ',
		'        ',
		'###     ',
		'   #    ',
		'    #   ',
		'    #   ',
	},
	['1'] = bitmap{
		'        ',
		'        ',
		'        ',
		'        ',
		'     111',
		'    1   ',
		'    1   ',
		'    1  1',
	},
	['2'] = bitmap{
		'        ',
		'        ',
		'        ',
		'        ',
		'222     ',
		'   2    ',
		'   2    ',
		'2  2    ',
	},
	['3'] = bitmap{
		'    3  3',
		'    3   ',
		'    3   ',
		'     333',
		'        ',
		'        ',
		'        ',
		'        ',
	},
	['4'] = bitmap{
		'4  4    ',
		'   4    ',
		'   4    ',
		'444     ',
		'        ',
		'        ',
		'        ',
		'        ',
	},
	['+'] = bitmap{
		'        ',
		'        ',
		'        ',
		'        ',
		'        ',
		'        ',
		'        ',
		'        ',
	},
}

Image.invaders = {}
Image.invaders.shot = bitmap{
	"p  p",
	"e  e",
	" ww ",
	" pp ",
	"e  e",
	"w  w"
}

Image.invaders.hero = bitmap{
	"       T       ",
	"      HIS      ",
	"  _GUY_IS_THE  ",
	" _HERO_OF_THIS ",
	" _STORY._DONT_ ",
	" LET_HIM_LOSE! ",
}

Image.invaders.aliens = bitmap{
	"               ".."               ",
	"               ".."               ",
	"      ha       ".."      ve       ",
	"     you_      ".."     ever_     ",
	"    wonder     ".."    ed_why     ",
	"   th e_ in    ".."   va de rs    ",
	"   attacked    ".."   us?_mayb    ",
	"     e  _      ".."    t he y     ",
	"    a re _     ".."   j      u    ",
	"   s t  _ e    ".."    v    i     ",
	"               ".."               ",
	"               ".."               ",
	------------------------------------
	"               ".."               ",
	"               ".."               ",
	"    l     .    ".."    o     r    ",
	"  m  a   y  b  ".."     e   _     ",
	"  t hey_nee d  ".."    a_new_p    ",
	"  lan et_ to_  ".."   li ve. if   ",
	"  so,_they_co  ".."  uld_have_ju  ",
	"   st_asked_   ".."  u s,_righ t  ",
	"    ?     o    ".."  r m     a y  ",
	"   b       e   ".."     th ey     ",
	"               ".."               ",
	"               ".."               ",
	------------------------------------
	"               ".."               ",
	"               ".."               ",
	"     did_      ".."     but_      ",
	"  we_said_'n   ".."  o_way_you_   ",
	" creeps_are_c  ".." oming_in!'_a  ",
	" nd_  no  w_t  ".." hey  ar  e_d  ",
	" esperately_t  ".." rying_to_sur  ",
	"    vi  ve     ".."   ...  doe    ",
	"   s_ it _m    ".."  at  te  r_   ",
	" th        ou  ".."   gh    ??    ",
	"               ".."               ",
	"               ".."               ",
}
