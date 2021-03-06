pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--main
ground_y = 96
scaffolding_y = 24

rock_push_force = 0.5
rock_push_time = 15
rock_damage = 10

cat_push_range = 10
cat_hpush_freeze = 32
cat_vpush_freeze = 32

bucket_push_force = 0.5
bucket_push_time = 15
bucket_shake_time = 15
bucket_paint_capacity_max = 3

building_life_max = 100

function _init()
 rock_create(20,24)
 building = building_init()
 cat = cat_init()
 demolisher = demolisher_init()
 bucket = bucket_init()
end

function _update60()
 building_update(building)
 cat_update(cat)
 demolisher_update(demolisher)
 bucket_update(bucket)
 foreach(paintbullets_arr, paintbullet_update)
 foreach(rocks_arr, rock_update)
end

function _draw()
 cls(7)
 palt(0, false)
 palt(11, true)
 bg_draw()
 bulding_draw(building)
 cat_draw(cat)
 demolisher_draw(demolisher)
 bucket_draw(bucket)
 foreach(paintbullets_arr, paintbullet_draw)
 foreach(rocks_arr, rock_draw)
 rectfill(50,30,107,82,7)
 draw_building(0,32,57,52,50,30)
end

-->8
-- cat
function cat_init()
 return {
  x = 64,
  y = scaffolding_y,
  spr_flip = false,
  freeze = -1,
  anims = {
   idle = {5},
   walk = {7,9,11,13},
   push = {32,34,36,38,40},
  },
  anim_name = "idle",
  anim_index = 1,
  anim_frame = 0,
  push_type = 0,
  push_countdown = 1
 }
end

function cat_update(c)
	c.freeze -= 1
 if c.freeze <= 0 then
  -- move
  if btn(1) then
   c.x += 0.5
   c.spr_flip = false
   cat_setanim(c, "walk")
  elseif btn(0) then
   c.x -= 0.5
   c.spr_flip = true
   cat_setanim(c, "walk")
  else 
   cat_setanim(c, "idle")
  end

  -- hpush
  if btnp(5) then
   cat_setanim(c, "push")
   c.push_type = 1
   c.push_countdown = 16
   c.freeze = cat_hpush_freeze
  end

  -- vpush
  if btnp(4) then
   cat_setanim(c, "push")
   c.push_type = 2
   c.push_countdown = 16
   c.freeze = cat_vpush_freeze
  end
 end

 -- push delay
 if c.push_countdown > 0 then
  c.push_countdown -= 1
  if c.push_countdown <= 0 then
   cat_applypush(c)
  end
 end

 -- bounds
 if(c.x > 124) c.x = 124
 if(c.x < 4) c.x = 4

  -- anim
 local anim = c.anims[c.anim_name]
 local anim_frame = c.anim_frame
 local anim_index = c.anim_index
 anim_frame += 1
 if anim_frame >= 8 then
  anim_frame = 0
  anim_index += 1
  if anim_index > #anim then
   anim_index = 1
  end
 end
 c.anim_index = anim_index
 c.anim_frame = anim_frame
end

function cat_applypush(c)
 if c.push_type == 1 then
  local push_dir = 1
  if (c.spr_flip) push_dir = -1
  
  local rock = rocks_getclosest(c.x, cat_push_range)
  if rock != nil then
   rock_push(rock, push_dir)
  elseif is_cat_near_bucket() then
   bucket_push(bucket, push_dir)
  end
 elseif c.push_type == 2 then
  local rock = rocks_getclosest(c.x, cat_push_range)
  if rock != nil then
   rock_fall(rock)
  elseif is_cat_near_bucket() then
   bucket_shake(bucket)
  end
 end
end

function cat_draw(c)
 if c.anim_name == "push" and c.push_type == 2 then
  pal(6,8)
 end

 local anim = c.anims[c.anim_name]
 spr(anim[c.anim_index], c.x - 8, c.y - 16, 2, 2, c.spr_flip)

 pal(6,6)
end

function cat_setanim(c, anim_name)
 if(anim_name == c.anim_name) return
 c.anim_name = anim_name
 c.anim_index = 1
end

function is_cat_near_bucket()
 return abs(bucket.x - cat.x) <= cat_push_range
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
 sspr(0,32,32,32,50,ground_y-64,64,64)
 --rect(70,50,110,96,0)

 -- gauge
 local gauge_min = 65
 local gauge_max = 105
 rect(gauge_min-1,36,gauge_max+1,40,0)
 if b.life > 0 then
  local gauge_ratio = 1 - b.life / building_life_max
  local gauge_val = gauge_min + flr(gauge_ratio * (gauge_max - gauge_min))
  rectfill(gauge_val,37,105,39,8)
 end
end

function building_hit(b, damage)
 b.life -= damage
end

function collide_with_building(x,y)
 return x >= 70 and x <= 110 and y >=50 and y <= 96
end

--draw building in both states
--altered / renovated (clean)
function draw_building(x,y,w,h,px,py,clean)
 --init palette parity
 pal()
 local pair_broken = {
  {13,1},{10,7},{2,6},{12,1},
  {15,11},{9,11},{4,11},{14,6}
 }
 local pair_clean = {
  {13,7},{10,1},{2,8},{12,8},
  {15,8},{9,1},{4,7},{14,7}
 }
 local pair = pair_broken
 if(clean) pair = pair_clean
 --applying parity
 for pa in all(pair) do
  pal(pa[1],pa[2])
 end
 --drawing sprite
 if(not clean) then
  palt(15,true)
  palt(9,true)
  palt(4,true)
 end
 palt(11,true)
 sspr(x,y,w,h,px,py)
 pal()
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
 --state machine
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
  if d.x < 10 then
   d.x = 10
   demolisher_idle(d)
  elseif state_time >= 30 then
   demolisher_idle(d)
  end
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
-- bucket
bucket_state_push = 1
bucket_state_shake = 2
function bucket_init()
 return {
  x = 85,
  state = 0,
  state_time = 0,
  paint_capacity = bucket_paint_capacity_max
 }
end

function bucket_update(b)
 -- state machine
 local state = b.state
 b.state_time += 1

 if state == bucket_state_push then
  b.x += b.push_dir * bucket_push_force
  if(b.state_time >= bucket_push_time) b.state = 0
 elseif state == bucket_state_push then
  if(b.state_time >= bucket_shake_time) b.state = 0
 end

 if(b.x > 108) b.x = 108
 if(b.x < 20) b.x = 20
end

function bucket_draw(b)
 spr(42, b.x-4, scaffolding_y-8, 1, 1)

 if b.paint_capacity > 0 then
  local ymin = scaffolding_y - 4
  local ymax = scaffolding_y - 2
  local ratio = 1 - b.paint_capacity / bucket_paint_capacity_max
  local y = ymin + flr((ymax - ymin) * ratio)
  rectfill(b.x-2, y, b.x+1, ymax, 8)
 end

end

function bucket_push(b, dir)
 b.push_dir = dir
 b.state = bucket_state_push
 b.state_time = 0
end

function bucket_shake(b)
 if b.paint_capacity > 0 then
  b.paint_capacity -= 1
  paintbullet_create(b.x)
 end

 b.state = bucket_state_shake
 b.state_time = 0
end

function bucket_refill(b)
 b.paint_capacity = bucket_paint_capacity_max
end

-->8
-- paint bullet
paintbullets_arr = {}

function paintbullet_create(x)
 p = {
  x = x,
  y = scaffolding_y
 }
 add(paintbullets_arr, p)
 return p
end

function paintbullet_update(p)
 p.y += 1
 if p.y >= ground_y then
  paintbullet_destroy(p)
 end
end

function paintbullet_draw(p)
 circfill(p.x,p.y,2,8)
end

function paintbullet_destroy(p)
 del(paintbullets_arr, p)
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
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00700700bbb0bb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00077000bbb0000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00077000b0b0000bbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00700700b000000bbb00000bbbbb00000000bbbbbbbbbbbb11b11bbbbbbbbbbbbb1b1bbbbbbbbbbbb11b11bbbbbbbbbbbb1b1bbbbbbbbbbbbb1b1bbbbbbbbbbb
00000000bb00000bb000000bbbbb077770770bbbbbbbbbbb11b11bbbbbbbbbbbb11b11bbbbbbbbbb111111bbbbbbbbbbb11b11bbbbbbbbbbb11b11bbbbbbbbbb
00000000bb0bbb0bb000000bbbbb0777700770bbbbbbbbb1111111bbbbbbbbbb111111bbbbbbbbbb117171bbbbbbbbbb111111bbbbbbbbbb111111bbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbb07777707770bbbbbbbb1171711bbbbbbbbbb117171bbbbbbbbbb117171bbbbbbbbbb117171bbbbbbbbbb117171bbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbb07777770000bbbbbbbb1171711bbbbbbbbbb117171bbbbbbbbbbb1111bbbbbbbb1bb117171bbbbbbbbbb117171bbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbb07777777770bbbbb1bbb11111bbbbbbb1bbbb1111bbbbbb11bbbb111bbbbbbbbb1bbb1111bbbbbbb1bbbb1111bbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbb00777777770bbbbb1bbbb111bbbbbbbb1bbbb111bbbbbbbbb1b11111bbbbbbbbb1b11111bbbbbbbbb1bbb111bbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbb00777777770bbbbbb1b11111bbbbbbbbb1b11111bbbbbbbbbb11111111bbbbbbbb111111bbbbbbbbb1b11111bbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000bbbbbbbb111111bbbbbbbbbb111111bbbbbbbbb11111111bbbbbbbb1111111bbbbbbbbbb111111bbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbb077777777770bbbbbbb111111bbbbbbbbbb1111111bbbbbbbb11bbbbbbbbbbbbbbbbbb111bbbbbbbbbb111111bbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000bbbbbbb1b11b1bbbbbbbbbb11bb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbb11bbbbbbbbbbb11b1bbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb11b11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb117171bbbbbbbbbbbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb117171bbbbbbbbbbbb11b116bbbbbbbbbbbbbbb6bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb1111bbbbbbbbbbbb111111b6bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb1111111bbbbbbbbb117171b6bbbbbbbbbbbb1b166bbbbbbbbbbb1b1bbbbbbbbbbbbb1b1bbbbbbbb0000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb111111bbbbbbbbbb117171b66bbbbbbbbbb11b116bbbbbbbbbb11b11bbbbbbbbbbb11b11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb1111bbbbbbbbbbbbb1111bb66bbbb1bbbb11111166bbb1bbbb1111116bbbb1bbbb111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb1111bbbbbbbbbbbbb1111116bbbbbb1bbb117171b66bbb1bbb117171bbbbbb1bbb117171bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb1111bbbbbbbbbbbb1111116bbbbbbb1bbb117171b666bb1bbb117171b6bbbb1bbb117171bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b11111bbbbbbbbbb1111111bbbbbbbbbb1111b1111bbb66bb1111b1111bb66bbb1111b1111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
1bb111bbbbbbbbbbbbb111bbbbbbbbbbb11111111bbbb66bb11111111bbbb6bbb11111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb111bbbbbbbbbbbbb111bbbbbbbbbbbb111111111166bbbb111111111166bbbb1111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb11bbbbbbbbbbbbbb11bbbbbbbbbbbbbb11bbb11166bbbbbb11bbb11166bbbbbb11bbb111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7777777777777777777777777771777777777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7777777777777777777777777711777777777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7777777777777777777777777711711777777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7777777777777777777777777111111177777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7777777777777777777777777144441177777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7777777777777777777777777144441177777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb777777777777777777777777714eee1177777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7777777777777777777777777144441177777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7777777771111111199991111144441111111177777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb777777771fffffffccccccfff1ee4411ffff1117777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77777771ffffffffffcfcffff144411ffff11111777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7777771fff2222fffffffffff11111ffff111111177777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb777771ccfffffffffff222fffffffffff1111111117777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77771fffccffffffffffffff2ff222ff11161116111777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7771ffffffff2f222ffffffffffffff111671117711177777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb771ffffffffffffffffffffcffffff1116771117771117777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb71fffffcfffffff222ffffff22fff11111111111111111777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb1ffffccffffffffffffcfccfffff111111111111111111177777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb9fcffccfff2f22fffffffffcffff1116666666666666661117777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb9ffcfcffffffffffffff222fffff11144444444444d44441111777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb9ffcffffffffffffffffffffffff11114444444444dd44441111177bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb9999111111111111111111111111111144441114441a14441111177bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7771666666666666666666666441141111714441711111177777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7771444444444444444444444441141111714441711111177777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7771444444444444444444444441144441714441714441177777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77714444444444444444444d4441144441114441114441177777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77714411111441111144111114411444d4444444444441177777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77714411771441177144117714411444444111111eee41177777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77714411111441111144111114411444eee12221144441177777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7771441177144117714411771441144444412221144441177777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb777144111a1441111144111a144114444441122114eee1177777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb777144444d4444dd4444444d4441144e4ee12221144441177777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7771444444444d44444444d444411444444122211ee441177777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
999991111111111111111111111111111111111111111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
999999111111111111111111111111111111111111111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b99991111111111111111111111111111111111111111111111111117bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb99b7716661166666661166666661166666661111111111111117777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb997716666116666666116666666196666661111111111111117777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb9171444441144444441944444449944444111111111111aa17777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb111dd4444114444d449944444449944441111111111111117777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb71144444441144dd4449944dd44499444111111a1a1111117777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb771ddd44444144d444449444d444494441111111111111117777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77144444444444444444444d4444444441111111111111117777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb771441111144444444444444441111144111111a1a1111117777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77144111114444111111114444111114411111111a1111117777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77144444d4444411212121444444444d411111111aaa11117777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77144444444444112121214444444444411111111a1111117777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7714444444dddd11212121444ddd4444411111111a1111117777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77144d444444441121212144444d444441111111111111117777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb771dddd44444dd112121214444dddd444111aaa1111111117777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb771444444444441121212144444d4444411111a1111111117777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7711111111111111111111111111111111111111111111117777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
