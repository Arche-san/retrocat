pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--main
ground_y = 108
scaffolding_y = 30

rock_push_force = 0.5
rock_push_time = 15
rock_damage = 10

cat_charge_full_duration = 30
cat_push_range = 10
cat_hpush_freeze = 24
cat_vpush_freeze = 24

bucket_push_force_min = 1
bucket_push_force_max = 2
bucket_push_time = 15
bucket_shake_time = 15
bucket_shake_nbbullets_min = 1
bucket_shake_nbbullets_max = 3
bucket_paint_capacity_max = 10
bucket_refill_position = 115

demolisher_xmin = -50
demolisher_xmax = 25
demolisher_ball_damage = 40

building_life_max = 100
building_complete_duration = 180
paint_surface_bonus = 0.2

particles = {}

score_bonus_building_paint = 20
score_bonus_demolisher_hit = 5
score_bonus_building_completed = 100

debug_collisions = false

tuto_active = true

score = 0

function _init()
 building = building_init(1)
 cat = cat_init()
 demolisher = demolisher_init()
 bucket = bucket_init()
 painttap = painttap_init();
end

local key = false
function _update60()
 if not tuto_active then
  building_update(building)
  cat_update(cat)
  demolisher_update(demolisher)
  bucket_update(bucket)
  painttap_update(painttap)
  foreach(paintbullets_arr, paintbullet_update)
  foreach(rocks_arr, rock_update)
 end
end

function _draw()
 palt(0, false)
 palt(11, true)
 bg_draw()
 building_draw(building)
 demolisher_draw(demolisher)
 painttap_draw(painttap)
 cat_draw(cat)
 bucket_draw(bucket)
 foreach(paintbullets_arr, paintbullet_draw)
 foreach(rocks_arr, rock_draw)
 foreach(particles, draw_particle)
 print_outline("\x92 "..num_format(score, 4), 100, 122, 7, 1)
 --print("cpu=".. stat(1), 0, 112)
 --print("mem=".. stat(0), 0, 120)
 --print("nb part="..#particles, 0, 120)
 if(tuto_active) scene_tuto(1)
end

-- print outline
function print_outline(s, x, y, c1, c2)
 print(s, x-1, y, c2)
 print(s, x, y-1, c2)
 print(s, x+1, y, c2)
 print(s, x, y+1, c2) 
 print(s, x, y, c1)
end

function num_format(n, d)
 local s = n
 local ten_power = 10
 for i=1,d-1 do
  if(n < ten_power) s = "0"..s
  ten_power *= 10
 end

 return s
end

function rnd_range(min, max)
 return min + rnd(max-min)
end

function rnd_range_i(min, max)
 return min + flr(rnd((max+1)-min))
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
   push_charge = {32},
   push_release = {34,36,38,40},
  },
  anim_name = "idle",
  anim_index = 1,
  anim_frame = 0,
  push_type = 0,
  push_countdown = 1,
  charging = false,
  charge_type = 0,
  charge_ratio = 0,
  charge_timer = 0,
  charge_blink = false,
  charge_blink_timer = 0,
 }
end

function cat_update(c)
	c.freeze -= 1
 if c.freeze <= 0 then
  -- move
  if not c.charging then
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
  end

  -- hpush
  if c.charging then
   if c.charge_timer < cat_charge_full_duration then
    c.charge_timer += 1
    if c.charge_timer >= cat_charge_full_duration then
     c.charge_ratio = 1
     c.charge_blink = true
     c.charge_blink_timer = 0
    end
   end

   if c.charge_type == 1 and not btn(5) then
    cat_setanim(c, "push_release")
    c.push_type = 1
    c.push_countdown = 16
    c.freeze = cat_hpush_freeze   
    c.charging = false
   end

   if c.charge_type == 2 and not btn(4) then
    cat_setanim(c, "push_release")
    c.push_type = 2
    c.push_countdown = 16
    c.freeze = cat_vpush_freeze
    c.charging = false
   end
  else
   if btn(5) then
    cat_setanim(c, "push_charge")
    c.charge_type = 1
    c.charge_ratio = 0
    c.charge_timer = 0
    c.charging = true
   end

   if btn(4) then
    cat_setanim(c, "push_charge")
    c.charge_type = 2
    c.charge_ratio = 0
    c.charge_timer = 0
    c.charging = true
   end
  end
 end

 -- charge blink
 if c.charge_blink then
  c.charge_blink_timer += 1
  if c.charge_blink_timer >= 8 then
   c.charge_blink = false
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
   bucket_push(bucket, push_dir, c.charge_ratio)
  end
 elseif c.push_type == 2 then
  local rock = rocks_getclosest(c.x, cat_push_range)
  if rock != nil then
   rock_fall(rock)
  elseif is_cat_near_bucket() then
   bucket_shake(bucket, c.charge_ratio)
  end
 end
end

function cat_draw(c)
 if c.anim_name == "push_release" and c.push_type == 2 then
  pal(6,8)
 end

 if c.charge_blink then
  pal(1,8)
 end

 local anim = c.anims[c.anim_name]
 spr(anim[c.anim_index], c.x - 8, c.y - 16, 2, 2, c.spr_flip)

 pal(1,1)
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
function building_init(type)
 b = {
  x = 70,
  paint_surface = 0,
  paint_surface_y = 0,
  life = 100,
  completed = false,
  completed_timer = 0
 }

 if type == 1 then
  b.cx = 5
  b.cw = 45
  b.ch = 40
  b.spr_x = 0
  b.spr_y = 32
  b.spr_w = 57
  b.spr_h = 52
 elseif type == 2 then
  b.cx = 0
  b.cw = 46
  b.ch = 40
  b.spr_x = 56
  b.spr_y = 32
  b.spr_w = 47
  b.spr_h = 32
 elseif type == 3 then
  b.cx = 0
  b.cw = 45
  b.ch = 59
  b.spr_x = 77
  b.spr_y = 67
  b.spr_w = 51
  b.spr_h = 59
 elseif type == 4 then
  b.cx = 2
  b.cw = 57
  b.ch = 48
  b.spr_x = 11
  b.spr_y = 84
  b.spr_w = 69
  b.spr_h = 44
 end
 b.type = type

 return b;
end

function building_update(b)
 if b.completed then
  b.completed_timer += 1
  if b.completed_timer >= building_complete_duration then
   local btype = 0
   repeat
    btype = rnd_range_i(1,4)
   until btype != b.type
   building = building_init(btype)
   return
  end
 end

 local ystart = b.spr_y
 local yend = ystart + b.spr_h
 local height = yend - ystart
 local paint_ystart = yend - (height) * b.paint_surface
 local paint_height = yend - paint_ystart
 b.paint_surface_y =  ground_y - paint_height
end

function building_draw(b)
 -- building (with paint completion)
 local ystart = b.spr_y
 local yend = ystart + b.spr_h
 local height = yend - ystart
 local completed_ystart = yend - (height) * b.paint_surface
 local completed_height = yend - completed_ystart
 if b.completed then
  building_draw_part(b.spr_x, ystart, b.spr_w, height, b.x, ground_y-height, true)
 else
  if b.paint_surface > 0 then
   rectfill(b.x, b.paint_surface_y, b.x + b.spr_w-1, ground_y-1, 8)
  end
  building_draw_part(b.spr_x, ystart, b.spr_w, height, b.x, ground_y-height, false)
 end

 -- gauge
 local gauge_min = 75
 local gauge_max = 120
 rect(gauge_min-1,36,gauge_max+1,40,0)
 if b.life > 0 then
  local gauge_ratio = 1 - b.life / building_life_max
  local gauge_val = gauge_min + flr(gauge_ratio * (gauge_max - gauge_min))
  rectfill(gauge_val,37,gauge_max,39,8)
 end

 --collisions debug
 if debug_collisions then
  local cx_start = b.x + b.cx
  local cx_end = cx_start + b.cw
  local cy_start = ground_y - b.ch
  local cy_end = ground_y
  rect(cx_start, cy_start, cx_end, cy_end, 11)
 end
end

function building_hit(b, damage)
 if(b.completed) return
 b.life -= damage
end

function building_paint(b, surface)
 b.paint_surface += surface
 b.paint_surface = min(b.paint_surface, 1)
 if b.paint_surface == 1 then
  if not b.completed then
   building_complete(b)
  end
 else
  score += score_bonus_building_paint
 end
end

function building_complete(b)
 b.completed = true
 b.completed_timer = 0
 score += score_bonus_building_completed
 demolisher_retreat(demolisher)
end

function collide_with_building(x,y)
 local b = building
 local cx_start = b.x + b.cx
 local cx_end = cx_start + b.cw
 local cy_start = ground_y - b.ch
 local cy_end = ground_y
 return x >= cx_start and x <= cx_end and y >= cy_start and y <= cy_end
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
demolisher_state_attack = 3
demolisher_state_stun = 4
demolisher_state_retreat = 5

function demolisher_init()
 return {
  x = demolisher_xmin,
  y = ground_y,
  cx = -16,
  cy = -32,
  cw = 65,
  ch = 32,
  state = demolisher_state_idle,
  state_time = 0,
  spr_shake_time = 0,
  shake_offset = 0,
  swing = false,
  swing_time = 0,
  swing_force = 0,
  ball_x = demolisher_xmin + 39,
  ball_y = ground_y - 20,
  idle_time = 300,
  move_time = 30,
  move_speed = 0.5,
  stun_time = 30,
  stun_speed = 0.5,
  retreat_speed = 0.5,
 }
end

function demolisher_update(d)
 --sprite shake
 d.spr_shake_time += 1
 d.shake_offset = cos(flr(d.spr_shake_time / 8) / 2) / 2

 --swing
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

 --ball pos
 d.ball_x = d.x + 39
 d.ball_y = d.y - 20 + d.shake_offset
 if d.swing_force > 0 then
  d.ball_x += cos(d.swing_time / 60) * d.swing_force
  d.ball_y += sin(d.swing_time / 60) /3 * d.swing_force
 end

 --state machine
 local state = d.state
 local state_time = d.state_time

 state_time += 1
 d.state_time = state_time

 if state == demolisher_state_idle then
  if(state_time >= d.idle_time) demolisher_move(d)
 
 elseif state == demolisher_state_move then
  d.x += d.move_speed
  if d.x >= demolisher_xmax then
   d.x = demolisher_xmax
   demolisher_attack(d)
  end
  if(state_time >= d.move_time) demolisher_idle(d)
 
 elseif state == demolisher_state_attack then
  if(collide_with_building(d.ball_x, d.ball_y)) then
   building_hit(building, demolisher_ball_damage)
   demolisher_idle(d)
  end

 elseif state == demolisher_state_stun then
  d.x -= d.stun_speed
  if state_time >= d.stun_time then
   demolisher_idle(d)
  end

 elseif state == demolisher_state_retreat then
  d.x -= d.retreat_speed
  if (d.x <= demolisher_xmin) and (not building.completed) then
   demolisher_idle(d)
  end
 end

 if d.x < demolisher_xmin then
  d.x = demolisher_xmin
 end
end

function demolisher_draw(d)
 -- base
 local spr_y = d.y -32 + d.shake_offset
 -- base part1
 sspr(0, 96, 11, 21, d.x-16, spr_y)
 sspr(0, 117, 11, 1, d.x-16, d.y-12)
 sspr(0, 117, 11, 11, d.x-16, d.y-11)
 -- base part2
 sspr(103, 32, 25, 21, d.x-16+11, spr_y+3)
 sspr(103, 53, 25, 1, d.x-16+11, d.y-12+3)
 sspr(103, 53, 25, 11, d.x-16+11, d.y-11+3)
 --sspr(0, 117, 48, 1, d.x-16, d.y-12)
 --sspr(0, 117, 48, 11, d.x-16, d.y-11)

 -- arm
 local arm_x = d.x + 11
 local arm_y = d.y - 31 + d.shake_offset
 demolisher_draw_arm(arm_x, arm_y)

 -- cannon line
 local ball_line_x = d.x + 39
 local ball_line_y = d.y - 51 + d.shake_offset
 line(ball_line_x, ball_line_y, d.ball_x, d.ball_y, 0)

  -- cannon ball
 sspr(18, 0, 16, 16, d.ball_x-7, d.ball_y-8)

 if debug_collisions then
  circ(d.ball_x, d.ball_y, 1, 11)
  local cx_start = d.x + d.cx
  local cx_end = cx_start + d.cw
  local cy_start = d.y + d.cy
  local cy_end = cy_start + d.ch
  rect(cx_start, cy_start, cx_end, cy_end, 11)
 end

 --print(d.state, 0, 0)
end

function demolisher_draw_arm(x,y)
 for i=0,11 do
  sspr(88,30,9,2,x+i*2,y-i*2)
 end
 sspr(88,25,10,5,x+21,y-26)
end

function demolisher_idle(d)
 d.swing = false
 demolisher_setstate(d, demolisher_state_idle)
end

function demolisher_retreat(d)
 d.swing = false
 demolisher_setstate(d, demolisher_state_retreat)
end

function demolisher_move(d)
 d.swing = false
 demolisher_setstate(d, demolisher_state_move)
end

function demolisher_attack(d)
 d.swing = true
 demolisher_setstate(d, demolisher_state_attack)
end

function demolisher_stun(d)
 d.swing = false
 demolisher_setstate(d, demolisher_state_stun)
 score += score_bonus_demolisher_hit
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
  paint_capacity = bucket_paint_capacity_max,
  push_force,
  refilling = false,
  refill_timer = 0
 }
end

function bucket_update(b)
 if is_bucket_in_refill_position() then
  bucket_refill_start(b)
 else
  bucket_refill_stop(b)
 end

 if b.refilling then
  b.refill_timer -= 1
  if b.refill_timer <= 0 then
   bucket_addpaint(bucket, 1)
   b.refill_timer = 60
  end
 end

 -- state machine
 local state = b.state
 b.state_time += 1

 if state == bucket_state_push then
  b.x += b.push_dir * b.push_force
  if(b.state_time >= bucket_push_time) b.state = 0
 elseif state == bucket_state_push then
  if(b.state_time >= bucket_shake_time) b.state = 0
 end

 if(b.x > bucket_refill_position) b.x = bucket_refill_position
 if(b.x < 4) b.x = 4
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

function bucket_push(b, dir, force_ratio)
 b.push_dir = dir
 b.push_force = bucket_push_force_min + (bucket_push_force_max - bucket_push_force_min) * force_ratio
 b.state = bucket_state_push
 b.state_time = 0
end

function bucket_shake(b, force)
 if(b.refilling) return

 local nbbullets = bucket_shake_nbbullets_min + flr((bucket_shake_nbbullets_max - bucket_shake_nbbullets_min) * force)
 
 local i=0
 while i<nbbullets and b.paint_capacity > 0 do
  b.paint_capacity -= 1
  local x = b.x
  if (i > 0) x += (i*2 -1) * (2 + rnd()*3)
  paintbullet_create(x)
  i += 1
 end

 b.state = bucket_state_shake
 b.state_time = 0
end

function bucket_refill_start(b)
 if(b.refilling) return
 b.refilling = true
 b.refill_timer = 60
end

function bucket_refill_stop(b)
 if(not b.refilling) return
 b.refilling = false
end

function bucket_addpaint(b, value)
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
  if p.y >= building.paint_surface_y then
   add_splash(p.x,p.y)
   building_paint(building, paint_surface_bonus)
   paintbullet_destroy(p)
  end
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
 }
end

function painttap_update(p)
 if is_bucket_in_refill_position() then
  painttap_open(p)
 else
  painttap_close(p)
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
 bg_road(ground_y)
 --scaffolding
 bg_scaffolding(scaffolding_y)
end

function bg_scaffolding(y)
 for i=0,16 do
  sspr(88,16,8,5,i*8,y)
 end
end

function bg_road(y)
 --top road
 local sp = 12
 for i=0,16 do
  sspr(0,sp,8,1,i*8,y)
  sp += 1
  if(sp > 15) sp = 12
 end
 --lines
 for i=0,16 do
  if(i%2 == 0) line(i*8,y+8,i*8+8,y+8,1)
 end
 --street lights
 local x1 = 13
 local x2 = 60
 line(x1,y,x1,y-20,1)
 spr(0,x1-7,y-24)
 spr(0,x1,y-24,1,1,true)
 sspr(0,8,5,3,x1-2,y-14)
 line(x2,y,x2,y-20,1)
 spr(0,x2-7,y-24)
 spr(0,x2,y-24,1,1,true)
 sspr(0,8,5,3,x2-2,y-14)
end

-->8
--scenes
txts = {
 {"* how to play *","* comment jouer *"},
 {"press ⬅️➡️ to move",
  "utiliser ⬅️➡️ pour se deplacer"},
 {"presss ❎ to push bucket",
  "utiliser ❎ pour pousser le pot"},
 {"(hold to charge)",
  "(appuie long pour charger)"},
 {"press z to drop paint",
  "c pour faire tomber la peinture"},
 {"painting keeps demolisher away",
  "la peinture ecarte le bulldozer"},
 {"drop paint to repair building",
  "la peinture repare le batiment"},
 {"use tap to fill bucket",
  "le robinet remplit le pot"},
 {" ❎ next >>","❎ suite >>"},
 {"repair","repare"} 
}

--center text
function ctxt(txt,x,y,c)
 print(txt,x-#txt/2*4,y,c)
end

--show tuto
local tuto_page = 0
local next_x = 0
local key_n = false
local tra = 0
function scene_tuto(lang)
 --globals
 if(tra > 0) tra -= 2
 if tuto_page <= 2 then
 cls(1)
 ctxt(txts[1][lang],64,2,8)
 rect(14,21,113,60,7)
 rectfill(16,23,111,58,7)
 rect(14,77,113,116,7)
 rectfill(16,79,111,114,7)
 print(txts[9][lang],80+next_x/12,121)
 next_x += 1
 if(next_x > 36) next_x = 0
 end

 --page 1
 if(tuto_page == 0) then
  ctxt(txts[2][lang],60,15,7)
  ctxt(txts[3][lang],62,65,7)
  ctxt(txts[4][lang],64,71,7)
  for x=0,11 do for y=0,1 do
   spr(43,16+x*8,49+y*56)
  end end
  spr(9,48,33,4,2)
  spr(9,48,33,4,2)
  spr(36,51,89,2,2)
  rectfill(67,100,72,103,8)
  spr(42,66,89,1,2)
  print("->",74,98,1)
 --page 2
 elseif(tuto_page == 1) then
  ctxt(txts[5][lang],64,9,7)
  ctxt(txts[4][lang],64,15,7)
  ctxt(txts[6][lang],64,71,7)
  for x=0,11 do spr(43,16+x*8,49) end
  pal(6,8)
  spr(36,51,33,2,2)
  pal() palt(11,true)
  rectfill(67,46,72,47,8)
  spr(42,66,33,1,2)
  circfill(69,54,3,8)
  for i=0,9 do sspr(88,30,9,2,38+i*2,97-i*2) end
  sspr(104,32,24,17,28,98)
  sspr(18,0,16,16,64,100)
  sspr(0,106,11,10,17,105)
  line(68,79,71,100,1)
  circfill(30,90,3,8)
  print("<<",90,95,1)
 --page 3
 elseif(tuto_page == 2) then
  ctxt(txts[8][lang],64,15,7)
  ctxt(txts[7][lang],64,71,7)
  for x=0,11 do spr(43,16+x*8,49) end
  spr(46,96,19,2,2)  
  spr(42,94,33,1,2,2)
  rectfill(97,34,99,41,8)
  building_draw_part(0,32,54,25,50,90)
  circfill(72,90,3,8)
  print(txts[10][lang],39,88,8)
 end
 --next page press
 if(btn(5) and not key_n and
    tra == 0) then
  key_n = true
  tra = 64
 end
 if(not btn(5)) key_n = false
 if(tra == 32) tuto_page += 1
 if(tra == 0 and tuto_page > 2) tuto_active = false
 if(tra != 0) scene_transition()
end

function scene_transition()
 for x=0,15 do for y=0,15 do
  if(tra > 32) then
	  circfill(x*8+4,y*8+4,8-((tra-32)/4),8)
	 else
	  circfill(x*8+4,y*8+4,tra/4,8)
	 end
 end end
end
__gfx__
bb1bbbbbbbbbbbbbbbbbbbb11111bbbbbbb1111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb11bbbbbbbbbbbbbbbb111177711bbbb116161bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb1bb1bbbbbbbbbbbbbb11111111771bbb111661bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b1bbbb1bbbbbbbbbbbb1111111111171bbb1111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b1bbbbbbbbbbbbbbbbb1711111111171bbbbbbbbbbbbbbbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
111bbbbbbbbbbbbbbb171711111111171bbbbbbbbbbbbbbb11b11bbbbbbbbbbbbb1b1bbbbbbbbbbbb11b11bbbbbbbbbbbb1b1bbbbbbbbbbbbb1b1bbbbbbbbbbb
111bbbbbbbbbbbbbbb117111111111171bbbbbbbbbbbbbbb11b11bbbbbbbbbbbb11b11bbbbbbbbbb111111bbbbbbbbbbb11b11bbbbbbbbbbb11b11bbbbbbbbbb
b1bbbbbbbbbbbbbbbb171711111111171bbbbbbbbbbbbbb1111111bbbbbbbbbb111111bbbbbbbbbb117171bbbbbbbbbb111111bbbbbbbbbb111111bbbbbbbbbb
1bbb1bbbbbbbbbbbbb117111111111171bbbbbbbbbbbbbb1171711bbbbbbbbbb117171bbbbbbbbbb117171bbbbbbbbbb117171bbbbbbbbbb117171bbbbbbbbbb
b111bbbbbbbbbbbbbb171711111111111bbbbbbbbbbbbbb1171711bbbbbbbbbb117171bbbbbbbbbbb1111bbbbbbbb1bb117171bbbbbbbbbb117171bbbbbbbbbb
1bbb1bbbbbbbbbbbbbb1711111111111bbbbbbbbbbbb1bbb11111bbbbbbb1bbbb1111bbbbbb11bbbb111bbbbbbbbb1bbb1111bbbbbbb1bbbb1111bbbbbbbbbbb
bbbbbbbbbbbbbbbbbbb1171111111111bbbbbbbbbbbb1bbbb111bbbbbbbb1bbbb111bbbbbbbbb1b11111bbbbbbbbb1b11111bbbbbbbbb1bbb111bbbbbbbbbbbb
111bb1b1bbbbbbbbbbbb11711111111bbbbbbbbbbbbbb1b11111bbbbbbbbb1b11111bbbbbbbbbb11111111bbbbbbbb111111bbbbbbbbb1b11111bbbbbbbbbbbb
11bb111bbbbbbbbbbbbbb117111111bbbbbbbbbbbbbbbb111111bbbbbbbbbb111111bbbbbbbbb11111111bbbbbbbb1111111bbbbbbbbbb111111bbbbbbbbbbbb
bbbbbbb1bbbbbbbbbbbbbbb11111bbbbbbbbbbbbbbbbbb111111bbbbbbbbbb1111111bbbbbbbb11bbbbbbbbbbbbbbbbbb111bbbbbbbbbb111111bbbbbbbbbbbb
11bb1b11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1b11b1bbbbbbbbbb11bb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbb11bbbbbbbbbbb11b1bbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17777771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb11b11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb71177117bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb77711777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb117171bbbbbbbbbbbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111bbb11111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb117171bbbbbbbbbbbb11b116bbbbbbbbbbbbbbb6bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11b11b11bbb
bbb1111bbbbbbbbbbbb111111b6bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11111111bbb
bbb1111111bbbbbbbbb117171b6bbbbbbbbbbbb1b166bbbbbbbbbbb1b1bbbbbbbbbbbbb1b1bbbbbb1bbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11bbbbbb
bbb111111bbbbbbbbbb117171b66bbbbbbbbbb11b116bbbbbbbbbb11b11bbbbbbbbbbb11b11bbbbb1bbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1771bbbbb
bbb1111bbbbbbbbbbbbb1111bb66bbbb1bbbb11111166bbb1bbbb1111116bbbb1bbbb111111bbbbb1111111bbbbbbb111bbbbbbbbbbbbbbbbbbbbb111111bbbb
bbb1111bbbbbbbbbbbbb1111116bbbbbb1bbb117171b66bbb1bbb117171bbbbbb1bbb117171bbbbb1111111bbbbbb17711bbbbbbbbbbbbbbbbbbbbb1111bbb11
bbb1111bbbbbbbbbbbb1111116bbbbbbb1bbb117171b666bb1bbb117171b6bbbb1bbb117171bbbbb1bb11b1bbbbb1777111bbbbbbbbbbbbbbb11111171717111
b11111bbbbbbbbbb1111111bbbbbbbbbb1111b1111bbb66bb1111b1111bb66bbb1111b1111bbbbbb1bb1bb1bbbb17771711bbbbbbbbbbbbbb177111117171711
1bb111bbbbbbbbbbbbb111bbbbbbbbbbb11111111bbbb66bb11111111bbbb6bbb11111111bbbbbbb1bbbbb1bbb17771171bbbbbbbbbbbbbbb171111111111111
bbb111bbbbbbbbbbbbb111bbbbbbbbbbbb111111111166bbbb111111111166bbbb1111111111bbbb1bbbbb1bb17771711bbbbbbbbbbbbbbbb111bbb1111bbb11
bbb11bbbbbbbbbbbbbb11bbbbbbbbbbbbbb11bbb11166bbbbbb11bbb11166bbbbbb11bbb111bbbbbb11111bb17771111bbbbbbbbbbbbbbbbb111bbbb11bbbbbb
7777777777777777777777777777777717777777777777777777777777777777777711111111111111111111111111177777777bbbbbbb11111111111111111b
7777777777777777777777777777777117777777777777777777777777777777777155555555555555555555555555117777777bbbbbb1777777771777777771
7777777777777777777777777777777117117777777777777777777777777777771551111111111199111111111551f17777777bbbbbb1777111111111111111
77777777777777777777777777777711111117777777777777777777777777777155111fff1fff1f991fff1ff1551fff1777777bbbbb17771617661776717671
7777777777777777777777777777771444411777777777777777777777777777155111f2f11111fff91111ff1551ff1f1777777bbbbb17771616671767716771
777777777777777777777777777777144441177777777777777777777777777155111fff1fff1fff1fff1f21551ff11ff177777bbbbb17716617771677717771
77777777777777777777777777777714eee117777777777777777777777777a551111111ff21111122f1221551ff161ff177777bbbbb17716617771777717771
7777777777777777777777777777771444411777777777777777777777777155111fff1ff21fff1fff1ff1551ff16711ff177771111117111111111111111111
777777777777771111111199991111144441111111177777777777777777155111fff1fff9fff1fff1ff1551ff111111ff17777b1bbb17177777771777777771
77777777777771fffffffccccccfff1ee4411ffff111777777777777777155111fff19999fff11111ff1551ff16176161ff1777b1bbb17177777771711111171
7777777777771ffffffffffcfcffff144411ffff1111177777777777771551111111f2f99991fff1ff1551ff167167171ff17771111117177777771717771171
777777777771fff2222fffffffffff11111ffff111111177777777777155111fff1f2f9fff1fff1111551ff11111111111ff1777777777111777771711111171
77777777771ccfffffffffff222fffffffffff1111111117777777777a1111fff1fff9f221fff1fff111ffffffffffffffff1771117777177777771717771171
7777777771fffccffffffffffffff2ff222ff11161116111777777777aaaaa111fff9fff111111ff111111111111111111111171717777177777771711111171
777777771ffffffff2f222ffffffffffffff111671117711177777777777a1111111111111111111111111111111111111111177117777111111111717771171
77777771ffffffffffffffffffffcffffff111677111777111777777777711166111661116666111111111111111111111117771117777111111111711111171
7777771fffffcfffffff222ffffff22fff1111111111111111177777777711166666666666666666661111ff9ff9ff2ff9ff1777777777171717171777777771
777771ffffccffffffffffffcfccfffff111111111111111111177777777111446664466644446666611161ff2ff9ff9ff9ff17111111111111111111111111b
7777accffccfff2f22fffffffffcffff11166666666666666611177777771114444444d4444444ddd4111461ff9ff9ff9ff2ff11111111111111111111bbbbbb
777acccfcffffffffffffff222fffff11144444444444d4444111177777711144ddd4444444d44444d11144611111111111111111111111111111111111111bb
77acccffffffffffffffffffffffff11114444444444dd44441111177777a114d4444444444411114411144416666666661177a777777777771111711111111b
77aaaa111111111111111111111111111144441114441a14441111177777aa1444d44111444117171411144414444444441177a1111111177177771711111111
777777771666666666666666666666441141111714441711111177777777aa14d44411221441111114111d4414491111941177a1111111771771177111111111
777777771444444444444444444444441141111714441711111177777777a114d4411211214117a7141114d414417771141177a7111117771716617111111111
777777771444444444444444444444441144441714441714441177777777a11444411211214411aad41114d41d411111141177a7111117771716617111111111
7777777714444444444444444444d44411444411144411144411777777771114d4411222214d44dd4411144414417771141177a1111111771771177111111111
7777777714411111441111144111114411444d444444444444117777777711144d411222214d4444441114d41441aa11141177a1111111177177771711111111
7777777714411771441177144117714411444444111111eee41177777777111444411121214dd4444411144d94444444441177a777777777771111711111111b
7777777714411111441111144111114411444eee12221144441177777777111999911221211111111111119999111111111177111111111111111111111111bb
77777777144117714411771441177144114444441222114444117777777111119911111221111a1a11111119911111111a11771bbbbbbbbbbbbbbbbbbbbbbbbb
77777777144111a1441111144111a144114444441122114eee1177777771111111911222211a111111111119111111aaa111771bbbbbbbbbbbbbbbbbbbbbbbbb
77777777144444d4444dd4444444d4441144e4ee122211444411777777711111111111111111a11111111111111111111111771bbbbbbbbbbbbbbbbbbbbbbbbb
777777771444444444d44444444d444411444444122211ee441177777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
aaaaa1111111111111111111111111111111111111111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
aaaaaa111111111111111111111111111111111111111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7aaaa1111111111111111111111111111111111111111111111111117bbbbbbbbbbbbbbbbbbbb77777777777777777777777aa77777777777777777777777777
77aa77716661166666661166666661166666661111111111111117777bbbbbbbbbbbbbbbbbbbb77777777777777777777777aa77777777777777777777777777
777aa7716666116666666116666666196666661111111111111117777bbbbbbbbbbbbbbbbbbbb7777777777777777777777aaaa7777777777777777777777777
7777a171444441144444441944444449944444111111111111aa17777bbbbbbbbbbbbbbbbbbbb7777777777777777777777aaaa7777777777777777777777777
77777111dd4444114444d449944444449944441111111111111117777bbbbbbbbbbbbbbbbbbbb77777777777777777777777aa77777777777777777777777777
7777771144444441144dd4449944dd44499444111111a1a1111117777bbbbbbbbbbbbbbbbbbbb777777777777777777777711a17777777777777777777777777
77777771ddd44444144d444449444d444494441111111111111117777bbbbbbbbbbbbbbbbbbbb777777777777777777777711117777777777777777777777777
7777777144444444444444444444d4444444441111111111111117777bbbbbbbbbbbbbbbbbbbb777777777777777777777771177777777777777777777777777
77777771441111144444444444444441111144111111a1a1111117777bbbbbbbbbbbbbbbbbbbb777777777777777777777711117777777777777777777777777
7777777144111114444111111114444111114411111111a1111117777bbbbbbbbbbbbbbbbbbbb777777777777777777777711117777777777777777777777777
7777777144444d4444411212121444444444d411111111aaa11117777bbbbbbbbbbbbbbbbbbbb777777777777777777711111111111777777777777777777777
7777777144444444444112121214444444444411111111a1111117777bbbbbbbbbbbbbbbbbbbb7777777777777777771ff2fff11111177777777777777777777
777777714444444dddd11212121444ddd4444411111111a1111117777bbbbbbbbbbbbbbbbbbbb7777777777777777771f9221f11171177777777777777777777
7777777144d444444441121212144444d444441111111111111117777bbbbbbbbbbbbbbbbbbbb777777777777777771ff9ff9ff1171117777777777777777777
77777771dddd44444dd112121214444dddd444111aaa1111111117777bbbbbbbbbbbbbbbbbbbb777777777777777771cf9ff1ff1117117777777777777777777
77777771444444444441121212144444d4444411111a1111111117777bbbbbbbbbbbbbbbbbbbb7777777777777777acc99f211ff11d1aa777777777777777777
777777711111111111111111111111111111111111111111111117777bbbbbbbbbbbbbbbbbbbb7777777777777777acc9ffff9ff111d11777777777777777777
bbbbbbbbbbb77777777777777777777777777777777777711111aaa1117777777777777777777777777777777777acc99f99f91ff11d11177777777777777777
bbbbbbbbbbb777777777777777777777777777777777777111111a111177777777777777777777777777777777771cf9ff99ff9ff111d1177777777777777777
bbbbbbbbbbb777777777777777777777777777777777777715555155177777777777777777777777777777777771fff9f299ff9fff1117117777777777777777
bbbbbbbbbbb777777777777777777777777777777777777711111111177777777777777777777777777777777711f9f9ff99ff1f1f1117111777777777777777
bbbbbbbbbbb77777771199991111111111199991111111111555515511111111111111777777777777777777711222ff22fffffffff111111177777777777777
bbbbbbbbbbb7777771ffcffcff2ffffcfffcffcfffffffff155551551fff1fffffffff1777777777777777771111111111111111111111111aa7777777777777
bbbbbbbbbbb777771fffcfcff22ffffccfffccffffffffff155551551ff1fffffffcfff17777777777777771777777155555555511111717777a777777777777
bbbbbbbbbbb77771fffffcfff2ffcffffffffffffccfffff15555151ff1ffffcffffccff177777777777777777777714949d9414111117777777777777777777
bbbbbbbbbbb7771fffffffffffffcfffffffffffffcfffff1555511ff1fffffccffffcfff1777777777777777777771d444d4d44111117777777777777777777
bbbbbbbbbbb771ffffcccccfffffcf22ffccccccffffffff111111ff1fffffffffffffffff177777777777777777111111111111111111111777777777777777
bbbbbbbbbbb71ffffcfffffffffffffffffffffffffffccffffffff1ffffffccccfffffffff1777777777777777ccfffffffffff111111111177777777777777
bbbbbbbbbbb1ffffffffffffffffffffffffffffffffffffffffff1fffffffffffffffffffff177777777777771cc92f1ff9221ff11171171117777777777777
bbbbbbbbbbb1111111111111111111111111111111111111111111111111111111111111111117777777777771ff29ff1ff92f1fff111711711a777777777777
bbbbbbbbbbb777117716666666666666666666666666666116611666661111111111117711777777777777771f1f29ff1f29ff12f1f111d11711a77777777777
bbbbbbbbbbb7777117144444411111111114444444dd444116441144441111111111117117777777777777a1ff1ff92f1ff1ff1221ff111d1171111777777777
bbbbbbbbbbb77777111444441555555555514444444dd441164441144411111111111111777777777777aacccfffffffffffffffffffff111111111117777777
bbbbbbbbbbb777777114444955111111115514444444d4411644441444111111111111177777777777aaaaaa1111111111111111111111111111111111777777
bbbbbbbbbbb777777714dd49511414141415144444d4444116444d44441111111111117777777777777a77777111111111111111111111111117777717777777
bbbbbbbbbbb7777777144d49519414141415144444444441164444dd441111111111117777777777777777777155555555555555551555555517777777777777
bbbbbbbbbbb7777777ad4d495199999991151444d44dd44116411199141111777711117777777777777777777144111444441114441441111417777777777777
bbbbbbbbbbb7777777ad444151149494941514444d44444116411444141117171771117777777777777777777144444444444444441441711417777777777777
bbbbbbbbbbb7777777144441511414141415144444d44441164914441411711711771177777777777777777111111111111111111111111111111a7777777777
bbbb111111177777711111111111111111111114444dd441164911111411777777771177777777777777771ffffffffff22fffffffff111111111aa777777777
bbbb1bbb1bb777771fffffffffffffffffff1ff14444444116499444141171171177117777777777777771ff1ff1f29ff9229ff1ff9221117111daa177777777
bbbb1bbb1bb77771ffcccffffffcfffffffff1ff144444411649944414111717177111777777777777771f2f1ff1221ff1f29ff1229fff1117111d1117777777
b1111111111777affffffffcfcfffffcffffff1ff1444d41164111111411117777111177777777777771f1221ff92f9ff9ff9ff9f21ff9f111d1117111777777
1777777777777accfcfffffffcffffcccffffcf1ff14444116466666641111111111117777777777711ff1f21ff1ff1f21ff1ff1ff1f29ff1117111711117777
171111111117acfffccccfffffffffcfffffffff1ff14441164444444411111111111a77777777711fffffffffffffffffffffffffff2fffff11111111111177
17117171717acccffffffffffffffffffffffffff1ff144116444444441111111111aa7777777111111111111111111111111111111111111111111111111111
17171717171aaa1111111111111111111111111111111441164ddd44441a111111111a7777777717777711555555115151515151555555115555155551777717
17711111111777166666666666666666666666611116644116444444441111111111117777777777777711449944114141414141449144114444444411777777
b11777777777771444444444444444444444444111144441164444ddd411111111a1117777777777777711d419441111111111114d1144114111111141777777
bbb111111117771441111444419914444199144111144441164d44444411111111111177777777777777114411441444444444414d9944114177171141777777
bbbbbbbb111777141111114411111144119111411114dd411644d444441111a111111177777777777777a1444444111111111111444444114111171141777777
bb1111111117771114414411144144111449441111144d411644444d441111a111111177777777777777a149d9d41111111111114d9d94114177171141777777
b17111177777771199999999111111111119111111144d4116444dd44411111111a11177777777777777a1ddd44411fff11ffff14444441141aa111141777777
171777717717771114414491144944991449441111144441164411114411aaa111a11177777777777777a149494411f2f11f22f1dd94941145555555da777777
11771177177777111119191111991111119911111114d4411641122214111111111a11777777777777771144444d11f2f11ff2f1dd444411444d444d4a777777
11716617177777111441449994494411144944111114dd411641122214111111111111777777777777771149d94411fff11ffff14494941144444444da777777
117166171777771111119911111111111119111111144d411641122214111a11111111777777777777771144d44411f1f11f1ff144444411444d11dd41777777
1177117717777711144144111441441114414411111444411641112214111a111a1111777777777777a111111111112ff11ffff1111111111119919111117777
171777717717771111111111111111111111111111144d411641122214111111111111777777777777a7111414141122f11ffff141414111414149d1417a7777
b171111777777714141414141414141414141411111444411641122214111111111111777777777777171114141411fff11ffff14141411141414141417a7777
bb111111111777111111111111111111111111111111111111111111111111111111117777777777771111111111111111111111111111111111111111aa7777
__map__
5051525300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6061626300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7071727300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
