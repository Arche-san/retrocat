pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--main
ground_y = 108
scaffolding_y = 30

rock_push_force = 0.5
rock_push_time = 15
rock_damage = 10

cat_push_range = 10
cat_hpush_freeze = 32
cat_vpush_freeze = 32

bucket_push_force = 1.5
bucket_push_time = 15
bucket_shake_time = 15
bucket_paint_capacity_max = 10
bucket_refill_position = 115

demolisher_xmin = -20
demolisher_xmax = 20

building_life_max = 100

paint_surface_bonus = 0.02

particles = {}

function _init()
 --rock_create(20,scaffolding_y)
 building = building_init()
 cat = cat_init()
 demolisher = demolisher_init()
 bucket = bucket_init()
 painttap = painttap_init();
end

local key = false
function _update60()
 building_update(building)
 cat_update(cat)
 demolisher_update(demolisher)
 bucket_update(bucket)
 painttap_update(painttap)
 foreach(paintbullets_arr, paintbullet_update)
 foreach(rocks_arr, rock_update)
end

function _draw()
 palt(0, false)
 palt(11, true)
 bg_draw()
 building_draw(building)
 cat_draw(cat)
 demolisher_draw(demolisher)
 painttap_draw(painttap)
 bucket_draw(bucket)
 foreach(paintbullets_arr, paintbullet_draw)
 foreach(rocks_arr, rock_draw)
 foreach(particles, draw_particle)
 print("cpu=".. stat(1), 0, 112)
 --print("mem=".. stat(0), 0, 120)
 print("nb part="..#particles, 0, 120)
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
  x = 70,
  spr_x = 0,
  spr_y = 32,
  spr_w = 57,
  spr_h = 52,
  spr_scale = 2,
  paint_surface = 0,
  life = 100,
 }
end

function building_update(b)
end

function building_draw(b)
 -- building (with paint completion)
 local ystart = b.spr_y
 local yend = ystart + b.spr_h
 local height = yend - ystart
 local completed_ystart = yend - (height) * b.paint_surface
 local completed_height = yend - completed_ystart
 building_draw_part(b.spr_x, ystart, b.spr_w, height, b.x, ground_y-height, false)
 building_draw_part(b.spr_x, completed_ystart, b.spr_w, completed_height, b.x, ground_y-completed_height, true)

 -- gauge
 local gauge_min = 75
 local gauge_max = 120
 rect(gauge_min-1,36,gauge_max+1,40,0)
 if b.life > 0 then
  local gauge_ratio = 1 - b.life / building_life_max
  local gauge_val = gauge_min + flr(gauge_ratio * (gauge_max - gauge_min))
  rectfill(gauge_val,37,gauge_max,39,8)
 end
end

function building_hit(b, damage)
 b.life -= damage
end

function building_paint(b, surface)
 b.paint_surface += surface
 b.paint_surface = min(b.paint_surface, 1)
end

function collide_with_building(x,y)
 return x >= 70 and x <= 110 and y >=50 and y <= 96
end

--draw building in both states
--altered / renovated (clean)
function building_draw_part(x,y,w,h,px,py,clean)
 --init palette parity
 pal()
 local pair_broken = {
  {13,1},{10,7},{2,6},{12,1},
  {15,11},{9,11},{4,11},{14,6},
  {5,11}
 }
 local pair_clean = {
  {13,7},{10,1},{2,8},{12,8},
  {15,8},{9,1},{4,7},{14,7},
  {5,6}
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
  palt(5,true)
 end
 palt(11,true)
 sspr(x,y,w,h,px,py)
 --reset palt
 pal()
 palt()
 palt(0, false)
 palt(11, true)
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
  x = 10,
  y = ground_y,
  cx = -16,
  cy = -32,
  cw = 65,
  ch = 32,
  state = demolisher_state_idle,
  state_time = 0,
  spr_shake_time = 0,
  swing = false,
  swing_time = 0,
  swing_force = 0
 }
end

function demolisher_update(d)
 --sprite shake
 d.spr_shake_time += 1

 d.swing_time += 1
 if d.swing then
  d.swing_force += 0.05
 else
  if d.swing_force >= 0 then
   d.swing_force -= 0.1
  else
   d.swing_force = 0
  end
 end

 --state machine
 local state = d.state
 local state_time = d.state_time

 state_time += 1
 d.state_time = state_time

 if state == demolisher_state_idle then
  if(state_time >= 300) demolisher_move(d)
 
 elseif state == demolisher_state_move then
  d.x += 0.5
  if d.x >= demolisher_xmax then
   d.x = demolisher_xmax
   demolisher_loading(d)
  end
  if(state_time >= 30) demolisher_idle(d)
 
 elseif state == demolisher_state_loading then
  if(state_time >= 300) demolisher_attack(d)
 
 elseif state == demolisher_state_attack then
  if(state_time >= 60) demolisher_idle(d)

 elseif state == demolisher_state_stun then
  d.x -= 0.5
  if state_time >= 30 then
   demolisher_idle(d)
  end
 end

 if d.x < demolisher_xmin then
  d.x = demolisher_xmin
 end
end

function demolisher_draw(d)
 local shake_offset = cos(flr(d.spr_shake_time / 8) / 2) / 2
 -- base
 local spr_y = d.y -32 + shake_offset
 sspr(0, 96, 48, 21, d.x-16, spr_y)
 sspr(0, 117, 48, 1, d.x-16, d.y-12)
 sspr(0, 117, 48, 11, d.x-16, d.y-11)

 -- cannon ball
 local ball_x = d.x + 43
 local ball_y = d.y - 28 + shake_offset
 if d.swing_force > 0 then
  ball_x += cos(d.swing_time / 60) * d.swing_force
  ball_y += sin(d.swing_time / 60) /3 * d.swing_force
 end
 sspr(18, 0, 16, 16, ball_x-7, ball_y)

 -- cannon line
 local ball_line_x = d.x + 43
 local ball_line_y = d.y - 50 + shake_offset
 line(ball_line_x, ball_line_y, ball_x, ball_y, 0)

 -- local cx_start = d.x + d.cx
 -- local cx_end = cx_start + d.cw
 -- local cy_start = d.y + d.cy
 -- local cy_end = cy_start + d.ch
 -- rect(cx_start, cy_start, cx_end, cy_end, 11)

 --print(d.state, 0, 0)
end

function demolisher_idle(d)
 d.swing = false
 demolisher_setstate(d, demolisher_state_idle)
end

function demolisher_move(d)
 d.swing = false
 demolisher_setstate(d, demolisher_state_move)
end

function demolisher_loading(d)
 d.swing = true
 demolisher_setstate(d, demolisher_state_loading)
end

function demolisher_attack(d)
 d.swing = true
 building_hit(building, 10)
 demolisher_setstate(d, demolisher_state_attack)
end

function demolisher_stun(d)
 d.swing = false
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
 spr(4, r.x-4, r.y-4, 1, 1)
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
-- paint elements
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

 if(b.x > bucket_refill_position) b.x = bucket_refill_position
 if(b.x < 20) b.x = 20
end

function bucket_draw(b)
 if b.paint_capacity > 0 then
  local ymin = scaffolding_y - 5
  local ymax = scaffolding_y - 2
  local ratio = 1 - b.paint_capacity / bucket_paint_capacity_max
  local y = ymin + flr((ymax - ymin) * ratio)
  rectfill(b.x-3, y, b.x+1, ymax, 8)
 end

 spr(42, b.x-4, scaffolding_y-16, 1, 2)
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

function bucket_refill(b, value)
 b.paint_capacity += value
 b.paint_capacity = min(b.paint_capacity, bucket_paint_capacity_max)
end

function is_bucket_in_refill_position()
 return bucket.x >= bucket_refill_position
end

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
 p.y += 1.5
 if collide_with_building(p.x, p.y) then
  add_splash(p.x,p.y)
  building_paint(building, paint_surface_bonus)
  paintbullet_destroy(p)
 elseif collide_with_demolisher(demolisher, p.x, p.y) then
  demolisher_stun(demolisher)
  paintbullet_destroy(p)
 elseif p.y >= ground_y then
  paintbullet_destroy(p)
 end
end

function paintbullet_draw(p)
 circfill(p.x,p.y,2,8)
end

function paintbullet_destroy(p)
 del(paintbullets_arr, p)
end

-- paint tap
function painttap_init()
 return {
  x = 128,
  y = -3,
  opened = false,
  refill_timer = 0
 }
end

function painttap_update(p)
 if is_bucket_in_refill_position() then
  painttap_open(p)
 else
  painttap_close(p)
 end

 if p.opened then
  p.refill_timer -= 1
  if p.refill_timer <= 0 then
   if is_bucket_in_refill_position() then
    bucket_refill(bucket, 1)
   end
   p.refill_timer = 60
  end
 end

end

function painttap_draw(p)
 if p.opened then
  rectfill(p.x-15, p.y+15, p.x-13, p.y+23, 8)
 end

 spr(46, p.x-16, p.y, 2, 2)
end

function painttap_open(p)
 if(p.opened) return;
 p.opened = true
 p.refill_timer = 60
end

function painttap_close(p)
 if(not p.opened) return;
 p.opened = false
end

function add_particle(x,y,vx,vy,r,c,g,gr,f)
 local part = {}
 part.x = x
 part.y = y
 part.vx = vx
 part.vy = vy
 part.col = c
 part.radius = r
 part.gravity = g
 part.ground = gr
 part.frame = f
 if(f == nil) part.frame = 60
 add(particles, part)
end

function add_splash(x,y)
 local nb = rnd(3)+5
 for i=1,nb do
  add_particle(x,y,
   rnd(1)-0.5,
   rnd(1)-3,
   rnd(1)+3,8,0.2,
   108,50)
 end
end

function draw_particle(p)
 circfill(p.x,p.y,p.radius,p.col)
 p.x += p.vx
 p.y += p.vy
 if(p.ground != nil and
    p.y+p.radius > p.ground) then
  p.y = p.ground - p.radius
 end
 if(p.gravity != nil and
    p.vy < 2) then
  p.vy += p.gravity
 end
 p.radius = p.radius / 1.025
 p.frame -= 1
 if(p.frame <= 0) del(particles,p)
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
bbbbb1b111bbbbbbbbbbbbb11111bbbbbbb1111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb1716771bbbbbbbbbb111177711bbbb116161bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb17766771bbbbbbbb11111111771bbb111661bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb1167166771bbbbbb1111111111171bbb1111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb176666666661bbbbb1711111111171bbbbbbbbbbbbbbbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b16111661116111bbb171711111111171bbbbbbbbbbbbbbb11b11bbbbbbbbbbbbb1b1bbbbbbbbbbbb11b11bbbbbbbbbbbb1b1bbbbbbbbbbbbb1b1bbbbbbbbbbb
b117716177766711bb117111111111171bbbbbbbbbbbbbbb11b11bbbbbbbbbbbb11b11bbbbbbbbbb111111bbbbbbbbbbb11b11bbbbbbbbbbb11b11bbbbbbbbbb
17167616611667771b171711111111171bbbbbbbbbbbbbb1111111bbbbbbbbbb111111bbbbbbbbbb117171bbbbbbbbbb111111bbbbbbbbbb111111bbbbbbbbbb
11616666177166771b117111111111171bbbbbbbbbbbbbb1171711bbbbbbbbbb117171bbbbbbbbbb117171bbbbbbbbbb117171bbbbbbbbbb117171bbbbbbbbbb
1666166666771611bb171711111111111bbbbbbbbbbbbbb1171711bbbbbbbbbb117171bbbbbbbbbbb1111bbbbbbbb1bb117171bbbbbbbbbb117171bbbbbbbbbb
b1177161116661771bb1711111111111bbbbbbbbbbbb1bbb11111bbbbbbb1bbbb1111bbbbbb11bbbb111bbbbbbbbb1bbb1111bbbbbbb1bbbb1111bbbbbbbbbbb
b17167616666166171b1171111111111bbbbbbbbbbbb1bbbb111bbbbbbbb1bbbb111bbbbbbbbb1b11111bbbbbbbbb1b11111bbbbbbbbb1bbb111bbbbbbbbbbbb
161166111611716111bb11711111111bbbbbbbbbbbbbb1b11111bbbbbbbbb1b11111bbbbbbbbbb11111111bbbbbbbb111111bbbbbbbbb1b11111bbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbb117111111bbbbbbbbbbbbbbbb111111bbbbbbbbbb111111bbbbbbbbb11111111bbbbbbbb1111111bbbbbbbbbb111111bbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbb11111bbbbbbbbbbbbbbbbbb111111bbbbbbbbbb1111111bbbbbbbb11bbbbbbbbbbbbbbbbbb111bbbbbbbbbb111111bbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1b11b1bbbbbbbbbb11bb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbb11bbbbbbbbbbb11b1bbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb11b11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb117171bbbbbbbbbbbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb117171bbbbbbbbbbbb11b116bbbbbbbbbbbbbbb6bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11b11b11bbb
bbb1111bbbbbbbbbbbb111111b6bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11111111bbb
bbb1111111bbbbbbbbb117171b6bbbbbbbbbbbb1b166bbbbbbbbbbb1b1bbbbbbbbbbbbb1b1bbbbbb1bbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11bbbbbb
bbb111111bbbbbbbbbb117171b66bbbbbbbbbb11b116bbbbbbbbbb11b11bbbbbbbbbbb11b11bbbbb1bbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1771bbbbb
bbb1111bbbbbbbbbbbbb1111bb66bbbb1bbbb11111166bbb1bbbb1111116bbbb1bbbb111111bbbbb1111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111111bbbb
bbb1111bbbbbbbbbbbbb1111116bbbbbb1bbb117171b66bbb1bbb117171bbbbbb1bbb117171bbbbb1111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1111bbb11
bbb1111bbbbbbbbbbbb1111116bbbbbbb1bbb117171b666bb1bbb117171b6bbbb1bbb117171bbbbb1bb11b1bbbbbbbbbbbbbbbbbbbbbbbbbbb11111171717111
b11111bbbbbbbbbb1111111bbbbbbbbbb1111b1111bbb66bb1111b1111bb66bbb1111b1111bbbbbb1bb1bb1bbbbbbbbbbbbbbbbbbbbbbbbbb177111117171711
1bb111bbbbbbbbbbbbb111bbbbbbbbbbb11111111bbbb66bb11111111bbbb6bbb11111111bbbbbbb1bbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbb171111111111111
bbb111bbbbbbbbbbbbb111bbbbbbbbbbbb111111111166bbbb111111111166bbbb1111111111bbbb1bbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbb111bbb1111bbb11
bbb11bbbbbbbbbbbbbb11bbbbbbbbbbbbbb11bbb11166bbbbbb11bbb11166bbbbbb11bbb111bbbbbb11111bbbbbbbbbbbbbbbbbbbbbbbbbbb111bbbb11bbbbbb
bbbbb77777777777777777777777777717777777777777777777777777777777777711111111111111111111111111177777777bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77777777777777777777777777117777777777777777777777777777777777155555555555555555555555555117777777bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77777777777777777777777777117117777777777777777777777777777771551111111111199111111111551f17777777bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb777777777777777777777777711111117777777777777777777777777777155111fff1fff1f991fff1ff1551fff1777777bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77777777777777777777777771444411777777777777777777777777777155111f2f11111fff91111ff1551ff1f1777777bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7777777777777777777777777144441177777777777777777777777777155111fff1fff1fff1fff1f21551ff11ff177777bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb777777777777777777777777714eee117777777777777777777777777a551111111ff21111122f1221551ff161ff177777bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77777777777777777777777771444411777777777777777777777777155111fff1ff21fff1fff1ff1551ff16711ff17777bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7777777771111111199991111144441111111177777777777777777155111fff1fff9fff1fff1ff1551ff111111ff17777bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb777777771fffffffccccccfff1ee4411ffff111777777777777777155111fff19999fff11111ff1551ff16176161ff1777bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77777771ffffffffffcfcffff144411ffff1111177777777777771551111111f2f99991fff1ff1551ff167167171ff1777bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7777771fff2222fffffffffff11111ffff111111177777777777155111fff1f2f9fff1fff1111551ff11111111111ff177bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb777771ccfffffffffff222fffffffffff1111111117777777777a1111fff1fff9f221fff1fff111ffffffffffffffff177bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77771fffccffffffffffffff2ff222ff11161116111777777777aaaaa111fff9fff111111ff11111111111111111111117bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7771ffffffff2f222ffffffffffffff111671117711177777777777a111111111111111111111111111111111111111117bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb771ffffffffffffffffffffcffffff11167711177711177777777771116611166111666611111111111111111111111777bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb71fffffcfffffff222ffffff22fff1111111111111111177777777711166666666666666666661111ff9ff9ff2ff9ff177bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb1ffffccffffffffffffcfccfffff111111111111111111177777777111446664466644446666611161ff2ff9ff9ff9ff17bbbbbbbbbbbbbbbbbbbbbbbbb
bbbb9fcffccfff2f22fffffffffcffff11166666666666666611177777771114444444d4444444ddd4111461ff9ff9ff9ff2ff1bbbbbbbbbbbbbbbbbbbbbbbbb
bbb9ffcfcffffffffffffff222fffff11144444444444d4444111177777711144ddd4444444d44444d111446111111111111111bbbbbbbbbbbbbbbbbbbbbbbbb
bb9ffcffffffffffffffffffffffff11114444444444dd44441111177777a114d4444444444411114411144416666666661177abbbbbbbbbbbbbbbbbbbbbbbbb
bb9999111111111111111111111111111144441114441a14441111177777aa1444d44111444117171411144414444444441177abbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7771666666666666666666666441141111714441711111177777777aa14d44411221441111114111d4414491111941177abbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7771444444444444444444444441141111714441711111177777777a114d4411211214117a7141114d414417771141177abbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb7771444444444444444444444441144441714441714441177777777a11444411211214411aad41114d41d411111141177abbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77714444444444444444444d44411444411144411144411777777771114d4411222214d44dd4411144414417771141177abbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77714411111441111144111114411444d444444444444117777777711144d411222214d4444441114d41441aa11141177abbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77714411771441177144117714411444444111111eee41177777777111444411121214dd4444411144d94444444441177abbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb77714411111441111144111114411444eee122211444411777777771119999112212111111111111199991111111111771bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb777144117714411771441177144114444441222114444117777777111119911111221111a1a11111119911111111a11771bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb777144111a1441111144111a144114444441122114eee1177777771111111911222211a111111111119111111aaa111771bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb777144444d4444dd4444444d4441144e4ee122211444411777777711111111111111111a11111111111111111111111771bbbbbbbbbbbbbbbbbbbbbbbbb
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
bbbbbbbbbbbbbbbbbbbbbb1111111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbb177777777771777777771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbb177777111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbb1777771617661776717671bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbb1777771616671767716771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbb1777716617771677717771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbb1777716617771777717771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb11111111111111111777111111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb1bbb1bbb1bbb1bbb1777177777771777777771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb1bbb1bbb1bbb1bbb1777177777771777777771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b11111111111111111111777177777771711111171bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
177777777777777777777777111777771717771171bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
177777777777777777777777177777771711111171bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
177111111111111777777777177777771717771171bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
177117171717171777777777177777771711111171bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
177171717171711777777777111111111717771171bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
177711111111111777777777777777771711111171bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
177777777777777777777777111111111777777771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b11777777777777777777777171717171777777771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb11111111111111111111111111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbb1111111111111111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb1111111111111111111111111111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b171111777777777777777777777111171111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
17177771771111111111111117717777171111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
11771177177111111111111177177117711111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
11716617177711111111111777171661711111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
11716617177711111111111777171661711111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
11771177177111111111111177177117711111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
17177771771111111111111117717777171111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b171111777777777777777777777111171111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb1111111111111111111111111111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
__map__
5051525300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6061626300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7071727300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
