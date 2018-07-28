pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--main

-- game settings
ground_y = 108
scaffolding_y = 30

rock_push_force = 0.5
rock_push_time = 15
rock_damage = 10

cat_move_speed = 0.65
cat_charge_full_duration = 15
cat_push_range = 10
cat_hpush_freeze = 12
cat_vpush_freeze = 12

bucket_push_force_min = 1.5
bucket_push_force_max = 2.5
bucket_push_time = 15
bucket_shake_time = 15
bucket_shake_nbbullets_min = 1
bucket_shake_nbbullets_max = 3
bucket_paint_capacity_max = 10
bucket_refill_position = 14
bucket_refill_period = 8
bucket_refill_value = 1

demolisher_xmin = -30
demolisher_xmax = 25
demolisher_ball_damage = 50
demolisher_idletime_start = 180
demolisher_stun_time = 30
demolisher_stun_speed = 0.5
demolisher_move_time = 30
demolisher_move_speed = 0.5
demolisher_retreat_xmin = 0
demolisher_retreat_speed = 0.5
demolisher_trail_pop = 0

builing_type_start = 1
building_life_max = 100
building_complete_hide = 60
building_complete_duration = 180
building_paint_surface_bonus = 25
building_blink_frame = 0

score_bonus_building_paint = 10
score_bonus_demolisher_hit = 5
score_bonus_building_completed = 50

difficulty_building_step = 3
difficulty_factor_paintsurface = 0.3
difficulty_factor_demolisher_idletime = 0.2

debug_collisions = false

title_active = false
tuto_active = false

-- global vars
score = 0
nb_building_completed = 0
particles = {}
gr_paint = {}
gameover = false
lang = 1

--screen shake struct
scr = {
 x = 0,
 y = 0,
 intensity_x = 0,
 intensity_y = 0,
 shake_time = 0
}

function reset_game()
 gameover = false
 score = 0
 nb_building_completed = 0
 particles = {}
 gr_paint = {}
 paintbullets_arr = {}
 building_paint_surface_bonus = 25
 _init()
end

function _init()
 building = building_init(builing_type_start)
 cat = cat_init()
 demolisher = demolisher_init()
 bucket = bucket_init()
 painttap = painttap_init();
 music(2)
end

local key = false
function _update60()
 if(not btn(4) and not btn(5)) key=false

 if(not tuto_active and
    not title_active and
    not gameover) then
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
 perform_shake()
 if(not gameover) then
  building_draw(building)
  demolisher_draw(demolisher)
  painttap_draw(painttap)
  cat_draw(cat)
  bucket_draw(bucket)
  foreach(paintbullets_arr, paintbullet_draw)
  foreach(rocks_arr, rock_draw)
  print_outline("\x92 "..num_format(score, 4), 100, 122, 7, 1)
 end
 --print("cpu=".. stat(1), 0, 112)
 --print("mem=".. stat(0), 0, 120)
 --print("nb part="..#particles, 0, 120)
 if(title_active) scene_title()
 if(tuto_active) scene_tuto(lang)
 if(gameover) scene_gameover() --print("gameover", 48, 64, 8)
 if(tra == 0) foreach(particles, draw_particle)
 foreach(gr_paint, draw_ground_paint)
 draw_flash()
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

function game_sfx(n)
 sfx(n,3)
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
    c.x += cat_move_speed
    c.spr_flip = false
    cat_setanim(c, "walk")
   elseif btn(0) then
    c.x -= cat_move_speed
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
     game_sfx(13)
    end
   end

   if c.charge_type == 1 and not btn(5) then
    cat_setanim(c, "push_release")
    c.push_type = 1
    c.push_countdown = 8
    c.freeze = cat_hpush_freeze   
    c.charging = false
   end

   if c.charge_type == 2 and not btn(4) then
    cat_setanim(c, "push_release")
    c.push_type = 2
    c.push_countdown = 8
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
 local anim_speed = 8
 if(c.anim_name == "push_release") anim_speed = 4
 anim_frame += 1
 if anim_frame >= anim_speed then
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
  game_sfx(16)
  local push_dir = 1
  if (c.spr_flip) push_dir = -1
  
  local rock = rocks_getclosest(c.x, cat_push_range)
  if rock != nil then
   rock_push(rock, push_dir)
  elseif is_cat_near_bucket() then
   bucket_push(bucket, push_dir, c.charge_ratio)
  end
 elseif c.push_type == 2 then
  game_sfx(16)
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
  paint_surface_max = 100,
  paint_surface_ratio = 0,
  paint_surface_y = 0,
  life = 100,
  completed = false,
  completed_timer = 0,
  show_transition = true,
  hide_transition = false,
  height = 0,
 }

 if type == 1 then
  b.cx = 5
  b.cw = 45
  b.ch = 40
  b.spr_x = 0
  b.spr_y = 32
  b.spr_w = 57
  b.spr_h = 52
  b.paint_surface_max = 100
  b.damage_multiplier = 1
 elseif type == 2 then
  b.x = 80
  b.cx = 0
  b.cw = 46
  b.ch = 40
  b.spr_x = 56
  b.spr_y = 32
  b.spr_w = 47
  b.spr_h = 32
  b.paint_surface_max = 70
  b.damage_multiplier = 2
 elseif type == 3 then
  b.x = 80
  b.cx = 0
  b.cw = 45
  b.ch = 59
  b.spr_x = 77
  b.spr_y = 67
  b.spr_w = 51
  b.spr_h = 59
  b.paint_surface_max = 120
  b.damage_multiplier = 1
 elseif type == 4 then
  b.x = 65
  b.cx = 7
  b.cw = 57
  b.ch = 48
  b.spr_x = 11
  b.spr_y = 84
  b.spr_w = 69
  b.spr_h = 44
  b.paint_surface_max = 150
  b.damage_multiplier = 0.7
 end
 b.type = type

 return b;
end

function building_update(b)
 if(building_blink_frame > 0) then
  building_blink_frame -= 1
 end
 b.paint_surface_ratio = b.paint_surface / b.paint_surface_max

 if b.completed then
  b.completed_timer += 1
  if b.completed_timer >= building_complete_hide then
   b.hide_transition = true
  end
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
 local paint_ystart = yend - (height) * b.paint_surface_ratio
 local paint_height = yend - paint_ystart
 b.paint_surface_y =  ground_y - paint_height
end

function building_draw(b)
 if(building_blink_frame > 0 and
    building_blink_frame%4 == 0) then
    return
 end
 if b.show_transition then
  b.height += 1
  if b.height >= b.spr_h then
   b.height = b.spr_h
   b.show_transition = false
  end
 end

 if b.hide_transition then
  b.height -= 1
  if b.height <= 0 then
   b.height = 0
   b.hide_transition = false
  end
 end

 -- building (with paint completion)
 local ystart = b.spr_y
 local yend = ystart + b.spr_h
 local height = yend - ystart
 local completed_ystart = yend - (height) * b.paint_surface_ratio
 local completed_height = yend - completed_ystart
 if b.completed then
  building_draw_part(b.spr_x, ystart, b.spr_w, b.height, b.x, ground_y-b.height,1)
 else
  if b.paint_surface_ratio > 0 and
     not gameover then
   rectfill(b.x, b.paint_surface_y, b.x + b.spr_w-1, ground_y-1, 8)
  end
  local mode = 0
  if(gameover) mode = 2
  building_draw_part(b.spr_x, ystart, b.spr_w, b.height, b.x, ground_y-b.height,mode)
 end

 -- gauge
 if not b.completed and not gameover then
  local gauge_min = b.x + 10
  local gauge_max = b.x + b.spr_w - 10
  local gauge_y = ground_y - b.height - 7
  rect(gauge_min-1,gauge_y-2,gauge_max+1,gauge_y+2,0)
  if b.life > 0 then
   local gauge_ratio = 1 - b.life / building_life_max
   local gauge_val = gauge_min + flr(gauge_ratio * (gauge_max - gauge_min))
   rectfill(gauge_val,gauge_y-1,gauge_max,gauge_y+1,8)
  end
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
 b.life -= flr(damage * b.damage_multiplier)
 shake_screen(2,3,40)
 building_blink_frame = 80
 game_sfx(10)
 if b.life <= 0 then
  game_sfx(11)
  music(-1)
  b.life = 0
  gameover = true
  building_blink_frame = 0
  explosion_frame = 120
  gameover_score_timeout = 0
  y_destroy = 0
  for p in all(particles) do del(particles,p) end
 end
end

function building_paint(b, surface)
 b.paint_surface += surface
 if b.paint_surface >= b.paint_surface_max then
  b.paint_surface = b.paint_surface_max
  if not b.completed then
   building_complete(b)
  end
 else
  score += score_bonus_building_paint
  game_sfx(19)
 end
 b.paint_surface_ratio = b.paint_surface / b.paint_surface_max
end

function building_complete(b)
 game_sfx(14)
 b.completed = true
 b.completed_timer = 0
 score += score_bonus_building_completed
 nb_building_completed += 1
 flash_screen()
 shake_screen(3,3,11)
 if nb_building_completed % difficulty_building_step == 0 then
  demolisher.idle_time -= demolisher.idle_time * difficulty_factor_demolisher_idletime
  building_paint_surface_bonus -= building_paint_surface_bonus * difficulty_factor_paintsurface
 end
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
function building_draw_part(x,y,w,h,px,py,mode)
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
 if(mode == 1) pair = pair_clean
 --applying parity
 if(mode != 2) then
	 for pa in all(pair) do
   pal(pa[1],pa[2])
 	end
 else --if gameover
  for i=0,15 do
   if(i != 1 and i != 12) then
    pal(i,1)
   else
    pal(i,7)
   end
  end
 end
 --drawing sprite
 if(mode == 0) then
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
  idle_time = demolisher_idletime_start,
  move_time = demolisher_move_time,
  move_speed = demolisher_move_speed,
  stun_time = 0,
  stun_speed = demolisher_stun_speed,
  retreat_speed = demolisher_retreat_speed,
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
  d.stun_time -= 1
  if d.stun_time <= 0 then
   demolisher_idle(d)
  end

 elseif state == demolisher_state_retreat then
  if d.x > demolisher_retreat_xmin then
   d.x -= d.retreat_speed
  end
  if (d.x <= demolisher_retreat_xmin) and (not building.completed) then
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
 sspr(0, 106, 11, 11, d.x-16, spr_y+11)
 sspr(0, 117, 11, 1, d.x-16, d.y-11)
 sspr(0, 117, 11, 11, d.x-16, d.y-11)
 -- base part2
 sspr(103, 32, 25, 19, d.x-16+11, spr_y+4)
 sspr(103, 50, 25, 1, d.x-16+11, d.y-12+3)
 sspr(103, 51, 25, 13, d.x-16+11, d.y-13+3)
 --sspr(0, 117, 48, 1, d.x-16, d.y-12)
 --sspr(0, 117, 48, 11, d.x-16, d.y-11)
 --trail
 rectfill(d.x+4,d.y-34+d.shake_offset,d.x+6,d.y-29+d.shake_offset,1)
 demolisher_trail_pop += 1
 if(demolisher_trail_pop >= 10) then
  demolisher_trail_pop = 0
  add_particle(d.x+5,d.y-38+d.shake_offset,
   rnd(0.2)-0.1,rnd(0.25)-0.5,
   rnd(1)+3,6,0,128,40,1.02)
 end
 -- arm
 local arm_x = d.x + 11
 local arm_y = d.y - 30 + d.shake_offset
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
 d.stun_time += demolisher_stun_time
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
  x = 95,
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
   bucket_addpaint(bucket, bucket_refill_value)
   b.refill_timer = bucket_refill_period
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

 if(b.x < bucket_refill_position) b.x = bucket_refill_position
 if(b.x > 124) b.x = 124
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
  if (i > 0) x += (i*2 -1) * rnd_range(3,6)
  paintbullet_create(x)
  i += 1
 end

 b.state = bucket_state_shake
 b.state_time = 0
end

function bucket_refill_start(b)
 if(b.refilling) return
 b.refilling = true
 b.refill_timer = bucket_refill_period
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
 return bucket.x <= bucket_refill_position
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
   building_paint(building, building_paint_surface_bonus)
   paintbullet_destroy(p)
  end
 elseif collide_with_demolisher(demolisher, p.x, p.y) then
  add_splash(p.x,p.y)
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
  x = 0,
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
  rectfill(p.x+12, p.y+13, p.x+14, p.y+25,8)
  if(bucket.paint_capacity ==
     bucket_paint_capacity_max) then
   add_particle(p.x+13,p.y+25,
   rnd(0.6)-0.3,rnd(0.2)-0.6,
   1,8,0.1,30,20,1)
  end
 end

 -- trigger
  local trigger_xmin = bucket_refill_position -3
  local trigger_xmax = bucket_refill_position +1
  local trigger_ymin = scaffolding_y
  local trigger_ymax = scaffolding_y - 1
  if p.opened then
   trigger_ymax += 1
  end
  rectfill(trigger_xmin, trigger_ymin, trigger_xmax, trigger_ymax, 8)
  rect(trigger_xmin-1, trigger_ymin, trigger_xmax+1, trigger_ymax -1, 1)
  spr(46, p.x, p.y, 2, 2, true)
end

function painttap_open(p)
 if(p.opened) return;
 game_sfx(17)
 p.opened = true
 p.refill_timer = 60
end

function painttap_close(p)
 if(not p.opened) return;
 game_sfx(18)
 p.opened = false
end

function add_particle(x,y,vx,vy,r,c,g,gr,f,ra,sp,txt)
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
 part.ratio = ra
 part.sp = sp
 part.txt = txt
 part.bounce = 2
 if(ra == nil) part.ratio = 1.025
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
 if(p.sp != nil) then
  sspr(p.sp.x,p.sp.y,p.sp.w,p.sp.h,p.x,p.y,p.sp.w,p.sp.h)
 elseif(p.txt != nil) then
  print(p.txt,p.x,p.y,p.col)
 else
  circfill(p.x,p.y,p.radius,p.col)
 end
 p.x += p.vx
 p.y += p.vy
 if(p.ground != nil and
    p.y+p.radius > p.ground) then
  p.y = p.ground - p.radius
  if(p.col == 8 and p.sp == nil and
     p.txt == nil) then
   add_ground_paint(p.x,p.ground)
  end
  if(p.bounce > 0 and
     p.txt != nil) then
   p.vy = -0.5*p.bounce-rnd(0.25)
   p.bounce -= 1
  end
 end
 if(p.gravity != nil and
    p.vy < 2) then
  p.vy += p.gravity
 end
 p.radius = p.radius / p.ratio
 p.frame -= 1
 if(p.frame <= 0 and p.txt == nil) del(particles,p)
end

function add_ground_paint(x,y)
 for pa in all(gr_paint) do
  if(flr(pa.x) == flr(x)) then
   if(abs(pa.y0 - pa.y1) < pa.maxy and
      flr(rnd(8)) == 1) then
    pa.y1 += 1
   end
   return
  end
 end
 if(flr(rnd(8)) == 1) then
  local paint = {}
  paint.x = x
  paint.y0 = y
  paint.y1 = y
  paint.c = 8
  paint.maxy = rnd(4)+2
  add(gr_paint,paint)
 end
end

function draw_ground_paint(pa)
 line(pa.x,pa.y0,pa.x,pa.y1,pa.c)
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
 {"repair","repare"},
 {"❎ restart","❎ recommencer"}
}

--center text
function ctxt(txt,x,y,c)
 print(txt,x-#txt/2*4,y,c)
end


--show tuto
tuto_page = 0
next_x = 0
key_n = false
tra = 0
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
 if(tuto_page < 0) then
  scene_title()
 elseif(tuto_page == 0) then
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
  building_draw_part(0,32,54,25,50,90,0)
  circfill(72,90,3,8)
  print(txts[10][lang],39,88,8)
 end
 --next page press
 if(btn(5) and not key_n and
    tra == 0) then
  key_n = true
  tra = 64
  game_sfx(14)
 end
 if(not btn(5)) key_n = false
 if(tra == 32) tuto_page += 1
 if(tra == 0 and tuto_page > 2) tuto_active = false
 if(tra != 0) scene_transition()
end

--show title screen
title_y = 0
title_up = false
title_shine = 0
title_start = 0
function scene_title()
 cls(1)
 --variables
 if(title_up) title_y -= 0.1
 if(not title_up) title_y += 0.1
 title_shine += 2
 palt(7,true)
 --shine effect
 rectfill(34,14+title_y,92,23+title_y,7)
 if(title_shine < 58) then
  local r = 0.6
  r = 0.6 - title_shine/55
  for y=0,9 do
   line(34+title_shine+(9-y)*r,14+y+title_y,34+title_shine+8+(9-y)*r,14+y+title_y,6)
  end 
 end
 rectfill(93,14+title_y,128,23+title_y,1)
 --sspr text
 sspr(57,64,20,10,34,14+title_y)
 sspr(57,74,20,10,54,14+title_y)
 sspr(0,84,11,10,74,14+title_y)
 sspr(0,94,8,10,85,14+title_y)
 palt(7,false)
 --description
 ctxt("save the old!",65,27+title_y,8)
 ctxt("save the old!",64,26+title_y,7)
 --cat sleeping
 pal(1,7)
 sspr(99,28,12,4,54,68)
 local head = 0
 if(title_shine > 200) head = 1
 sspr(106,24,7,7,61,65-head)
 if(title_shine % 60 == 0 and 
    tra == 0 and title_active) then
  add_particle(63,57,rnd(0.2)-0.1,
    rnd(0.05)-0.1,0,1,0,
    128,75,1,
    {x=108,y=18,w=4,h=4})
 end
 pal()
 --flags
 rect(31,85,49,97,7)
 rectfill(38,87,42,95,7)
 rectfill(43,87,47,95,8)
 rect(78,85,96,97,7)
 rectfill(80,90,94,92,7)
 rectfill(86,87,88,95,7)
 line(80,87,94,95,7)
 line(94,87,80,95,7)
 line(80,91,94,91,8)
 line(87,87,87,95,8)
 if(title_shine > 80 or
    title_start > 0) then
  local c1 = 7
  local c2 = 7
  if(title_start > 0 and title_start/2%2 == 0 and lang == 2) c1 = 8
  if(title_start > 0 and title_start/2%2 == 0 and lang == 1) c2 = 8
  ctxt("presser",35,104,c1)
  if(c1 == 7) spr(1,53,104)
  if(c1 == 8) spr(17,53,104)
  ctxt("press ❎",87,104,c2)
 end
 --frames variables
 if(title_y > 8) title_up = true
 if(title_y < 0)  title_up = false
 if(title_start > 0) title_start -= 1
 if(title_start == 10) then
  tuto_page = -1
  tra = 120
  tuto_active = true
  title_active = false
  for p in all(particles) do del(particles,p) end
 end
 if(title_shine >= 400) title_shine = 0
 --start
 if((btn(5) or btn(4)) and 
    not key_n and
    title_start == 0 and
    tra == 0) then
  key_n = true
  title_start = 80
  game_sfx(14)
  if(btn(5)) lang = 1
  if(btn(4)) lang = 2
 end
 if(not btn(5) and not btn(4)) key_n = false
end

--gameover scene
explosion_frame = 0
y_destroy = 0
smoke_destroy = 0
gameover_score_timeout = 0
function scene_gameover()
 cls(1)
 local b = building
 building_draw_part(b.spr_x,b.spr_y+y_destroy,b.spr_w,b.spr_h-y_destroy+1,b.x-b.cx,ground_y-b.spr_h+y_destroy,2)
 if(explosion_frame > 0) explosion_frame-=1
 if(explosion_frame > 0 and
    explosion_frame%20 == 0) then
  add_explosion(b.x+b.cx,b.x-b.cx+b.cw,ground_y-b.spr_h+y_destroy)
  shake_screen(1,1,10)
 end
 if(explosion_frame > 10 and
    explosion_frame < 100 and
    (explosion_frame+10)%20 == 0) then
  y_destroy += b.spr_h/5
 end
 smoke_destroy += 1
 if(explosion_frame == 0 and
    smoke_destroy >= 20) then
  smoke_destroy = 0
  add_particle(b.x+rnd(b.spr_w-6)+3,
   ground_y-b.spr_h+y_destroy-5,
   rnd(0.2)-0.1,rnd(0.25)-0.5,
   rnd(1)+3,6,0,128,40,1.02)
 end
 if(explosion_frame == 1) then
  local letters = {"g","a","m","e","o","v","e","r"}
  local i = 0
  for l in all(letters) do
   add_particle(48+i*4,-50-i*15,0,0,
    1,7,0.05,50,-1,1,nil,l)
   i += 1
  end
  gameover_score_timeout = 1
 end
 if(gameover_score_timeout > 0) gameover_score_timeout += 1
 if(gameover_score_timeout > 220) then
  ctxt("score "..num_format(score, 4),64,58,8)
  print(txts[11][lang],3,121,7)
  if(btnp(4) or btnp(5)) reset_game()
 end 
end

function add_explosion(x0,x1,y)
 while x0 < x1 do
	 add_particle(x0+rnd(3)-1.5,
   y+rnd(3)-1.5,0,0,rnd(2)+2,
   8,0,128,9+rnd(3),0.9)
  x0 += 6
 end
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

--screen shake
function shake_screen(x,y,t)
 scr.intensity_x = x
 scr.intensity_y = y
 scr.shake_time = abs(t)
end

function perform_shake()
 if(scr.shake_time > 0) then
  scr.x = (rnd(2)-1)*scr.intensity_x
  scr.y = (rnd(2)-1)*scr.intensity_y
  scr.shake_time -= 1
 else
  scr.x = 0
  scr.y = 0
 end
	camera(scr.x,scr.y)
end

flash_frame = 0
function flash_screen()
 flash_frame = 8
end

function draw_flash()
 if(flash_frame > 0) then
  local c = 7
  if(flash_frame < 2 or
     flash_frame > 6) then
   c = 6
  end
  rectfill(-5,-5,133,133,c)
  flash_frame -= 1
 end
end

__gfx__
bb1bbbbb17777711bbbbbbb11111bbbbbbb1111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb11bbb77111771bbbbb111177711bbbb116161bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb1bb1bb77177771bbbb11111111771bbb111661bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b1bbbb1b77111771bbb1111111111171bbb1111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b1bbbbbb17777711bbb1711111111171bbbbbbbbbbbbbbbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
111bbbbb11111111bb171711111111171bbbbbbbbbbbbbbb11b11bbbbbbbbbbbbb1b1bbbbbbbbbbbb11b11bbbbbbbbbbbb1b1bbbbbbbbbbbbb1b1bbbbbbbbbbb
111bbbbb11111111bb117111111111171bbbbbbbbbbbbbbb11b11bbbbbbbbbbbb11b11bbbbbbbbbb111111bbbbbbbbbbb11b11bbbbbbbbbbb11b11bbbbbbbbbb
b1bbbbbb11111111bb171711111111171bbbbbbbbbbbbbb1111111bbbbbbbbbb111111bbbbbbbbbb117171bbbbbbbbbb111111bbbbbbbbbb111111bbbbbbbbbb
1bbb1bbb18888811bb117111111111171bbbbbbbbbbbbbb1171711bbbbbbbbbb117171bbbbbbbbbb117171bbbbbbbbbb117171bbbbbbbbbb117171bbbbbbbbbb
b111bbbb88111881bb171711111111111bbbbbbbbbbbbbb1171711bbbbbbbbbb117171bbbbbbbbbbb1111bbbbbbbb1bb117171bbbbbbbbbb117171bbbbbbbbbb
1bbb1bbb88188881bbb1711111111111bbbbbbbbbbbb1bbb11111bbbbbbb1bbbb1111bbbbbb11bbbb111bbbbbbbbb1bbb1111bbbbbbb1bbbb1111bbbbbbbbbbb
bbbbbbbb88111881bbb1171111111111bbbbbbbbbbbb1bbbb111bbbbbbbb1bbbb111bbbbbbbbb1b11111bbbbbbbbb1b11111bbbbbbbbb1bbb111bbbbbbbbbbbb
11bb111b18888811bbbb11711111111bbbbbbbbbbbbbb1b11111bbbbbbbbb1b11111bbbbbbbbbb11111111bbbbbbbb111111bbbbbbbbb1b11111bbbbbbbbbbbb
11b1bbb111111111bbbbb117111111bbbbbbbbbbbbbbbb111111bbbbbbbbbb111111bbbbbbbbb11111111bbbbbbbb1111111bbbbbbbbbb111111bbbbbbbbbbbb
bbbbbb1b11111111bbbbbbb11111bbbbbbbbbbbbbbbbbb111111bbbbbbbbbb1111111bbbbbbbb11bbbbbbbbbbbbbbbbbb111bbbbbbbbbb111111bbbbbbbbbbbb
11bb111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1b11b1bbbbbbbbbb11bb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbb11bbbbbbbbbbb11b1bbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17777771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb11b11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb71177117bbbbbbbbbbbb7777bbbbbbbbbbbbbbbb
bb111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb77711777bbbbbbbbbbbb1171bbbbbbbbbbbbbbbb
bb117171bbbbbbbbbbbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111bbb11111111bbbbbbbbbbbb1711bbbbbbbbbbbbbbbb
bb117171bbbbbbbbbbbb11b116bbbbbbbbbbbbbbb6bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbb1bbbbbbbbbbbbbbbbbbbbbb7777bbbbb11b11b11bbb
bbb1111bbbbbbbbbbbb111111b6bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11111111bbb
bbb1111111bbbbbbbbb117171b6bbbbbbbbbbbb1b166bbbbbbbbbbb1b1bbbbbbbbbbbbb1b1bbbbbb1bbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11bbbbbb
bbb111111bbbbbbbbbb117171b66bbbbbbbbbb11b116bbbbbbbbbb11b11bbbbbbbbbbb11b11bbbbb1bbbbb1bbbbbbbbbbbbbbbbbbbbb1b1bbbbbbbb1771bbbbb
bbb1111bbbbbbbbbbbbb1111bb66bbbb1bbbb11111166bbb1bbbb1111116bbbb1bbbb111111bbbbb1111111bbbbbbb111bbbbbbbbbb11b11bbbbbb111111bbbb
bbb1111bbbbbbbbbbbbb1111116bbbbbb1bbb117171b66bbb1bbb117171bbbbbb1bbb117171bbbbb1111111bbbbbb17711bbbbbbbbb11b11bbbbbbb1111bbb11
bbb1111bbbbbbbbbbbb1111116bbbbbbb1bbb117171b666bb1bbb117171b6bbbb1bbb117171bbbbb1bb11b1bbbbb1777111bbbbbbb1111111b11111171717111
b11111bbbbbbbbbb1111111bbbbbbbbbb1111b1111bbb66bb1111b1111bb66bbb1111b1111bbbbbb1bb1bb1bbbb17771711bbb1b111111111177111117171711
1bb111bbbbbbbbbbbbb111bbbbbbbbbbb11111111bbbb66bb11111111bbbb6bbb11111111bbbbbbb1bbbbb1bbb17771171bb1111111111111171111111111111
bbb111bbbbbbbbbbbbb111bbbbbbbbbbbb111111111166bbbb111111111166bbbb1111111111bbbb1bbbbb1bb17771711bb1bb1111111111b111bbb1111bbb11
bbb11bbbbbbbbbbbbbb11bbbbbbbbbbbbbb11bbb11166bbbbbb11bbb11166bbbbbb11bbb111bbbbbb11111bb17771111bbb11bb11111111bb111bbbb11bbbbbb
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
777777771444444444d44444444d444411444444122211ee44117777711117777711777771777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
aaaaa111111111111111111111111111111111111111111111111111111117777787777787777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
aaaaaa11111111111111111111111111111111111111111111111111111177887787777887777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7aaaa11111111111111111111111111111111111111111111111111171177887778778881187777777777777777777777777aa77777777777777777777777777
77aa777166611666666611666666611666666611111111111111177771177777887777711177777777777777777777777777aa77777777777777777777777777
777aa7716666116666666116666666196666661111111111111117777177777781778888117777777777777777777777777aaaa7777777777777777777777777
7777a171444441144444441944444449944444111111111111aa17777177777787777711117777777777777777777777777aaaa7777777777777777777777777
77777111dd4444114444d4499444444499444411111111111111177777778777877777711177777777777777777777777777aa77777777777777777777777777
7777771144444441144dd4449944dd44499444111111a1a111111777777787787777778817778777777777777777777777711a17777777777777777777777777
77777771ddd44444144d444449444d44449444111111111111111777718881881888888111888777777777777777777777711117777777777777777777777777
7777777144444444444444444444d444444444111111111111111777777177777111777111777777777777777777777777771177777777777777777777777777
77777771441111144444444444444441111144111111a1a111111777777877777717777717777777777777777777777777711117777777777777777777777777
7777777144111114444111111114444111114411111111a111111777777877887787777787777777777777777777777777711117777777777777777777777777
7777777144444d4444411212121444444444d411111111aaa1111777788877817787788787778777777777777777777711111111111777777777777777777777
7777777144444444444112121214444444444411111111a1111117777811777778877817777787777777777777777771ff2fff11111177777777777777777777
777777714444444dddd11212121444ddd4444411111111a1111117777811777777177817787787777777777777777771f9221f11171177777777777777777777
7777777144d444444441121212144444d44444111111111111111777781177777787777778777777777777777777771ff9ff9ff1171117777777777777777777
77777771dddd44444dd112121214444dddd444111aaa111111111777781777877787777778777777777777777777771cf9ff1ff1117117777777777777777777
77777771444444444441121212144444d4444411111a1111111117777817778777817777881777777777777777777acc99f211ff11d1aa777777777777777777
777777711111111111111111111111111111111111111111111117777111888188811888811187777777777777777acc9ffff9ff111d11777777777777777777
7111777117777777777777777777777777777777777777711111aaa1117777777777777777777777777777777777acc99f99f91ff11d11177777777777777777
77177777117777777777777777777777777777777777777111111a111177777777777777777777777777777777771cf9ff99ff9ff111d1177777777777777777
77877787711777777777777777777777777777777777777715555155177777777777777777777777777777777771fff9f299ff9fff1117117777777777777777
88877888771777777777777777777777777777777777777711111111177777777777777777777777777777777711f9f9ff99ff1f1f1117111777777777777777
1111777777877777771199991111111111199991111111111555515511111111111111777777777777777777711222ff22fffffffff111111177777777777777
111177777777777771ffcffcff2ffffcfffcffcfffffffff155551551fff1fffffffff1777777777777777771111111111111111111111111aa7777777777777
77717778777777771fffcfcff22ffffccfffccffffffffff155551551ff1fffffffcfff17777777777777771777777155555555511111717777a777777777777
7778177787777771fffffcfff2ffcffffffffffffccfffff15555151ff1ffffcffffccff177777777777777777777714949d9414111117777777777777777777
777817788177771fffffffffffffcfffffffffffffcfffff1555511ff1fffffccffffcfff1777777777777777777771d444d4d44111117777777777777777777
88881188111771ffffcccccfffffcf22ffccccccffffffff111111ff1fffffffffffffffff177777777777777777111111111111111111111777777777777777
7777711111171ffffcfffffffffffffffffffffffffffccffffffff1ffffffccccfffffffff1777777777777777ccfffffffffff111111111177777777777777
777777111111ffffffffffffffffffffffffffffffffffffffffff1fffffffffffffffffffff177777777777771cc92f1ff9221ff11171171117777777777777
777777811111111111111111111111111111111111111111111111111111111111111111111117777777777771ff29ff1ff92f1fff111711711a777777777777
18778811111777117716666666666666666666666666666116611666661111111111117711777777777777771f1f29ff1f29ff12f1f111d11711a77777777777
117778111117777117144444411111111114444444dd444116441144441111111111117117777777777777a1ff1ff92f1ff1ff1221ff111d1171111777777777
1117781111177777111444441555555555514444444dd441164441144411111111111111777777777777aacccfffffffffffffffffffff111111111117777777
81177781111777777114444955111111115514444444d4411644441444111111111111177777777777aaaaaa1111111111111111111111111111111111777777
71177781111777777714dd49511414141415144444d4444116444d44441111111111117777777777777a77777111111111111111111111111117777717777777
781177781117777777144d49519414141415144444444441164444dd441111111111117777777777777777777155555555555555551555555517777777777777
881118881117777777ad4d495199999991151444d44dd44116411199141111777711117777777777777777777144111444441114441441111417777777777777
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
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111777771177777177777177777111777111777711177711777777711111111111111111111111111111111111111
11111111111111111111111111111111111111777778777778777777877777717777717777771777771177777771111111111111111111111111111111111111
11111111111111111111111111111111111117788778777788777777877887787777787777778777877117777778111111111111111111111111111111111111
11111111111111111111111111111111111177887778778881187788877817787788787778888778887711877881111111111111111111111111111111111111
11111111111111111111111111111111111177777887777711177781177777887781777778111177777781177781111111111111111111111111111111111111
11111111111111111111111111111111111777777817788881177781177777717781778778111177777771117781111111111111111111111111111111111111
11111111111111111111111111111111111777777877777111177781177777787777778777777177787778117778111111111111111111111111111111111111
11111111111111111111111111111111117778777877777711177781777877787777778777777817778777117778111111111111111111111111111111111111
11111111111111111111111111111111117778778777777881777881777877781777788177777817788177811777811111111111111111111111111111111111
11111111111111111111111111111111111888188188888811188811188818881188881118888811881118811188811111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111177177717171777111117771717177711111177171117711171111111111111111111111111111111111111111
11111111111111111111111111111111111111718878787878788811111788787878881111717878117871178111111111111111111111111111111111111111
11111111111111111111111111111111111111777177787878771111111781777877111111787878117878178111111111111111111111111111111111111111
11111111111111111111111111111111111111187878787778788111111781787878811111787878117878118111111111111111111111111111111111111111
11111111111111111111111111111111111111771878781788777111111781787877711111771877717778171111111111111111111111111111111111111111
11111111111111111111111111111111111111188118181181188811111181181818881111188118881888118111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111777711111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111117777111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111171111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111711711111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111117777111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111171711111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111771771111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111771771111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111117777777111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111171777777777111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111117777777777777111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111171177777777771111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111177117777777711111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111117777777777777777777111111111111111111111111111177777777777777777771111111111111111111111111111111
11111111111111111111111111111117111111111111111117111111111111111111111111111171111111111111111171111111111111111111111111111111
11111111111111111111111111111117111111777778888817111111111111111111111111111171711111787111117171111111111111111111111111111111
11111111111111111111111111111117111111777778888817111111111111111111111111111171177111787111771171111111111111111111111111111111
11111111111111111111111111111117111111777778888817111111111111111111111111111171111771787177111171111111111111111111111111111111
11111111111111111111111111111117111111777778888817111111111111111111111111111171777777787777777171111111111111111111111111111111
11111111111111111111111111111117111111777778888817111111111111111111111111111171888888888888888171111111111111111111111111111111
11111111111111111111111111111117111111777778888817111111111111111111111111111171777777787777777171111111111111111111111111111111
11111111111111111111111111111117111111777778888817111111111111111111111111111171111771787177111171111111111111111111111111111111
11111111111111111111111111111117111111777778888817111111111111111111111111111171177111787111771171111111111111111111111111111111
11111111111111111111111111111117111111777778888817111111111111111111111111111171711111787111117171111111111111111111111111111111
11111111111111111111111111111117111111111111111117111111111111111111111111111171111111111111111171111111111111111111111111111111
11111111111111111111111111111117777777777777777777111111111111111111111111111177777777777777777771111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111177717771777117711771777177711111177777111111111111117771777177711771177111111777771111111111111111111111111
11111111111111111111171717171711171117111711171711111771117711111111111117171717171117111711111117717177111111111111111111111111
11111111111111111111177717711771177717771771177111111771777711111111111117771771177117771777111117771777111111111111111111111111
11111111111111111111171117171711111711171711171711111771117711111111111117111717171111171117111117717177111111111111111111111111
11111111111111111111171117171777177117711777171711111177777111111111111117111717177717711771111111777771111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__map__
5051525300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6061626300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7071727300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400200c0430000000000000000c0430000000000000000c0430000000000000000c0430000000000000000c0430000000000000000c0430000000000000000c0430000000000000000c043000000000000000
01140020021000210002120020200e11002120020200e01002120020200e11002120020200e010021200211002120020200e11002120020200e01002120020200e01002120020100e110021200e010021300e010
011400002470024700247002470026740267302673026730267202671021740217302173021730217302173026740267302474024730237402373023730237302372023720237202372023720237101f7401f730
011400002174021730217302173021720217202172021710237402373023720237101f7401f7301f7201f72021740217302173021730217202172021720217202172021720217202172021720217202172021710
011800001a7401a7401a7301a7301a7201a7201a7201a710157401573015720157101574015730157201572021740217402173021730217202172021720217202172021720217202172021720217202172021710
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400000c05300050006500064000640006300063000620006200061000610006000060000600006050060000600006000060000600006000060000600006000060000600006000060000600006000060000000
010400000c05300050006500064000640006300063000620006200c04300040006400063000630006250062000610006100c0330003000630006200062000610006100c013006100061500600006050060000600
010200000201100030260110065100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010000331203312037131371303c1413c1403f1513f1503a1003a1003f1003f1003f1003f100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
01030000245463054628536345363052630526285163451624500305002450030500285003450024500305002850034500245003050024500305000c5000c5000050000500005000050000500005000050000500
010200003c6203c6150c1000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
01020000000100c611186212463100600006012400000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
01040000306000c6153c6003c62500100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
01040000306003c6153c6000c62500100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
01020000306250c6053c6003c60000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
__music__
01 41424344
02 41424444
01 01424344
01 01024344
00 01024344
00 01020344
00 01020444
00 01020344
02 01020444

