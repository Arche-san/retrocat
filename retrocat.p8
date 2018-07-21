pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--main
ground_y = 96
scaffolding_y = 24

rock_push_force = 0.5
rock_push_time = 15
rock_damage = 10

cat_push_range = 6
cat_hpush_freeze = 5
cat_vpush_freeze = 5

building_life_max = 100

function _init()
 rock_create(20,24)
 building = building_init()
 cat = cat_init()
 demolisher = demolisher_init()
end

function _update60()
 building_update(building)
 cat_update(cat)
 demolisher_update(demolisher)
 foreach(rocks_arr, rock_update)
end

function _draw()
 palt(0, false)
 bg_draw()
 bulding_draw(building)
 cat_draw(cat)
 demolisher_draw(demolisher)
 foreach(rocks_arr, rock_draw)
end

-->8
-- cat
function cat_init()
 return {
  x = 64,
  y = scaffolding_y,
  spr_flip = false,
  freeze = -1
  }
end

function cat_update(c)
 if c.freeze > 0 then
		c.freeze -= 1
  return
 end

 if btn(1) then
  c.x += 0.5
  c.spr_flip = false
 elseif btn(0) then
  c.x -= 0.5
  c.spr_flip = true
 end

 -- move bounds
 if(c.x > 124) c.x = 124
 if(c.x < 4) c.x = 4

 -- hpush
 if btnp(5) then
  c.freeze = cat_hpush_freeze
  rock = rocks_getclosest(c.x, cat_push_range)
  if rock != nil then
   local dir = 1
   if (c.spr_flip) dir = -1
   rock_push(rock, dir)
  end
 end

 -- vpush
 if btnp(4) then
  c.freeze = cat_vpush_freeze
  rock = rocks_getclosest(c.x, cat_push_range)
  if rock != nil then
   rock_fall(rock)
  end
 end
end

function cat_draw(c)
 palt(7, true)
 sspr(8,0,8,8,c.x-4,c.y-8,8,8,c.spr_flip)
 --spr(1, c.x - 4, c.y - 8, 1, 1, c.spr_flip)
 palt(7, false)
end

-->8
-- building
function building_init()
 return {
  life = 100,  
 }
end

function building_update(b)
end

function bulding_draw(b)
 -- building
 rect(70,50,110,96,0)

 -- gauge
 local gauge_min = 75
 local gauge_max = 105
 rect(gauge_min-1,44,gauge_max+1,48,0)
 if b.life > 0 then
  local gauge_ratio = 1 - b.life / building_life_max
  local gauge_val = gauge_min + flr(gauge_ratio * (gauge_max - gauge_min))
  rectfill(gauge_val,45,105,47,8)
 end
end

function building_hit(b, damage)
 b.life -= damage
end

function collide_with_building(x,y)
 return x >= 70 and x <= 110 and y >=50 and y <= 96
end

-->8
-- demolisher
demolisher_state_idle = 1
demolisher_state_move = 2
demolisher_state_loading = 3
demolisher_state_attack = 4
demolisher_state_stun = 5

function demolisher_init()
 return {
  x = 20,
  y = ground_y,
  cx = -8,
  cy = -16,
  cw = 16,
  ch = 16,
  state = demolisher_state_idle,
  state_time = 0
 }
end

function demolisher_update(d)
 local state = d.state
 local state_time = d.state_time

 state_time += 1
 d.state_time = state_time

 if state == demolisher_state_idle then
  if(state_time >= 300) demolisher_move(d)
 
 elseif state == demolisher_state_move then
  d.x += 0.5
  if(d.x >= 40) demolisher_loading(d)
  if(state_time >= 30) demolisher_idle(d)
 
 elseif state == demolisher_state_loading then
  if(state_time >= 300) demolisher_attack(d)
 
 elseif state == demolisher_state_attack then
  if(state_time >= 180) demolisher_loading(d)

 elseif state == demolisher_state_stun then
  d.x -= 1
  if(state_time >= 30) demolisher_idle(d)
 end

end

function demolisher_draw(d)
 spr(3, d.x-8, d.y-16, 2, 2)

 local cx_start = d.x + d.cx
 local cx_end = cx_start + d.cw
 local cy_start = d.y + d.cy
 local cy_end = cy_start + d.ch
 rect(cx_start, cy_start, cx_end, cy_end, 11)

 print(d.state, 0, 0)
end

function demolisher_idle(d)
 demolisher_setstate(d, demolisher_state_idle)
end

function demolisher_move(d)
 demolisher_setstate(d, demolisher_state_move)
end

function demolisher_loading(d)
 demolisher_setstate(d, demolisher_state_loading)
end

function demolisher_attack(d)
 building_hit(building, 10)
 demolisher_setstate(d, demolisher_state_attack)
end

function demolisher_stun(d)
 demolisher_setstate(d, demolisher_state_stun)
end

function demolisher_setstate(d, state)
 d.state = state
 d.state_time = 0
end

function collide_with_demolisher(d,x,y)
 local cx_start = d.x + d.cx
 local cx_end = cx_start + d.cw
 local cy_start = d.y + d.cy
 local cy_end = cy_start + d.ch
 return x >= cx_start and x <= cx_end and y >= cy_start and y <= cy_end
end

-->8
-- rock
rocks_arr = {}
rock_state_push = 1
rock_state_fall = 2

function rock_create(x, y)
 r = {
  x = x,
  y = y,
  state = 0
 }

 add(rocks_arr, r)
 return r
end

function rock_update(r)
 
 if r.state == rock_state_fall then
  r.y += 1

  if collide_with_building(r.x, r.y) then
   building_hit(building, rock_damage)
   destroy = true
  elseif collide_with_demolisher(demolisher, r.x, r.y) then
   demolisher_stun(demolisher)
   destroy = true
  elseif r.y > ground_y then
   destroy = true
  end

  if destroy then
   del(rocks_arr, r)
  end

 elseif r.state == rock_state_push then
  r.x += r.push_dir * rock_push_force
  r.push_time += 1
  if (r.push_time >= rock_push_time) r.state = 0
 end

 if(r.x > 124) r.x = 124
 if(r.x < 4) r.x = 4
end

function rock_push(r, dir)
 r.push_dir = dir
 r.push_time = 0
 r.state = rock_state_push
end

function rock_fall(r)
 r.state = rock_state_fall
end

function rock_draw(r)
 palt(7, true)
 spr(2, r.x-4, r.y-8, 1, 1)
 palt(7, false)
end

function rocks_getclosest(x,range)
 local bestrock = nil
 local bestdist = 128
 for i=1,#rocks_arr do
  r = rocks_arr[i]
  local dist = abs(r.x - x)
  if dist <= range and dist < bestdist then
   bestrock = r
   bestdist = dist
  end
 end
 return bestrock
end

-->8
-- background
function bg_draw()
 rectfill(0,0,128,128,7)
 --ground
 rectfill(0, ground_y, 128, ground_y, 0)
 --scaffolding
 rectfill(0, scaffolding_y, 128, scaffolding_y+1, 0)
end

__gfx__
00000000777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700777077077777777777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000777000077777777777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000707000077770007777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700700000077700000777770000000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000770000077000000777770777707707770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000770777077000000777770777700770770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077770777770777070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077770777777000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077770777777777070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077770077777777070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077770077777777070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077700000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077707777777777070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077700000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
