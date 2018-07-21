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
 palt(0, false)
 palt(11, true)
 bg_draw()
 bulding_draw(building)
 cat_draw(cat)
 demolisher_draw(demolisher)
 bucket_draw(bucket)
 foreach(paintbullets_arr, paintbullet_draw)
 foreach(rocks_arr, rock_draw)
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
  push_type = 0
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
   c.freeze = cat_hpush_freeze

   local push_dir = 1
   if (c.spr_flip) push_dir = -1

   rock = rocks_getclosest(c.x, cat_push_range)
   if rock != nil then
    rock_push(rock, push_dir)
   elseif is_cat_near_bucket() then
    bucket_push(bucket, push_dir)
   end
  end

  -- vpush
  if btnp(4) then
   cat_setanim(c, "push")
   c.push_type = 2
   c.freeze = cat_vpush_freeze

   rock = rocks_getclosest(c.x, cat_push_range)
   if rock != nil then
    rock_fall(rock)
   elseif is_cat_near_bucket() then
    bucket_shake(bucket)
   end
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

 if(b.x > 124) b.x = 124
 if(b.x < 4) b.x = 4
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
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
