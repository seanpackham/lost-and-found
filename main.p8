pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

debug=false

world = nil
probs = nil
gameover=false
shop=false
delay=0

inventory = {}
selected=1
level = 1
workers = 4
money = 100

grass = {}
items = {}
tiles = {}

up=false
down=false
left=false
right=false
zz=false
xx=false

c = {x=4, y=3}

-- special item

key = {
	treasure=true,
	name="key",
	p=1,
	value=1,
	s=36
}

dug = {
	name="dug",
	p=1,
	value=1,
	s=46
}

-- grass

add(grass, {
	t="tile",
	name="grass1",
	p=1,
	value=0,
	s=4
})

add(grass, {
	t="tile",
	name="grass2",
	p=2,
	value=0,
	s=6
})

add(grass, {
	t="tile",
	name="grass3",
	p=1,
	value=0,
	s=8
})

add(grass, {
	t="tile",
	name="grass4",
	p=1,
	value=0,
	s=10
})

-- random spawn tiles

add(tiles, {
	treasure=true,
	name="rock1",
	p=1,
	value=1,
	s=2
})

add(tiles, {
	treasure=true,
	name="rock2",
	p=1,
	value=1,
	s=2
})

-- treasure

add(tiles, {
	treasure=true,
	name="gold",
	p=3,
	value=1,
	s=12
})

add(tiles, {
	treasure=true,
	name="skull",
	p=1,
	value=3,
	s=64
})

add(tiles, {
	treasure=true,
	name="chest",
	p=1,
	value=3,
	s=38
})

-- traps

add(tiles, {
	trap=true,
	name="snake",
	p=1,
	damage=1,
	s=66
})

add(tiles, {
	trap=true,
	name="spikes",
	p=1,
	damage=2,
	s=14
})

-- items

add(items, {
	item=true,
	name="pickaxe",
	p=2,
	uses=7,
	area=1,
	s=100
})


add(items, {
	item=true,
	name="dynamite",
	p=1,
	uses=1,
	area=2,
	s=98
})

add(items, {
	item=true,
	name="vision",
	p=2,
	uses=3,
	area=0,
	s=96
})

function worldgen()
	world = {}
	gameover=false
	shop=false
	delay=0

	-- tile spawn probability
	for k,tile in pairs(tiles) do
		for i=1,tile.p do
			-- print(tile.name)
			add(probs, tile)
		end
	end

	-- level spawn
	for x=1,8 do
		add(world, {})
		for y=1,8 do
			tile = {
				g=grass[flr(rnd(#grass))+1],
				t=nil,
				dug=false
			}

			-- 75% chance to spawn an item
			if (rnd(1) < 0.60) then
				tile.t=probs[flr(rnd(#probs))+1]
			end

			add(world[x], tile)
		end
 end
end

function _init()
	-- music(0)

	inventory = {}
	probs = {}
	selected=1
	level = 1
	workers = 4
	money = 100

	-- draw black pixels
	palt(0, false)
	palt(13, true)

	-- starting inventory
	-- pick
	add(inventory, { uses=items[1].uses, t=items[1] })
	-- dynamite
	add(inventory, { uses=items[2].uses, t=items[2] })
	-- vision
	add(inventory, { uses=items[3].uses, t=items[3] })

	worldgen()
end


function _update()

	-- game over
	if workers <= 0 then
		gameover=true
		-- play gameover sound
	end

	if gameover then
		if (not xx and btn(5)) then
			_init()

		end

		return
	end

	-- shop

	if inventory[1].uses <= 0 then
		shop=true
		-- play shop sound
	end

	if shop then
			delay+=1

			if delay > 30*2 then
				-- shop logic

				-- buy

				-- exit
				if (not xx and btn(5)) then
					worldgen()

					-- temp
					inventory[1].uses=9
				end
			end

			return
	end

	-- game

	if (not left and btn(0)) then
		c.x = c.x-1
	end

	if (not right and btn(1)) then
		c.x = c.x+1
	end

	if (not up and btn(2)) then
		c.y = c.y-1
	end

	if (not down and btn(3)) then
		c.y = c.y+1
	end

	if c.x<1 then c.x=1 end
	if c.x>8 then c.x=8 end
	if c.y<1 then c.y=1 end
	if c.y>8 then c.y=8 end

	if (not zz and btn(4)) then

		if inventory[selected].uses <= 0 then
			return
			-- play no more uses sound
		end

		tile=world[c.x][c.y]

		if tile.dug then
			-- play already dug sound
			sfx(7)
		else
			world[c.x][c.y].dug=true
			inventory[selected].uses-= 1

			-- just grass
			if not tile.t then
				sfx(3)
			else

				if tile.t.treasure then
					-- play treasure sound
					sfx(6)
					money += tile.t.value
				end
				if tile.t.trap then
					-- play trap soundz
					sfx(4)
					workers -= tile.t.damage
				end

			end
		end
	end

	if (not xx and btn(5)) then
		debug=not debug
	end

	-- old buttons
	left=btn(0)
	right=btn(1)
	up=btn(2)
	down=btn(3)
	zz=btn(4)
	xx=btn(5)
end


function draw_sprite(s, x, y)
	sx=(s%32)*8
	sy=flr(s/32)*16
	sspr(sx,sy,16,16, x,y)
end

function _draw()
	cls(13)

	if shop and delay > 30*2 then
		print("do you have treasure to trade?", 4, 8, 7)
		sspr(0,64,32,32, 32,12,64,64)
		print("x to leave", 44, 120, 7)
		return
	end

	-- world
 for x=1,8 do
		for y=1,7 do
			tx=x-1
			ty=y-1

			-- grass tile
			s=world[x][y].g.s
			sx=(s%32)*8
			sy=flr(s/32)*16
			draw_sprite(s, tx*16, ty*16)

			tile=world[x][y]

			if debug or tile.dug then
				if tile.dug then
					s=dug.s
					sx=(s%32)*8
					sy=flr(s/32)*16
					draw_sprite(s, tx*16, ty*16)
				end

				if tile.t then
					s=tile.t.s
					sx=(s%32)*8
					sy=flr(s/32)*16
					draw_sprite(s, tx*16, ty*16)
				end
			end
		end
 end

	-- inventory
	for i=1,#inventory do
			x=(i-1)*16
			y=7*16
			s=inventory[i].t.s
			sx=(s%32)*8
			sy=flr(s/32)*16
			draw_sprite(s, x, y)
			print(inventory[i].uses, x+1, y+1)

			-- if selected == i then
			-- 	rect(x,y,16,16,15)
			-- end
	end

	-- ui
	print("😐 " .. workers, 90, 7*16+2)
	print("$ " .. money, 90, 7*16+10)

	-- cursor
	cx = c.x-1
	cy = c.y-1
	rect(cx*16,cy*16,cx*16+15,cy*16+15,15)

	if workers <= 0 then
		rectfill(28, 28, 100, 100, 1)
		print("game over", 47, 58, 7)
		print("x to restart", 42, 70, 7)

	end
end

__gfx__
333333333333b333dddddddddddddddd3333333333333333333333333333333333333333333333333333333333333333dddddddddddddddd3333333333333333
3333333333333333dddddddddddddddd3333333333333333333333333333333333333333333333333333333333333333dddddddddddddadd3335455335555333
3335473333333333dddddddddddddddd3333b33333a333333b3333333333333333333333333333333333b33333333333dd7adddddddd97ad3345545533555433
3335497733333333dddddddd5766dddd33333333bbbb3333333333333333333333b3333333333a33333333333333b333d597ddddaddd997d3544555563655553
3335444433333333dddddddd56766ddd33333333b33b3333333333333333333333333333333333333333333333333333d599d597aaad55dd3555565508356553
3335555333347733dddddddd55576ddd3333333333333333333333333333b33333333333333333333333333333333333dd55d599aaaadddd35356e855056e653
3333333333549733dddddddd00555ddd33333333333333333333333b3333333333333333333333333333333333333333dddddd597aaadddd3355085565508533
333b333333544433dddddddddddddddd3333b3333333333b333333333333333333333333333333333354444333333333dddddd5997aadddd34555058e6550353
3333333333555533dd5766dddddddddd333b333333333333333333333333333333333333b33333333354499433333333dddddd599979dddd3556555065555553
3333333333333333ddd5766ddddddddd333333333b333333333333333333333333333333333333333355449433333333ddddddd59995dddd3587655505555653
3333333333333333dd5667666ddddddd3333333333333333333333333b33333333333333333333333335444333333333ddd5aaad555ddddd3508555556556e63
354733b3333333b3dd5556766ddd766d33333a3333333333333333333333333333333333333333333333553333333333d597aaaddddddddd355056556e650853
3594333333333333dd0055676ddd576d333bbb3333333333333333333333333333b33333333333333333333333333333d5997aaddddddddd35546e6506545053
3555333333567333ddd00555dddd057d33333bb333333b333333333333333333333333333333a3333333333333333333d59997addddddddd3545085550554553
333333333356a333dddddddddddddddd3333333333333333333b3333333333333333333333333333333333333b333333dd5999dddddddddd3355505553355433
3333333333555333dddddddddddddddd333333333333333333333333333333b333333333333333333333333333333333ddd555dddddddddd3333333333333333
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd333333333333b333
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd9aa7dddddddddddddddddddddd33555b3355555533
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddc1777adddddddddddd9aa7ddddddddddddddddddd9dd3545555b35555453
ddddddddddddddddddd011c7777adddddddddddddddddddddddddddddddddddddddc171117addddddddddd9aa7ddddddddddddddddddc9dd3554555535554553
dddddd0977dddddddd011ccccccaadddddddddddddddddddddddd011111dddddddc171cccccaddddddd1119aa7111ddddddddddddddc10dd3555505535505553
ddddd09aa77dddddd01111ccc777cadddddddddddddddddddddd01222221ddddddc11cccccccaddddd119aaaaaa911ddddddddddddd10ddd3545555055055533
dddd09aa7a77ddddd011c11111aac7ddddddddddddddddddddd0122224221ddddc11cc77a77a7ddddd1119aaaa9111dddddddddddd11dddd3455050500555333
dddd09a7a7a7ddddd011c1cccc7cc7dddddda7dddaa7dddddd012222222221dddc11cc176176cddddd11c19aa911c1ddddddddddd110dddd3555500000054533
dddd097a7a77ddddd0111c1cccacc7dddddaaaaaaa0adddddd01111a0a1111dddc111c156156cddddd1c1119911c11ddddddddddd10ddddd3555550000055553
dddd09a7a7a7dddddd0111c1cacc7ddddd00a0a00aaadddddd01122aaa2211ddddc111cccc7adddddd1111c111c111dddddddddd11dddddd3353550000005553
ddddd09a7a7dddddddd0111cacc7ddddddd0d0dd000ddddddd011222222211dddddcc11ccc7adddddd111c111c11c1dddddddddd10dddddd3b35505000555533
dddddd0999dddddddddd01111c7ddddddddddddddddddddddd011242222211dddddddc17c7c7dddddd11c111c11c11ddddddddd11ddddddd3555555355055453
ddddddd000ddddddddddd01117ddddddddddddddddddddddddd01111111110ddddddddc17171dddddddc111c11c11dddd5555501055555dd3554545305545553
dddddddddddddddddddddd017ddddddddddddddddddddddddddd000000000dddddddddd15151ddddddd0000000000ddddd55550005555ddd35455553355545b3
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd55555555dddd3355555b35555b33
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd3333333333333333
dddddddddddddddddddddddddddddddddddddddddddddbbdddddddddddddddddddddd667777ddddddddddddddddddddddddddddddddddddd0000000000000000
ddddddddddddddddddddddddd3337dddbbbbddddddddbdddddd555ddddddddddddd5566656677ddddddddddddddddddddddddddddddddddd0000000000000000
dddd005557dddddddd3bddddd3bbb7dddb333bdddddbbddddd5dd5dddddddddddd556666666667dddddddddddddddddddddddddddddddddd0000000000000000
ddd00555577ddddddd0b7dddd3bbbbddddbb3bbdbbbbdddddd555d506dd55dddd55566666666667ddddddddddddddddddddddddddddddddd0000000000000000
dd0056666667ddddddd03b7d3bbbbb7dddddb33b3bbbddddd5ddd506005dd5ddd55666665665667ddddddddddddddd4444dddddddddddddd0000000000000000
dd05666666667ddddddd03bd3b8bb87dddddbb33bb6bbddddd55d06000555d5d0556665666666667dddddddddd2dd444444dd2dddddddddd0000000000000000
d005665775776ddddddd0bbd3bbbbb7ddddbb333bb666bbdd5dd5060005dd55d0556666666666667ddddddddddd2d444444d2ddddddddddd0000000000000000
d055665285286ddddddd3bdb03bbbbdddbb3333b6bb66bdbd5ddd6000505d5dd0555666666656657ddddddd22dd2d555555d2dd22ddddddd0000000000000000
d005565885886dddddddb3db033337ddbdb3333bb66b6bddd55d60005005d55d0055666566666667dddddddd22dd45055054dd22dddddddd0000000000000000
dd0055666666ddddddd3b3db20080dddddb33333bb66bbddd5d5000dddd5d55d0055566666666667dddd22ddd22d85555558d22dd222dddd0000000000000000
ddd000566666dddddddb30bb2228ddddddbb333bb666bddddd5d8080dddd5ddd0055565666566667ddddd2222d2284444448222222dddddd0000000000000000
ddddd0066666dddddd3b0bb22ed8ddddddd33333bbb6bddddd5d000dddd5d5ddd00555666666665ddddddddd2224044aa440122dd1ccaddd0000000000000000
dddddd006060dddddd33bb222dddddddddd33b333b6bbdddddd5dddddd55ddddd00555666656655dddddddddd44440488404444ddd1adddd0000000000000000
ddddddd05050dddddd033b22eddddddddbbbdbb333bbdddddddd5dddd55ddddddd005555666655ddddddddddd94044088044044dddcadddd0000000000000000
ddddddddddddddddddd033333dddddddbddddddbbbdbddddddddddddddddddddddd0005555555ddddddffffdd44044400444049dddcadddd0000000000000000
dddddddddddddddddddd0000ddddddddbdddddddddddbbbdddddddddddddddddddddd000005dddddddffffffd94404444440444dd1bbaddd0000000000000000
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddff555d44404444440449dd677addd0000000000000000
ddddddddddddddddddddddddddddddddddddddddddddddddddddd1cccaaddddddddddddddddddddddddfffffd444e000000ee44dd677addd0000000000000000
ddddddddddddddddddddddddddddddddddddddddddddddddddddd11111adddddddd222666622eddddd9fffff904e224999422e0991bba9dd0000000000000000
ddddddddddddddddddddddddddd4ddddddddd6667ddddddddddddd1ccadddddddddddd1111dddddddd900f5f9900244494442099901a09dd0000000000000000
dddddeeeeeeddddddddddddddd40ddddddddddd066a7dddddddddd1ccadddddddddddd1cc7dddddddd9990009999044494440999990099dd0000000000000000
ddddefffffffeddddddddddd280ddddddddddddd05667ddddddddd1ccadddddddddddd1cc7dddddddd9999999999900090009999999999dd0000000000000000
dddeffccccfffeddddddddd8288dddddddddddddd056adddddddd1ccccaddddddddddd1cc7dddddddd0000000000000000000000000000dd0000000000000000
ddeffc0007cfffeddddddd88820dddddddddddddc00567dddddd1bbbbbbadddddddddd1cc7dddddddddd0000ddd0000d0000dddd0000dddd0000000000000000
d0effc0000cffe0dddddd88820dddddddddddddc10d067dddddd1bbbbbbadddddddddd1cc7dddddddddd9900ddd0000d0000dddd0099dddd0000000000000000
dd0efcc00cffe0dddddd88820dddddddddddddc10dd06adddddd6777877adddddddddd1cc7dddddddddd9900ddd0000d0000dddd0099dddd0000000000000000
ddd0effccffe0dddddd88820dddddddddddddc10dddd06dddddd6778887adddddddddd1cc7dddddddddd9900ddd0000d0000dddd0099dddd0000000000000000
dddd0effffe0dddddd28820dddddddddddddc10ddddd6ddddddd6777877addddddddddd55ddddddddddd9900ddd0000d0000dddd0099dddd0000000000000000
ddddd000000ddddddd0220dddddddddddddc10dddddd6ddddddd1bbbbbbaddddddddddd66ddddddddddd9900ddd0000d0000dddd0099dddd0000000000000000
ddddddddddddddddddd00dddddddddddddd00dddddddddddddddd1ccccaddddddddddddd5dddddddddd59955550000555000055555995ddd0000000000000000
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd6dddddddddd59955555555555555555555995ddd0000000000000000
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
001400200d0200e5200a7200e520003200e5200032009520115200f5200d5200852008520145200d720003201472019720197200132000320055200a3200b520145201752014720157201e7200a0201402000020
000a002003100274103341002310061001641003300033000510000700294103141003310007000d410023000910000700033002a410304100331003300144100610001700033002b4102e41002310033000b410
001e00200e71010710127100001017510000101f5100001019510000101a71017710127100001022510000101f510000101a7101c7101f710227100001020510000101f510000102051014710117101371019710
0002000003550025500865004650065500665007650096500b550096500a5500d6500d5500e6500c6500000000000000000000000000010000100001000010000100001000000000000000000000000000000000
000200000000000000284101e4100e4100e4101221005420052200e7200722006220052300143005230042300a730097300023001250012500245001250002500575005750024500475002250014500045000450
0002000008050125500a050125500b050125500c050125500f0501355013050135501e0502a550190501b0501905020550192501a2501e2502025022250232502525027250292502b2502f25032250352503a250
00100000000000d2500e10000000000000000000000222500000000000292502a1502c2502e150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000000001e4501a4500000000000000000e4500a450000000000000000000000000000000074500345000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007000005150050500505005050050500505005050051500615005050050500605007050080500a0500b0500d0500f0501005026350311503315035150371503815037150351502f15028150211501b15000000
__music__
00 02404242
00 02404344
00 00414344
00 01424344
00 01004344

