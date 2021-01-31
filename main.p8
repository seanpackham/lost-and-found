pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

title = {
 y = -30,
 bob = 0,
 update = function()
  if btn(4) or btn(5) then state = game
   sfx(-1)
  end

  title.y = clamp(title.y + 1, -30, 28)

  title.bob += 0.01
 end,

 draw = function()
  cls(13)

  sspr(0, 64, 52, 32, 38, title.y)
  sspr(52, 64, 76, 32, 24, title.y + 30)

  if title.y == 28 then
   print("game by jon, sean & kyle", 15, 15, 15)
   print("find the skull on lvl 5", 17, 100, 9)
   print("z or x to start", 34, 115 + sin(title.bob) * 2, 15)
  end
 end
}

function use_pick(i)
 if items[i].uses == 0 then
  -- play no more uses sound
  return
 end

 local tile = tiles[cursor.x][cursor.y]

 if #tile.sprites == 1 then
  items[i].uses -= 1
  add(tile.sprites, dig_tile)

  if tile.e then
   add(tile.sprites, tile.e)

   if tile.e.name == "skull" then
    -- play win sound
    money += tile.e.value
    state = win
   elseif tile.e.type == "loot" then
    -- play find treasure sound
    sfx(6)
    money += tile.e.value
   else
    -- play trigger trap sound
    sfx(4)
    shake += 0.07
    workers -= tile.e.value
   end
  else
   -- play pick grass sound
   sfx(3)
  end
 else
  -- play already dug sound
 end
end

function use_dynamite(i)
 if items[i].uses == 0 then
  -- play no more uses sound
  sfx(7)
  return
 end

 -- play dynamite sound
 sfx(9)
 items[i].uses -= 1
 shake += 0.25

 for x = cursor.x - 1 , cursor.x + 1 do
  for y = cursor.y - 1, cursor.y + 1 do
   local tile = tiles[clamp(x, 1, 8)][clamp(y, 1, 7)]

   if #tile.sprites == 1 then
    add(tile.sprites, dig_tile)

    if tile.e then
     if tile.e.name == "skull" then
      -- play win sound
      money += tile.e.value
      state = win
     elseif tile.e.type == "loot" then
      sfx(6)
      money += tile.e.value
      add(tile.sprites, tile.e)
     else
      -- dyanmite kill critters
      if tile.e.name == "snake" or tile.e.name == "spider" then
        tile.e = nil
      -- still take environment damage
      else
       workers -= tile.e.value
       add(tile.sprites, tile.e)
      end
     end
    -- if entity
    end
   -- if not mined
   end

  end
 end

end

function use_vision(i)
 if items[i].uses == 0 then
  -- play no more uses sound
  sfx(7)
  return
 end

 -- play vision sound
  sfx(8)
 items[i].uses -= 1
 state = vision
 return
end

game = {
 update = function()
  -- movement
  if btnp(0) then cursor.x -= 1 end
  if btnp(1) then cursor.x += 1 end
  if btnp(2) then cursor.y -= 1 end
  if btnp(3) then cursor.y += 1 end

  cursor.x = clamp(cursor.x, 1, 8)
  cursor.y = clamp(cursor.y, 1, 7)

  -- use
  if btnp(4) then
   if item == 1 then
    use_pick(item)
   elseif item == 2 then
    use_dynamite(item)
   elseif item == 3 then
    use_vision(item)
   end
  end

  -- hotkeys
  if btnp(0, 1) then
   -- s
   use_pick(1)
  elseif btnp(3, 1) then
   -- d
   use_dynamite(2)
  elseif btnp(1, 1) then
   -- f
   use_vision(3)
  end

  -- inventory
  if btnp(5) then
   state = inventory
   return
  end

  -- gameover
  if workers <= 0 then
   -- sfx(1)
   state = gameover
   return
  end

  -- win hack to prevent shop triggering
  if state == win then
   return
  end

  -- shop
  if items[1].uses <= 0 and items[2].uses <= 0 then
   state = shop
   return
  end
 end,

 draw = function()
  cls(13)

  -- tiles
  for x = 1, 8 do
   for y = 1, 7 do
    for k, v in pairs(tiles[x][y].sprites) do
     draw_sprite(v.sprite, (x - 1) * 16, (y - 1) * 16)
    end
   end
  end

  -- items
  for k, v in pairs(items) do
   x = (k - 1) * 16
   y = 7 * 16
   draw_sprite(v.sprite, x, y)
   print(v.uses, x + 2, y + 2, 15)
  end

  local ix = item - 1
  local iy = 7 * 16
  rect(ix * 16, iy, ix * 16 + 15, iy + 15, 15)

  -- cursor
  local cx = cursor.x - 1
  local cy = cursor.y - 1
  rect(cx * 16, cy * 16, cx * 16 + 15, cy * 16 + 15, 15)

  -- ui
  ui.draw()

 end
}

vision = {
 delay = 0,

 update = function()
  vision.delay += 1

  if vision.delay > 45 - (level * 3) then
   vision.delay = 0
   state = game
  end
 end,

 draw = function()
  game.draw()

  for x = clamp(cursor.x - 1, 1, 8) , clamp(cursor.x + 1, 1, 8) do
   for y = clamp(cursor.y - 1, 1, 7) , clamp(cursor.y + 1, 1, 7) do
    local tile = tiles[x][y]

    if tile.e then
     draw_sprite(tile.e.sprite, (x - 1) * 16, (y - 1) * 16)
    end
   end
  end
 end
}

inventory = {
 update = function()
  if btnp(0) or btnp(2) then item -= 1 end
  if btnp(1) or btnp(3) then item += 1 end

  item = clamp(item, 1, #items)

  if btnp(4) or btnp(5) then
   state = game
  end
 end,

 draw = function()
  game.draw()

  local ix = item - 1
  local iy = 7 * 16
  rect(ix * 16, iy, ix * 16 + 15, iy + 15, 14)
 end
}

ui = {
 draw = function()
  print("lvl " .. level, 80, 7 * 16 + 2, 7)

  print("😐 " .. workers, 104, 7 * 16 + 2, 7)
  print("$ " .. money, 80, 7 * 16 + 10, 7)
 end
}

function buy_item(i)
 if money >= items[item].value then
  sfx(13)
  money -= items[i].value
  items[i].uses += 1
 end
end

shop = {
 update = function()
  if btnp(0) or btnp(2) then item -= 1 end
  if btnp(1) or btnp(3) then item += 1 end

  item = clamp(item, 1, #items)

  -- buy
  if btnp(4) then
    buy_item(item)
  end

  -- hotkeys
  if btnp(0, 1) then
   -- s
   buy_item(1)
  elseif btnp(3, 1) then
   -- d
   buy_item(2)
  elseif btnp(1, 1) then
   -- f
   buy_item(3)
  end

  -- back to game
  if items[1].uses > 0 or items[2].uses > 0 then
   if btnp(5) then
    level += 1
    next_level()
    state = game
   end
  end
 end,

 draw = function()
  cls(13)
  print("stock up adventurer", 26, 8, 7)
  sspr(80, 32, 32, 32, 32, 12, 64, 64)

  if items[1].uses > 0 or items[2].uses > 0 then
   print("x to exit", 20, 120, 7)
  end

  for k, v in pairs(items) do
   local y = 82
   local z = 7
   print(v.uses, k * 16 + 6, y, 7)
   draw_sprite(v.sprite, k * 16, y + z)
   print("$" .. v.value, k * 16 + 2, y + z + 18, 7)
   rect(item * 16, y + z, item * 16 + 15, y + z + 15, 15)
  end

  ui.draw()
 end
}

gameover = {
 update = function()
  if btnp(4) or btnp(5) then
   _init()
   sfx(-1)
   state = game
  end
 end,

 draw = function()
  game.draw()

  rectfill(20, 40, 108, 88, 0)
  print("game over", 47, 56, 7)
  print("z or x to restart", 31, 68, 7)
 end
}

win = {
 update = function()
  if btnp(4) or btnp(5) then
   _init()
   sfx(-1)
   state = game
  end
 end,

 draw = function()
  game.draw()

  rectfill(20, 40, 108, 88, 9)
  print("skull found!", 40, 56, 7)
  print("z or x to restart", 31, 68, 7)
 end
}

function _init()
 sfx(-1)
 sfx(1)

 -- transparency color
 palt(0, false)
 palt(13, true)

 -- globals
 debug = false
 shake = 0
 entities = {}
 grasses = {}
 items = {}
 cursor = { x = 4, y = 3 }
 item = 1
 level = 1
 workers = 10
 money = 25

 dig_tile = add_tile("dig", 46)
 key_tile = add_tile("key", 36)

 -- entities
 add_loot("coin", 			4, 10, 32)
 add_loot("gold", 			3, 20, 12)
 add_loot("gem", 				2, 25, 34)
 add_loot("chest", 		1, 30, 38)
 -- add_loot("rock", 			4, 5, 2)

 add_loot("skull", 		1, 100, 40)
 skull_entity = entities[#entities]
 del(entities, skull_entity)

 add_trap("snake", 		3, 1, 66)
 add_trap("spikes", 	1, 1, 14)
 add_trap("spider", 	2, 1, 70)
 add_trap("boulder", 2, 2, 72)
 -- add_trap("skull", 		1, 2, 64)

 -- items
 add_item("pick", 				7, 10, 100)
 add_item("bomb", 				2, 40, 98)
 add_item("vision", 		2, 20, 96)
 -- add_item("antidote", 1, 15, 102)

 -- grasses
 add(grasses, add_tile("g1", 4))
 add(grasses, add_tile("g2", 6))
 add(grasses, add_tile("g3", 8))
 add(grasses, add_tile("g4", 10))

 -- generate next world based on level
 next_level()

 state = title
end

function next_level()
 -- globals
 tiles = {}
 spawns = {}
 delay = 0

 -- spawns
 -- todo: change based on level
 for k, e in pairs(entities) do
  for i = 1, e.spawn do
   add(spawns, e)
  end
 end

 -- tiles
 for x = 1, 8 do
  add(tiles, {})

  for y = 1, 7 do
   local tile = {
    sprites = { grasses[flr(rnd(#grasses)) + 1] },
   }

   -- spawn loot or trap
   -- todo: base on level
   if (rnd(1) < 0.65) then
    tile.e = spawns[flr(rnd(#spawns)) + 1]
   end

   add(tiles[x], tile)
  end
 end

 -- if level 5
 if level == 5 then
  tiles[flr(rnd(8)) + 1][flr(rnd(7)) + 1].e = skull_entity
 end

end

function _update()
  state.update()
end

function screen_shake()
  local fade = 0.95
  local x = 16 - rnd(32)
  local y = 16 - rnd(32)

  x *= shake
  y *= shake

  camera(x, y)
  shake *= fade

  if shake < 0.05 then
    shake = 0
  end
end

function _draw()
 screen_shake()

 -- debug
 if debug and (state == game or state == inventory) then
  vision.draw()
 else
   state.draw()
 end
end

function draw_sprite(sprite, x, y)
 local sx = (sprite % 32) * 8
 local sy = flr(sprite / 32) * 16
 sspr(sx, sy, 16, 16, x, y)
end

function add_loot(name, spawn, value, sprite)
 add_entity("loot", name, spawn, value, sprite)
end

function add_trap(name, spawn, value, sprite)
 add_entity("trap", name, spawn, value, sprite)
end

function add_entity(type, name, spawn, value, sprite)
 add(entities, { type = type, name = name, spawn = spawn, value = value, sprite = sprite})
end

function add_tile(name, sprite)
 return { name = name, sprite = sprite }
end

function add_item(name, uses, value, sprite)
 add(items, { name = name, uses = uses, value = value, sprite = sprite })
end

function clamp(value, min, max)
 if value < min then value = 1 end
 if value > max then value = max end
 return value
end

__gfx__
3333333333333333dddddddddddddddd3333333333333333333333333333333333333333333333333333333333333333dddddddddddddddd3333333333333333
3333333333333333dddddddddddddddd3333333333333333333333333333333333333333333333333333333333333333dddddddddddddadd3335455335555333
3335473333333333dddddddddddddddd3333333333a33333333333333333333333333333333333333333333333333333dd7adddddddd97ad3345545533555433
3335497733333333dddddddd5766dddd33333333bbbb3333333333333333333333333333333333333333333333333533d597ddddaddd997d3544555563655553
3335444433333333dddddddd56766ddd33333333b33b3333333333333333333333333333333333333333333333333333d599d597aaad55dd3555565508356553
3335555333347733dddddddd55576ddd3333333333333333333333333333333333333333333333333333333333333333dd55d599aaaadddd35356e855056e653
3333333333549733dddddddd00555ddd3333333333333333333333333333333333333333333333333333333333333333dddddd597aaadddd3355085565508533
3333333333544433dddddddddddddddd3333333333333333333333333333333333333333333333333333333333333333dddddd5997aadddd34555058e6550353
3333333333555533dd5766dddddddddd3333333333333333333333333333333333333333333333333333333333333333dddddd599979dddd3556555065555553
3333333333333333ddd5766ddddddddd3333333333333333333333333333333333333333333333333b53333333333333ddddddd59995dddd3587655505555653
3333333333333333dd5667666ddddddd33333333333333333333333333333333333333333333333333b5553333333333ddd5aaad555ddddd3508555556556e63
3333333333333333dd5556766ddd766d3333333333333333333333333333333333333333333333333333333333333333d597aaaddddddddd355056556e650853
3333547333333333dd0055676ddd576d3333333333333333333333333333333333333333333333333333333333333333d5997aaddddddddd35546e6506545053
3333594333333333ddd00555dddd057d3333333333333333333333b33333333333333333333333333333333333333333d59997addddddddd3545085550554553
3333555333333333dddddddddddddddd3333333333333333333333333333333333333333333333333333333333333333dd5999dddddddddd3355505553355433
3333333333333333dddddddddddddddd3333333333333333333333333333333333333333333333333333333333333333ddd555dddddddddd3333333333333333
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd333333333333b333
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd9aa7dddddddddddddddddddddd33555b3355555533
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddc1777adddddddddddd9aa7ddddddddddddddddddd9dd3545555b35555453
ddddddddddddddddddd011c7777addddddddddddddddddddddddd011111ddddddddc171117addddddddddd9aa7ddddddddddddddddddc9dd3554555535554553
dddddd0977dddddddd011ccccccaaddddddddddddddddddddddd01222221ddddddc171cccccaddddddd1119aa7111ddddddddddddddc10dd3555505535505553
ddddd09aa77dddddd01111ccc777caddddddddddddddddddddd0122224221dddddc11cccccccaddddd119aaaaaa911ddddddddddddd10ddd3545555055055533
dddd09aa7a77ddddd011c11111aac7dddddddddddddddddddd012222222221dddc11cc77a77a7ddddd1119aaaa9111dddddddddddd11dddd3455050500555333
dddd09a7a7a7ddddd011c1cccc7cc7dddddda7dddaa7dddddd01111a0a1111dddc11cc176176cddddd11c19aa911c1ddddddddddd110dddd3555500000054533
dddd097a7a77ddddd0111c1cccacc7dddddaaaaaaa0adddddd01122aaa2211dddc111c156156cddddd1c1119911c11ddddddddddd10ddddd3555550000055553
dddd09a7a7a7dddddd0111c1cacc7ddddd00a0a00aaadddddd011222222211ddddc111cccc7adddddd1111c111c111dddddddddd11dddddd3353550000005553
ddddd09a7a7dddddddd0111cacc7ddddddd0d0dd000ddddddd011242222211dddddcc11ccc7adddddd111c111c11c1dddddddddd10dddddd3b35505000555533
dddddd0999dddddddddd01111c7dddddddddddddddddddddddd01111111110dddddddc17c7c7dddddd11c111c11c11ddddddddd11ddddddd3555555355055453
ddddddd000ddddddddddd01117dddddddddddddddddddddddddd000000000dddddddddc17171dddddddc111c11c11dddd5555501055555dd3554545305545553
dddddddddddddddddddddd017dddddddddddddddddddddddddddddddddddddddddddddd15151ddddddd0000000000ddddd55550005555ddd35455553355545b3
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd55555555dddd3355555b35555b33
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd3333333333333333
dddddddddddddddddddddddddddddddddddddddddddddbbdddddddddddddddddddddd667777ddddddddddddddddddddddddddddddddddddd0000000000000000
ddddddddddddddddddddddddd3337dddbbbbddddddddbdddddd000ddddddddddddd5566656677ddddddddddddddddddddddddddddddddddd0000000000000000
dddd005557dddddddd3bddddd3bbb7dddb333bdddddbbddddd0dd0dddddddddddd556666666667dddddddddddddddddddddddddddddddddd0000000000000000
ddd00555577ddddddd0b7dddd3bbbbddddbb3bbdbbbbdddddd000d006dd00dddd55566666666667ddddddddddddddddddddddddddddddddd0000000000000000
dd0056666667ddddddd03b7d3bbbbb7dddddb33b3bbbddddd0ddd006700dd0ddd55666665665667ddddddddddddddd9494dddddddddddddd0000000000000000
dd05666666667ddddddd03bd3b8bb87dddddbb33bb6bbddddd00d06700000d0d0556665666666667ddddddddddddd444444ddddddddddddd0000000000000000
d005665775776ddddddd0bbd3bbbbb7ddddbb333bb666bbdd0dd0067005dd00d0556666666666667ddddddddddddd444444ddddddddddddd0000000000000000
d055665285286ddddddd3bdb03bbbbdddbb3333b6bb66bdbd0ddd6700000d0dd0555666666656657ddddddddddddd222222ddddddddddddd0000000000000000
d005565885886dddddddb3db033337ddbdb3333bb66b6bddd00d60005500d00d0055666566666667dddddddddddd42022024dddddddddddd0000000000000000
dd0055666666ddddddd3b3db20080dddddb33333bb66bbddd0d0000dddd0d00d0055566666666667dddddddddddd82222228dddddddddddd0000000000000000
ddd000566666dddddddb30bb2228ddddddbb333bb666bddddd0d8080dddd0ddd0055565666566667dddddddddddd84400448dddddddddddd0000000000000000
ddddd0066666dddddd3b0bb22ed8ddddddd33333bbb6bddddd0d000dddd0d0ddd00555666666665dddddddddddd4044444404dddd1ccaddd0000000000000000
dddddd006060dddddd33bb222dddddddddd33b333b6bbdddddd0dddddd00ddddd00555666656655dddddddddd44440400404444ddd1adddd0000000000000000
ddddddd05050dddddd033b22eddddddddbbbdbb333bbdddddddd0dddd00ddddddd005555666655ddddddddddd94044044044044dddcadddd0000000000000000
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
d0effc0000cffe0dddddd88820dddddddddddddc10d067dddddd1bbbbbbadddddddddd1cc7dddddddddd9900ddd1000d0001dddd0099dddd0000000000000000
dd0efcc00cffe0dddddd88820dddddddddddddc10dd06adddddd6777877adddddddddd1cc7dddddddddd9900ddd1100d0011dddd0099dddd0000000000000000
ddd0effccffe0dddddd88820dddddddddddddc10dddd06dddddd6778887adddddddddd1cc7dddddddddd9900ddd1000d0001dddd0099dddd0000000000000000
dddd0effffe0dddddd28820dddddddddddddc10ddddd6ddddddd6777877addddddddddd55ddddddddddd9900dd10000d00001ddd0099dddd0000000000000000
ddddd000000ddddddd0220dddddddddddddc10dddddd6ddddddd1bbbbbbaddddddddddd66ddddddddddd9900d100000d000001dd0099dddd0000000000000000
ddddddddddddddddddd00dddddddddddddd00dddddddddddddddd1ccccaddddddddddddd5dddddddddd59955555555555555555555995ddd0000000000000000
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd6dddddddddd59955555555555555555555995ddd0000000000000000
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000000000000000
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddbddbdddddddddddddd777ddddddddbdddddddddddddddddddddddddddddddddddddddddd
deeeeeedeeddeedeeeeeeddddeeddddeeeeeedeeeeeedeeeeeeddd777b77bddddddd777ddd666dddd77777b77ddddddbddddddddddddbddd777ddddddddddddd
d888888d88dd88d888888dddd88dddd888888d888888d888888ddd666666b67ddddd666ddd666ddd7666666b6ddd77b7ddd7777ddd7b7ddd6667dddd77777ddd
ddd88ddd88dd88d882222dddd88dddd882288d822288d228822ddd666b66a66dddd6666ddd666ddd6666556b6ddd6b663dd6666ddd6b67dd6666ddd7666667dd
ddd88ddd88dd88d88dddddddd88dddd88dd88d8ddd22ddd88ddddd666355b66dddd6676ddd666ddd6660306b6ddd0b56d3d6666ddd6b66dd5566ddd6666666dd
ddd88ddd88ee88d88eedddddd88dddd88dd88d8eeeeeddd88ddddd5665305663ddd6655ddd666ddd666d3d6b67dddb66dd37666dddb6663d0056ddd66666667d
ddd88ddd888888d8888dddddd88dddd88dd88d888888ddd88ddddd6565dd56bdddd6660ddd566ddd566dbd6b77dddb66ddd576633366663dd666ddd666506667
ddd88ddd882288d8822dddddd88dddd88dd88d222288ddd88ddddd6655ddbb77ddd666ddd7756ddd655dbd6b55ddda66ddd0566ddd66553dd666dd3b650d5666
ddd88ddd88dd88d88dddddddd88dddd88dd88deedd88ddd88ddddd6665d35665ddd666ddd6675ddd666dbd0b66ddd566dddd056ddd66503dd666ddd356dd0666
ddd88ddd88dd88d88eeeedddd88eeed88ee88d88ee88ddd88ddddd6665d35657ddd665ddd6675ddd666dbddb66ddd656dddd666ddd666d3dd666ddd63bddd666
ddd88ddd88dd88d888888dddd88888d888888d888888ddd88ddddd6665dd5576ddd657ddd6650ddd666ddbdb66ddd665ddd6666ddd6667d3d666ddd6a63dd666
ddd22ddd22dd22d222222dddd22222d222222d222222ddd22ddddd6665dd5666ddd566ddd666dddd666ddbdb66ddd666ddd6666ddd6666d3d666ddd666ddd566
dddddddddddddddddddddddddddddddddddddddddddddddddddddd5665d3bbbbddd766dab666dddd666ddadb66ddd666ddd6666ddd656673d666dd3666ddd656
dddddddddddddddddddddddddddddddddddddddddddddddddddddd6557776675ddd6667b7666dddd6677ddd366ddd666ddd6766ddd6056673766dddb6addd665
dddddddddddddddddddddddddddddddddddddddddddddddddddddd6656666650ddd666b66666dddd6665ddbb77ddd666ddd5667ddd6556663566ddd6bbddd666
dddddddddddddddddddddddddddddddddddddddddddddddddddddd665666675dddd666b006663ddd6656ddb000dd7766ddd6565ddd660566b576ddd6663dd666
ddddddeeeeeedeedeeeeeedeeddeeddddeeeeeedeeeeeedddddddd665667550dddd667bdd666bddd6566ddb666dd5566ddd6056ddd665566b656ddd666ddd666
dddddd888888d88d888888d88dd88dddd888888d888888dddddddd66665030dddd5666bdd666bddd5666ddb666dd0666ddd6666ddd666566b665ddd566ddd666
dddddd882288d88d228822d88dd88dddd882288d882222dddddddd66550d3ddddd6566bddd76bddd6667ddb666dd6666ddd6666ddd666056a666ddd656ddd666
dddddd88dd88d88ddd88ddd88ee88dddd88dd88d88dddddddddddd5560ddbddddd6655bddd666bdd6665ddb666dd5666ddd6666ddd666d06b666dd3a65ddd666
dddddd88dd22d88ddd88ddd288882dddd88dd88d88eeeddddddddd675dddbdddd366633ddd565bdd6666ddb666dd6676ddd6666ddd666dd56666dddbbbdd7666
dddddd88ddddd88ddd88dddd2882ddddd88dd88d88888ddddddddd665ddbddddddbb6ddddd756bdd6666ddb666dd6656ddd6666ddd666dd56666ddd666376665
dddddd88ddeed88ddd88ddddd88dddddd88dd88d88222ddddddddd665ddbdddddd66b3dddd676bdd6666dd3666dd6666ddd6676ddd666dd05676ddd666766660
dddddd88dd88d88ddd88ddddd88dddddd88dd88d88dddddddddddd655ddadddddd56663ddd666add56677bb566dd66667776656d6d566ddd5656dd366666665d
dddddd888888d88ddd88ddddd88dddddd88ee88d88dddddddddddd555dddddddddb555ddd5555ddd0555535555dd555555555550dd555d6d5555dd355555550d
dddddd888888d88ddd88ddddd88dddddd888888d88dddddddddddd000d666dddddbba0ddd0000d6dd000bb0660dd00000000000ddd0006dd0000dd3b000600dd
dddddd222222d22ddd22ddddd22dddddd222222d22dddddddddddddddd550dddddddddddddddd56dddbbbdd55ddddddd66dddddddddd55ddddddddddbd55dddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddd00ddddddddddddddddd000ddd3ddd00ddddddd665ddddddddd00ddddddddddddbbbbddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddbbbbdddddddddd550dddddddddddddddddddddddddddadd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddbbaddddddd000dddddddddddddddddddddd05ddddddd
__label__
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddffdfffdfffdfffdddddfffdfdfdddddfffddffdffdddddddddddffdfffdfffdffddddddffddddddfdfdfdfdfdddfffdddddddddddddddddd
dddddddddddddddfdddfdfdfffdfdddddddfdfdfdfddddddfddfdfdfdfdddddddddfdddfdddfdfdfdfdddddffddddddfdfdfdfdfdddfdddddddddddddddddddd
dddddddddddddddfdddfffdfdfdffddddddffddfffddddddfddfdfdfdfdddddddddfffdffddfffdfdfdddddffddddddffddfffdfdddffddddddddddddddddddd
dddddddddddddddfdfdfdfdfdfdfdddddddfdfdddfddddddfddfdfdfdfddfddddddddfdfdddfdfdfdfdddddfdfdddddfdfdddfdfdddfdddddddddddddddddddd
dddddddddddddddfffdfdfdfdfdfffdddddfffdfffdddddffddffddfdfdfdddddddffddfffdfdfdfdfdddddfffdddddfdfdfffdfffdfffdddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddeeeeeedeeddeedeeeeeeddddeeddddeeeeeedeeeeeedeeeeeeddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddd888888d88dd88d888888dddd88dddd888888d888888d888888ddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddd88ddd88dd88d882222dddd88dddd882288d822288d228822ddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddd88ddd88dd88d88dddddddd88dddd88dd88d8ddd22ddd88ddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddd88ddd88ee88d88eedddddd88dddd88dd88d8eeeeeddd88ddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddd88ddd888888d8888dddddd88dddd88dd88d888888ddd88ddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddd88ddd882288d8822dddddd88dddd88dd88d222288ddd88ddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddd88ddd88dd88d88dddddddd88dddd88dd88deedd88ddd88ddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddd88ddd88dd88d88eeeedddd88eeed88ee88d88ee88ddd88ddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddd88ddd88dd88d888888dddd88888d888888d888888ddd88ddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddd22ddd22dd22d222222dddd22222d222222d222222ddd22ddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddeeeeeedeedeeeeeedeeddeeddddeeeeeedeeeeeedddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddd888888d88d888888d88dd88dddd888888d888888dddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddd882288d88d228822d88dd88dddd882288d882222dddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddd88dd88d88ddd88ddd88ee88dddd88dd88d88dddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddd88dd22d88ddd88ddd288882dddd88dd88d88eeeddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddd88ddddd88ddd88dddd2882ddddd88dd88d88888ddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddd88ddeed88ddd88ddddd88dddddd88dd88d88222ddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddd88dd88d88ddd88ddddd88dddddd88dd88d88dddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddd888888d88ddd88ddddd88dddddd88ee88d88dddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddd888888d88ddd88ddddd88dddddd888888d88dddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddd222222d22ddd22ddddd22dddddd222222d22dddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddbddbdddddddddddddd777ddddddddbdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddd777b77bddddddd777ddd666dddd77777b77ddddddbddddddddddddbddd777ddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddd666666b67ddddd666ddd666ddd7666666b6ddd77b7ddd7777ddd7b7ddd6667dddd77777ddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddd666b66a66dddd6666ddd666ddd6666556b6ddd6b663dd6666ddd6b67dd6666ddd7666667dddddddddddddddddddddddddddddd
dddddddddddddddddddddddddd666355b66dddd6676ddd666ddd6660306b6ddd0b56d3d6666ddd6b66dd5566ddd6666666dddddddddddddddddddddddddddddd
dddddddddddddddddddddddddd5665305663ddd6655ddd666ddd666d3d6b67dddb66dd37666dddb6663d0056ddd66666667ddddddddddddddddddddddddddddd
dddddddddddddddddddddddddd6565dd56bdddd6660ddd566ddd566dbd6b77dddb66ddd576633366663dd666ddd666506667dddddddddddddddddddddddddddd
dddddddddddddddddddddddddd6655ddbb77ddd666ddd7756ddd655dbd6b55ddda66ddd0566ddd66553dd666dd3b650d5666dddddddddddddddddddddddddddd
dddddddddddddddddddddddddd6665d35665ddd666ddd6675ddd666dbd0b66ddd566dddd056ddd66503dd666ddd356dd0666dddddddddddddddddddddddddddd
dddddddddddddddddddddddddd6665d35657ddd665ddd6675ddd666dbddb66ddd656dddd666ddd666d3dd666ddd63bddd666dddddddddddddddddddddddddddd
dddddddddddddddddddddddddd6665dd5576ddd657ddd6650ddd666ddbdb66ddd665ddd6666ddd6667d3d666ddd6a63dd666dddddddddddddddddddddddddddd
dddddddddddddddddddddddddd6665dd5666ddd566ddd666dddd666ddbdb66ddd666ddd6666ddd6666d3d666ddd666ddd566dddddddddddddddddddddddddddd
dddddddddddddddddddddddddd5665d3bbbbddd766dab666dddd666ddadb66ddd666ddd6666ddd656673d666dd3666ddd656dddddddddddddddddddddddddddd
dddddddddddddddddddddddddd6557776675ddd6667b7666dddd6677ddd366ddd666ddd6766ddd6056673766dddb6addd665dddddddddddddddddddddddddddd
dddddddddddddddddddddddddd6656666650ddd666b66666dddd6665ddbb77ddd666ddd5667ddd6556663566ddd6bbddd666dddddddddddddddddddddddddddd
dddddddddddddddddddddddddd665666675dddd666b006663ddd6656ddb000dd7766ddd6565ddd660566b576ddd6663dd666dddddddddddddddddddddddddddd
dddddddddddddddddddddddddd665667550dddd667bdd666bddd6566ddb666dd5566ddd6056ddd665566b656ddd666ddd666dddddddddddddddddddddddddddd
dddddddddddddddddddddddddd66665030dddd5666bdd666bddd5666ddb666dd0666ddd6666ddd666566b665ddd566ddd666dddddddddddddddddddddddddddd
dddddddddddddddddddddddddd66550d3ddddd6566bddd76bddd6667ddb666dd6666ddd6666ddd666056a666ddd656ddd666dddddddddddddddddddddddddddd
dddddddddddddddddddddddddd5560ddbddddd6655bddd666bdd6665ddb666dd5666ddd6666ddd666d06b666dd3a65ddd666dddddddddddddddddddddddddddd
dddddddddddddddddddddddddd675dddbdddd366633ddd565bdd6666ddb666dd6676ddd6666ddd666dd56666dddbbbdd7666dddddddddddddddddddddddddddd
dddddddddddddddddddddddddd665ddbddddddbb6ddddd756bdd6666ddb666dd6656ddd6666ddd666dd56666ddd666376665dddddddddddddddddddddddddddd
dddddddddddddddddddddddddd665ddbdddddd66b3dddd676bdd6666dd3666dd6666ddd6676ddd666dd05676ddd666766660dddddddddddddddddddddddddddd
dddddddddddddddddddddddddd655ddadddddd56663ddd666add56677bb566dd66667776656d6d566ddd5656dd366666665ddddddddddddddddddddddddddddd
dddddddddddddddddddddddddd555dddddddddb555ddd5555ddd0555535555dd555555555550dd555d6d5555dd355555550ddddddddddddddddddddddddddddd
dddddddddddddddddddddddddd000d666dddddbba0ddd0000d6dd000bb0660dd00000000000ddd0006dd0000dd3b000600dddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddd550dddddddddddddddd56dddbbbdd55ddddddd66dddddddddd55ddddddddddbd55dddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddd00ddddddddddddddddd000ddd3ddd00ddddddd665ddddddddd00ddddddddddddbbbbddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddbbbbdddddddddd550dddddddddddddddddddddddddddadddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddbbaddddddd000dddddddddddddddddddddd05ddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddd999d999d99dd99dddddd999d9d9d999dddddd99d9d9d9d9d9ddd9dddddddd99d99dddddd9ddd9d9d9ddddddd999dddddddddddddddddddd
ddddddddddddddddd9dddd9dd9d9d9d9dddddd9dd9d9d9ddddddd9ddd9d9d9d9d9ddd9ddddddd9d9d9d9ddddd9ddd9d9d9ddddddd9dddddddddddddddddddddd
ddddddddddddddddd99ddd9dd9d9d9d9dddddd9dd999d99dddddd999d99dd9d9d9ddd9ddddddd9d9d9d9ddddd9ddd9d9d9ddddddd999dddddddddddddddddddd
ddddddddddddddddd9dddd9dd9d9d9d9dddddd9dd9d9d9ddddddddd9d9d9d9d9d9ddd9ddddddd9d9d9d9ddddd9ddd999d9ddddddddd9dddddddddddddddddddd
ddddddddddddddddd9ddd999d9d9d999dddddd9dd9d9d999ddddd99dd9d9dd99d999d999ddddd99dd9d9ddddd999dd9dd999ddddd999dddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddfffddddddffdfffdddddfdfdddddfffddffddddddffdfffdfffdfffdfffddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddfdddddfdfdfdfdddddfdfddddddfddfdfdddddfddddfddfdfdfdfddfdddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddfddddddfdfdffdddddddfdddddddfddfdfdddddfffddfddfffdffdddfdddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddfdddddddfdfdfdfdddddfdfddddddfddfdfdddddddfddfddfdfdfdfddfdddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddfffdddddffddfdfdddddfdfddddddfddffddddddffdddfddfdfdfdfddfdddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__sfx__
001400200d0200e5200a7200e520003200e5200032009520115200f5200d5200852008520145200d720003201472019720197200132000320055200a3200b520145201752014720157201e7200a0201402000020
000a002003100274103341002310061001641003300033000510000700294103141003310007000d410023000910000700033002a410304100331003300144100610001700033002b4102e41002310033000b410
001e00200e71010710127100001017510000101f5100001019510000101a71017710127100001022510000101f510000101a7101c7101f710227100001020510000101f510000102051014710117101371019710
0002000003550025500865004650065500665007650096500b550096500a5500d6500d5500e6500c6500000000000000000000000000010000100001000010000100001000000000000000000000000000000000
000200000000000000284101e4100e4100e4101221005420052200e7200722006220052100142005210042100a710097100021001200012000240001200002000570005700024000470002200014000040000400
0002000008030125300a030125300b030125300c030125300f0301353013030135301e0302a530190301b0301903020530192201a2201e2202022022220232202522027220292102b2102f21032210352103a210
000201000000006330053300633007330093300c330133301b33026330333303d3000a30015300263003130000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000000001e4501a4500000000000000000e4500a450000000000000000000000000000000074500345000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000005150050500505005050050500505005050051500615005050050500605007050080500a0500b0500d0500f0501005026350311503315035150371503815037150351502f15028150211501b15000000
00020000000500105002010040000500006000090100b0100e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0014002011410000300d7102831025410010301071016710010300f410000300b7102431021410000300d71013710000300f410000300b710203101d410000300e71012710000300f410000300a7101c31019410
001400000000002210000000000000000032100520000000012100000001210000000000000000022100000000000022100000005210000000000000000042100000000000042100000001210000000000000000
001400200000035310000000000000000323100000000000333100000034310000000000000000323100000000000333100000033310000000000000000333100000000300353100000000300000000000000000
00010000000000000034050370503a0503c0503d0503d050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 0b404242
00 0b0c4344
00 4a0b0c44
00 0a0b0c44
00 0a0b0c44
00 0a0b4344
00 0a4b4344
00 0a424344
00 0b424344
00 0a0b4344
