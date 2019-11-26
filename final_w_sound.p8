pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--initial variables etc

function _init()
	updates = 0
	checkx = 0
	checky = 0
	--constants

	g_friction = .95
	a_friction = .97
	gravity = 0.25

	--flags
	solid_flag = 1
	wall_flag = 2
	deadly_flag = 3
	power_flag = 4
	ice_flag = 5
	goal_flag = 7

	sounds = {
		respawn = 7,
		jump = 8,
		crumble = 9,
		death = 10,
		charge = 11,
		land = 12,
		icicle_break = 13,
		reverse_grav = 14
	}


	sprites = {
		standing = 1,
		running = 3,
		jumping = 18,
		falling = 17,
		charge = 5,
		sliding = 19,
		spawn = 32,
		sand = 77,
		cloud = 101,
		dead = 48
	}

	--global vars
	screen = "controls"

	disp_msg = false
	msg = ""
	tempstr = ""
	msg_tick = 0

	world = 1
	level = 1
	
	g_rev = false

	mapx_ofst = 0
	mapy_ofst = 0
	bnp = false
	b_time = 0
	wall_x = 0

	part_tick = 0
	jump_from = ""
	time_held = 0

 red_display = true
	yellow_display = true

	basex = 8
	basey = 104
	classes = {}

	plr = {
		--instance vars
		controllable = true,
		ticker = 0,
		x = 8,
		y = 104,
		w = 8,
		h = 8,
		dx = 0,
		dy = 0,
		weighted = true,
		is_player = true,
		max_dy = 3,
		max_dx = 4,
		sprite = sprites.standing,
		on_ground = true,
		face_r = true,
		j_left = 1,
		max_jump = 1,
		wall_jumps = 1,
		charge_j = false,
		on_wall = false,
		clr = "blue",
		respawning = true,
		gonext = false,
		grapple = false,
		grapple_tick = 0,
		grapple_x = 0,
		grapple_y = 0,
		grapple_dir = {0,0},
		g_success = false,
		has_grapple = false,
		has_charge = false,
		has_double = false,
		dead = false,
		face_up = false,
		--functions

		respawn = function()
			plr.respawning = true
			plr.controllable = false
			plr.x = basex
			plr.y = basey
			plr.dy = 0
			plr.dx = 0
			plr.face_up = false
			plr.ticker = 0
			plr.weighted = true
			g_rev = false
			on_map = {}
			start_room()
			sfx(sounds.respawn)
		end,

		die = function()
			sfx(sounds.death)
			plr.dead = true
			plr.ticker = 30
			plr.controllable = false
			plr.weighted = false
			plr.dx = 0
			plr.dy = 0
		end,

		update = function()
			if plr.has_double then
				plr.max_jump = 2
			end
			if not g_rev and plr.y+plr.h > 128 then
				plr.respawn()
			end
			if g_rev and plr.y < 0 then
				plr.respawn()
			end
			if plr.controllable then
				
				btn_vector = {0,0,0,0}
				if btn(0) then
					btn_vector[1] = 1
					if jump_from == "right" then
						plr.wall_jumps = 1
					end
					if btn(5) then
						plr.dx-=.25
					end
					plr.dx-=.25
				end
				if btn(1) then
					btn_vector[2] = 1
					if jump_from == "left" then
						plr.wall_jumps = 1
					end
					if btn(5) then
						plr.dx+=.25
					end
					plr.dx +=.25
				end
				--btn 2 is the up arrow
				if btn(2) then
					local mod = 1
					if g_rev then
						mod = -1
					end
				
					btn_vector[3] = 1
					if plr.j_left > 0 and not bnp then
						plr.on_wall = false
						plr.dy=-1.5 * mod
						plr.on_ground = false
						plr.j_left -=1
						bnp = true
						sfx(sounds.jump)
					elseif bnp and b_time < 6 then
						b_time +=1
						plr.dy=-2 * mod
					end
				else
					bnp = false
					b_time = 0
				end
				if btn(3) and plr.has_charge then
					btn_vector[4] = 1
					time_held+=1
					if time_held > 20 then
						plr.charge_j = true
					end
				else
					local mod = 1
					if g_rev then
						mod = -1
					end
					time_held = 0
					if plr.charge_j == true then
						plr.dy = -5*mod
						plr.on_ground = false
						plr.j_left -=1
						plr.charge_j = false
					end
				end

				if btn(4) and plr.has_grapple and not plr.grapple then
					plr.grapple = true
					plr.grapple_tick = 0
					if btn_vector[1] == 1 then
						plr.grapple_dir[1] = -3
					end
					if btn_vector[2] == 1 then
						plr.grapple_dir[1] = 3
					end
					if btn_vector[3] == 1 then
						plr.grapple_dir[2] = -3
					end
					if btn_vector[4] == 1 then
						plr.grapple_dir[2] = 3
					end

					if plr.grapple_dir[1] == 0 and plr.grapple_dir[2] == 0 then
						plr.grapple_dir[2] = -3
						plr.grapple_dir[1] = 3 * sgn(plr.dx)
					end


					if plr.grapple_dir[1] ~= 0 and plr.grapple_dir[2]~= 0 then
						plr.grapple_dir[1] = plr.grapple_dir[1]/2
						plr.grapple_dir[2] = plr.grapple_dir[2]/2
					end
				end

				if plr.grapple and plr.has_grapple then
					plr.grapple_tick +=1
					plr.grapple_x = plr.x + (plr.grapple_dir[1]*plr.grapple_tick)
					plr.grapple_y = plr.y + (plr.grapple_dir[2]*plr.grapple_tick)
					if plr.grapple_x < 0 or plr.grapple_x > 128 or plr.grapple_y < 0 or plr.grapple_y > 128 then
						plr.grapple = false
					else
						if solid_collision(plr.grapple_x+(level-1)*128,plr.grapple_y+(world-1)*128) then
							plr.j_left += 1
							plr.g_success = true
							plr.weighted = false
							plr.grapple = false
						elseif plr.grapple_tick > 30 then
							grapple_tick = 0
							plr.grapple = false
							plr.g_success = false
							plr.grapple_dir = {0,0}
						end
					end
				end

				if plr.g_success then
					plr.dx = plr.grapple_dir[1]
					plr.dy = plr.grapple_dir[2]
					plr.weighted = false
				end


				physics_update()


			end
			move(plr)
			plr.spr_update()
		end,
		spr_update = function()
			plr.ticker += 0.5

			if plr.dx < 0 then
				plr.face_r = true
			elseif plr.dx > 0 then
				plr.face_r = false
			end

			if plr.dead then
				plr.ticker-=2
				if plr.ticker >=20 then
					plr.sprite = sprites.dead
				elseif plr.ticker >=10 then
					plr.sprite = sprites.dead + 1
				elseif plr.ticker >= 0 then
					plr.sprite = sprites.dead+2
				else
					plr.dead = false
					plr.respawn()
				end
			elseif plr.gonext then
				if plr.ticker >= 30 then
					if plr.ticker % 10 == 0 then
						plr.dy = -2
					end
				else
					plr.sprite = sprites.running
					plr.face_r = false
					plr.x+=1
					if plr.x > 128 then
						plr.gonext = false
						next_level()
					end
				end
				plr.ticker-=1

			elseif plr.respawning then
				plr.controllable = false
				plr.sprite = sprites.spawn
				local change = flr(plr.ticker/3)
				plr.sprite += change
				if plr.ticker > 10 then
					plr.respawning = false
					plr.controllable = true
				end
			elseif plr.on_wall then
				plr.sprite = sprites.sliding-- + modifier
			elseif not plr.on_ground and not plr.on_wall then
				if abs(plr.dx) > 0 and plr.dy < -.5 then
					plr.sprite = sprites.jumping-- + --modifier
				else
					plr.sprite = sprites.falling-- + --modifier
				end
			else

				if abs(plr.dx) > 0 then
					plr.sprite = sprites.running-- + modifier
				else
					if plr.charge_j then
						if plr.ticker %5 > 2 then
							plr.sprite = sprites.charge
						else
							plr.sprite = sprites.standing-- + modifier
						end
					else
						plr.sprite = sprites.standing-- + modifier
					end
				end

				if plr.ticker > 10 then
					if plr.ticker < 20 then
						plr.sprite += 1
					else
						plr.ticker = 0
					end
				end

			end
		end,
		draw = function()
			if plr.grapple then
		 	line(plr.x+4,plr.y+4, plr.grapple_x, plr.grapple_y+4, 12)
			end
			if plr.clr == "red" then
			 pal(12,14)
			elseif plr.clr == "yellow" then
			 pal(12,10)
			end
			spr(plr.sprite,plr.x,plr.y,1,1,plr.face_r,plr.face_up)
   pal()

		end
		}

		create_classes()
		parts = {}
		clouds = {}
		on_map={}

		for c = 0,40 do
			parts[c] = make_snow()
		end

		for z = 1,7 do
			clouds[z] = make_cloud()
		end
end





-->8
--draw and update

function _draw()
	--rectfill(0,0,128,128,0)

	if screen == "controls" then
		cls()
		rectfill(0,0,128,128,0)
		print("use the arrow keys to move/jump",0,10,7)
		print("hold up arrow for a longer jump",0,30,7)
		print("tap for a shorter jump",0,40,7)
		print("use the x key to sprint",0,60,7)
		print("you'll discover new powers throughout the game!",0,80,7)
		print("press x to continue to the game",0,90,7)
		--print("press x to continue to the game",0,110,7)
	else

		cls()

		--palt(0,false)

		rectfill(0,0,128,128,1)

		if world == 1 then
			foreach(clouds,function(cloud)
				spr(sprites.cloud,cloud.x,cloud.y,2,1)
			end)
		end

		map((level-1)*16,(world-1)*16,0,0,16,16,1)

		if plr.clr == "red" then
			pal(12,14)
		end
		--spr(plr.sprite,plr.x,plr.y,1,1,plr.face_r)
		plr.draw()
		pal()
		--draw every object on the map
		foreach(on_map,function(obj)
			if obj.type.draw ~= nil then
				obj.type.draw(obj)
			end
		end)
		--draw snow/sand
		if world == 2 or world == 3 then
			local clr = 7
			if world == 3 then
				clr = 9
			end
			for i = 1,#parts do
				local temp = parts[i]
				rectfill(temp.x,temp.y,temp.x+0.5,temp.y+0.5,clr)
			end
		end

		if disp_msg then
			--palt(0,false)
			rectfill(8,90,120,120,0)
			print(tempstr,16,95,7)
		end

		--uncomment to debug

		--print("wall_jumps: "..plr.wall_jumps,10,10,7)
		print(checkx,16,16,8)
		--print(#on_map,20,20,5)
		--print(wall_x,30,30,5)
	end
end

function _update()

	if screen == "controls" then
		if btn(5) then
			screen = "game"
			music(0)
		end
	elseif disp_msg then
		msg_tick+=1
		checkx = msg_tick
		if msg_tick <= #msg then
			tempstr = tempstr..sub(msg,msg_tick,msg_tick)
		elseif msg_tick > #msg + 60 then
			disp_msg = false
			plr.controllable = true
			plr.weighted = true
			msg_tick = 0
		end
	else
		if world == 3 and level == 3 then
			display_message("you win!!! (for now)")
		end

		plr.update()

		--call the update function
		--for any object on the map
		foreach(on_map,function(obj)
			move(obj)
			if obj.plat_solid then
				checkx = obj.x..","..obj.y
			end
			if obj.type.update ~= nil then
				obj.type.update(obj)
			--	checkx = "updating "..obj.type.tile
			end
		end)



		if not plr.gonext and fget(mget((plr.x+(level-1)*128)/8,(plr.y+(world-1)*128)/8),goal_flag) then
			plr.gonext = true
			plr.controllable = false
			plr.ticker = 59
			plr.dx = 0
			plr.dy = 0
		end


		physics_update()
		part_tick +=1
		particle_update()
		clouds_update()
	end
end
-->8
--collision checking and physics
function move(obj)
	startx = obj.x
	starty = obj.y
	local x_ofst = -1
	local y_ofst = 0

	local realx = obj.x + (level-1)*128
	local realy = obj.y + (world-1)*128

	local mod = 1
	if g_rev then
		mod = -1
	end
	
	--attempt to change dy
	if obj.weighted then
		obj.dy+=gravity * mod
		if plr.clr == "yellow" then
			printh("yo")
   obj.dy-=.10
		end
	end

	if obj.dx == 0 and obj.dy == 0 then
		return
	end

	--attempt to move in x direction
	obj.x += obj.dx

	if not plr.gonext then
		if obj.x + obj.w > 128 then
			obj.x = 128-obj.w
			obj.dx = 0
		end
		if obj.x < 0 then
			obj.x = 0
			obj.dx = 0
		end
	end

	if obj.dx > 0 then
		x_ofst = obj.w
	end

	--get the object at center y, x + offset
	local obj_at = mget((realx+x_ofst)/8,(realy+4)/8)


	--if they touch a paint bucket
	--change color and stats


	--if theres an object where this would move us
	--go back to where we started in terms of x
	if solid_collision(realx+x_ofst,realy+4) then

		if obj.is_player and obj.g_success then
			obj.g_success = false
			obj.grapple_dir = {0,0}
			obj.grapple_tick = 0
			obj.weighted = true
		end

		if obj.dx > 0 then
			jump_from = "right"
			obj.x = flr((obj.x)/8)*8
		elseif obj.dx < 0 then
			jump_from = "left"
			obj.x = flr((obj.x+8)/8)*8
		end

		obj.dx = 0
		if obj.weighted then
			--this is bad but we'll try it
			if obj.is_player then
				if not obj.on_ground then
					if fget(obj_at,wall_flag) then
						obj.on_wall = true
						wall_x = obj.x
						if obj.wall_jumps > 0 then
							obj.j_left += 1
							obj.wall_jumps -=1
						end
					else
						obj.on_wall = false
					end
				end
			end
		end
	end

	obj.y += obj.dy

	realy = obj.y + (world-1)*128

	if obj.dy > 0 then
		y_ofst = 7
	end

	--get object at where we'd fall to, center of player
	--obj_at = mget((plr.x+4+(level-1)*128)/8,(plr.y+y_ofst)/8)

 if solid_collision(realx+4,realy+y_ofst) then
	--if fget(obj_at,0) then
		--gets the top of the object that we're hitting

		local tempob = get_obj_at(realx+4-(level-1)*128,realy+y_ofst-(world-1)*128)

		if obj.is_player and obj.g_success then
			obj.g_success = false
			obj.grapple_dir = {0,0}
			obj.grapple_tick = 0
			obj.weighted = true
		end

		--if we were moving down
		if obj.dy > 0 then
			obj.y = flr(obj.y/8)*8


			--stops our movement
			obj.dy = 0
			--we're on the ground
			if obj.weighted then
				if obj.is_player then
					if not obj.on_ground then
						obj.on_ground = true
						sfx(sounds.land)
					end
					if obj.j_left < obj.max_jump then
						obj.j_left = obj.max_jump
						obj.wall_jumps = 1
					end
				end
			end
		end

		if obj.dy < 0 then
			--lets us use platforms appropriately while
			--in negative gravity
			if tempob ~= nil and g_rev then
				obj.y = tempob.y+tempob.h
				obj.dy = 0
				obj.on_ground = true
				if obj.j_left < obj.max_jump then
					obj.j_left = obj.max_jump
					obj.wall_jumps = 1
				end
			else
				obj.y = flr((obj.y+8)/8)*8
				obj.dy = 0
				if g_rev then
					obj.on_ground = true
					if obj.j_left < obj.max_jump then
						obj.j_left = obj.max_jump
						obj.wall_jumps = 1
					end
				end
			end
		end

	end

	--now we've finished moving,
	--check for other stuff


 --if player touches deadly object such as spikes
	--die and restart the level

	if obj.is_player then
		if deadly_collision(realx+1,realy) or deadly_collision(realx+6,realy) or deadly_collision(realx+1,realy+7) or deadly_collision(realx+6,realy+7) then
			plr.die()
				--plr.respawn()
				--destroy enemy
				-- not sure if this will be
				--implemented
		elseif flag_collision(realx+x_ofst,realy+y_ofst, power_flag) then
			gain_power(realx+x_ofst,realy+y_ofst, obj_at)
		end
	end

end


function gain_power(nx,ny,spr)
	if spr == 116 then
		mset(nx/8,ny/8,0)
		if world == 1 then
			plr.has_charge = true
			display_message("you can now charge jump!\ntry it by holding ⬇️")
		elseif world == 2 then
			plr.has_grapple = true
			display_message("you can now grapple!\ntry it by pressing z.")
		elseif world == 3 then
			display_message("you can now double jump!")
			plr.has_double = true
		end
	--wip, need to decide what paint powers will be
	elseif spr == 85 then
		if red_display then
			display_message("red paint increases \nfriction for precise jumps!")
			red_display = false
		end
		plr.clr = "red"
		g_friction = .85
	elseif spr == 86 then
		plr.clr = "blue"
		g_friction = .95
	elseif spr == 87 then
		if yellow_display then
			display_message("yellow paint lowers \ngravity!")
			yellow_display = false
		end
		plr.clr = "yellow"
		g_friction = .95
	end
end

function deadly_collision(nx,ny)

	if plr.dy <= 0 then
		y_mod = 3
	end
 return flag_collision(nx,ny,deadly_flag) or deadly_obj_at((nx)-(level-1)*128,(ny)-(world-1)*128)
end

function solid_collision(nx,ny)
	return flag_collision(nx,ny,solid_flag) or solid_obj_at(nx-(level-1)*128,ny-(world-1)*128)
end

function flag_collision(nx,ny,flag)
	
	local x_mod = 0
 local y_mod = 0
 
 --give forgiveness with collisions
 if flag == deadly_flag then
  if plr.dx > 0 then
  	local x_mod = -3
  else
  	local x_mod = 3
  end
  if plr.dy >= 0 then
  	local y_mod = -3
  else
  	local y_mod = 3
  end
 end
	
	local obj_at = mget((nx+x_mod)/8,ny/8)
	if fget(obj_at,flag) then
		return true
	end
end

function deadly_obj_at(nx,ny)
	--checkx = "checking x:"..nx.."y:"..ny

	local tempobj = get_obj_at(nx,ny)
	if tempobj~= nil then
		if tempobj.deadly then
			return true
		end
	end
	return false
end

function solid_obj_at(nx,ny,dy)
	local tempobj = get_obj_at(nx,ny)

	if tempobj ~= nil then
		if tempobj.solid then
			return true
		end
	end

	return false
end

function get_obj_at(nx,ny)
	local tempobj = nil
	foreach(on_map,function(obj)

		--give a little lenience
		local leftx = obj.x
		local rightx = obj.x+obj.w
		local upy = obj.y
		local lowy = obj.y+obj.h

		

		if leftx <= nx and nx <= rightx then
			if upy <= ny and ny <= lowy then
				tempobj = obj
			end
		end

	end)

	return tempobj
end

function physics_update()

	--if world == 2 and flag_collision(plr.x+(level-1)*128,plr.y+(world-1)*128+3,solid_flag) then
	--	g_friction = .97
	--else
	--	g_friction = .93
	--end

	if plr.j_left > plr.max_jump then
		plr.j_left = plr.max_jump
	end

	if plr.on_wall then
		local dist = abs(plr.x - wall_x)
		if dist > 3 then
			plr.on_wall = false
			wall_x = 0
		end
	end
	
	if flag_collision(plr.x+(level-1)*128,plr.y+(world-1)*128+plr.h+2,ice_flag) then
		checkx = "on ice"
		g_friction = .98
	else
		g_friction = .93
	end

	if plr.on_ground then
		plr.on_wall = false
		plr.dx *= g_friction
	else
		plr.dx *= a_friction
	end

	if plr.on_wall and plr.dy > 0 then
		gravity = .1
	else
		gravity = .25
	end

	if abs(plr.dx) > plr.max_dx then
		if plr.dx > 0 then
			plr.dx = plr.max_dx
		else
			plr.dx = -plr.max_dx
		end
	end

	if abs(plr.dx) < 0.1 then
		plr.dx = 0
	end

end




-->8
--cosmetics
function make_snow()
	local start = flr(rnd(128))+1
	snow = {
		x = 0,
		y = start,
		starty = start,
		height = flr(rnd(13))+2,
		spd = rnd(2)+1,
		start_tick = part_tick
		}
	return snow
end

function make_cloud()
	local start = flr(rnd(42))
	cld = {
		x = 0,
		y = start,
		starty = start,
		spd = rnd(0.5),
		start_tick = part_tick
		}
	return cld
end

function clouds_update()
	for i = 1,#clouds do
		clouds[i].x+=clouds[i].spd
		if clouds[i].x > 128 then
			clouds[i] = make_cloud()
		end
	end
end

function particle_update()
	for i = 1,#parts do
		parts[i].x+=parts[i].spd
		parts[i].y = parts[i].starty + parts[i].height*sin((part_tick-parts[i].start_tick)/50)
		if parts[i].x > 128 then
			parts[i] = make_snow()
		end
	end
	if part_tick > 100 then
		part_tick = 0
	end
end

function display_message(string)
	plr.dx = 0
	plr.dy = 0
	plr.controllable = false
	disp_msg = true
	msg = string
	tempstr = ""
end

-->8
--interactive objects

function create_classes()
	break_block = {
		tile = 77,
		init = function(this)
			this.solid = true
			this.state = 0
			this.ticker = 0
			this.sprite = 77
		end,
		draw = function(this)
			if this.state ~= 2 then
				spr(this.sprite,this.x,this.y)
			end
		end,
		update = function(this)
			if this.state == 0 then
				this.solid = true
				this.sprite = 77
				if not g_rev then
					if obj_in_range(plr,this.x,this.y-1,8,1) then
						sfx(sounds.crumble)
						this.state = 1
						this.ticker = 40
					end
				else
					if obj_in_range(plr,this.x,this.y+this.h+1,8,1) then
						this.state = 1
						this.ticker = 40
						sfx(sounds.crumble)
					end
				end
			elseif this.state == 1 then
				this.sprite = 78
				if this.ticker > 0 then
					this.ticker -= 1
					if this.ticker< 20 then
						this.sprite = 79
					end
				else
					this.state = 2
					this.solid = false
					this.ticker = 100
				end
			else
				if this.ticker > 0 then
					this.ticker-=1
				else
					this.state = 0
				end
			end
		end
	}
	add(classes,break_block)

	icicle = {
		tile = 93,

		init = function(this)
			this.state = 0
			this.deadly = true
			this.sprite = 93
			this.weighted = false
			this.ticker = 0
			this.is_player = false
			this.solid = false
			this.h = 4
		end,

		draw = function(this)
			spr(this.sprite,this.x,this.y)
		end,

		update = function(this)

			local rx = this.x + (level-1)*128
			local ry = this.y + (world-1)*128

			if this.state == 0 then
				if abs(plr.x - this.x) < 10 then
					--dont want to start falling until theyre on the right level
					local result = false
					for k = 3,flr((plr.y-this.y)/4) do
						if solid_collision(rx+4,(world-1)*128+plr.y-k*4) then
							result = true
						end
					end

					if not result then

						this.state = 1
						this.sprite = 94
						this.weighted = true
						this.h = 9
					end
				end
			elseif this.state == 1 then
				if solid_collision(rx+4,ry+9 ) then
					this.sprite = 95
					this.state = 2
					this.dy = -2
					this.y -=3
					this.deadly = false
					sfx(sounds.icicle_break)
				end
			else
				if solid_collision(rx +4,ry+9 ) then
					destroy_object(this)
				end
			end

			if this.y > 128 then
				destroy_object(this)
			end
		end
		}
		add(classes,icicle)

		move_platform = {

		tile = 110,

		init = function(this)
			this.solid = true
			this.dir = sgn(rnd(2)-1)
			this.h = 4
			this.w = 16
		end,

		update = function(this)

			local rx = this.x + (level-1)*128
			local ry = this.y + (world-1)*128
			if not g_rev then
				if plr.y <= this.y-5 then
					this.solid = true
				else
					this.solid = false
				end
			else
				if plr.y > this.y+this.h-1 then
					this.solid = true
				else
					this.solid = false
				end
			end

			local xoff = -1

			if this.dir > 0 then
				xoff = 17
			end

			this.x+=this.dir
			
			local tobj = get_obj_at(this.x+xoff+this.dir,this.y)

			if solid_collision(rx+xoff+this.dir,ry) then
				this.dir*=-1
			elseif this.x+this.w > 128 or this.x < 0 then
				this.dir*=-1
			elseif tobj~=nil and tobj.plat_solid then
				this.dir*=-1
			end
			if not g_rev then
				if obj_in_range(plr,this.x+3,this.y-1,13,1) then
					g_friction = .93
					plr.x+=this.dir
				end
			else
				if obj_in_range(plr,this.x,this.y+this.h+1,16,1) then
					g_friction = .93
					plr.x+=this.dir
				end
			end


		end,

		draw = function(this)
			spr(110,this.x,this.y,2,1)
		end

		}

		add(classes,move_platform)

		elevator = {
		tile = 126,

		init = function(this)
			this.solid = true
			this.h = 8
			this.w = 16
			this.state = 0
			this.startx = this.x
			this.starty = this.y
		end,

		update = function(this)
			if obj_in_range(plr,this.x,this.y-1,16,1) then
				this.state = 1
			else
				this.state = 0
			end

			--if players on top
			if this.state == 1 then
				if abs(this.y - this.starty) < 20 then
					plr.weighted = false
					this.y-=1
					plr.y-=1
					plr.on_ground = true
					plr.j_left = plr.max_jump
				end
			else
				if this.y ~= this.starty then
					this.y+=1
					plr.weighted = true
				end
			end
		end,

		draw = function(this)
			if this.state == 1 then
				pal(8,11)
			end
			spr(126,this.x,this.y,2,1)
			pal()
		end
	}
		add(classes,elevator)

	grav_shift = {
		tile = 103,
		init = function(this)
			this.solid = false
			this.h = 16
			this.w = 16
			this.ticker = 0
			this.s_tick = 0
		end,
		draw = function(this)
			if this.ticker > 0 then
				palt(1,true)
				palt(3,true)
				palt(11,true)
			else
				this.s_tick += 1
				if this.s_tick > 20 then
					pal(11,3)
				end
				if this.s_tick > 40 then
					this.s_tick = 0
				end
			end
			spr(103,this.x,this.y,2,2)
			pal()
		end,
		update = function(this)
			if this.ticker > 0 then
				this.ticker -= 1
			end
			if this.ticker <= 0 and obj_in_range(plr,this.x+4,this.y+4,8,8) then
				this.ticker = 150
				sfx(sounds.reverse_grav)
				if g_rev then
					g_rev = false
				else
					g_rev = true
				end
				if plr.face_up then
					plr.face_up = false
				else
					plr.face_up = true
				end
			end
		end
		}
		
		add(classes,grav_shift)
		
		plat_blocker = {
			tile = 115,
			init = function(this)
				this.w = 8
				this.h = 8
				this.solid = false
				this.plat_solid = true
			end
		}
		add(classes,plat_blocker)
end

function create(x,y,class)
	obj = {}
	obj.type = class
	obj.x = x
	obj.y = y
	obj.w = 8
	obj.h = 8
	obj.dx = 0
	obj.dy = 0
	obj.solid = true

	add(on_map,obj)
	if obj.type.init ~= nil then
		obj.type.init(obj)
	end
	return obj
end

function destroy_object(this)
	del(on_map,this)
end

function obj_in_range(obj,x,y,w,h)

	--have to implement height

	local leftx = obj.x
	local rightx = obj.x+obj.w
	local upy = obj.y
	local lowy = obj.y+obj.h

	for cx = x,x+w-1 do
		if leftx <= cx and cx <= rightx then
			if upy <= y and y <= lowy then
				return true
			end
		end
	end
end
-->8
--misc functions

function start_room()
	for i = 0,15 do
		for j = 0,15 do
			local temp_tile = mget(i+(level-1)*16,j+(world-1)*16)
			for k = 1,#classes do
				local typ = classes[k]
				if typ.tile == temp_tile then
					create(i*8,j*8,typ)
				end
			end
		end
	end
end

function next_level()
	on_map = {}
	level+=1
	if world == 1 and level > 4 then
		level = 1
		world+=1
		music(3)
	elseif world == 2 and level > 2 then
		level = 1
		world+=1
		music(5)
	end

	start_room()
	plr.respawn()
end
__gfx__
00000000000000000000000000000000c0000000000000000000000000000000000000009a999a99000000000000000000000000000000007772277777722777
00000000000cc000000000000000ccc000c00000000770000000000000000000000000009aa99aa9000000000000000000000000000000007722227777222277
0070070000cccc00000cc000000cccccc000ccc0007777000007700000000000000000009a999999000000000000000000000000000000007700a077770a0077
000770000cccccc000cccc0000cc8ccc000ccccc07777770007777000000000000000000aa999999000000000000000000000000000000002222222222222222
00077000cc8cc8cc0cccccc00ccccc8c00cc8ccc77877877077777700000000000000000999aa9aa000000000000000000000000000000007330303773030337
00700700cccccccccc8cc8cc0ccccccc0ccccc8c777777777787787700000000000000009999aaaa000000000000000000000000000000007333033773303337
000000000cccccc0cccccccc0cccccc00ccccccc07777770777777770000000000000000aa999999000000000000000000000000000000007333333773333337
0000000000cccc000cccccc000cccc0000ccccc000777700077777700000000000000000a99999aa000000000000000000000000000000007330003773000337
000000000000cc00000000000000000c00000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000cc000000cc00000000cc0000cccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000cccc0000cccc00000008c000cc8cc00000000000cc000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000cccc000c8c8c000000ccc00cccccc000cc00000cccc00000000000000000000000000000000000000000000000000000000000000000000000000
0000000000c8cc8c0cccccc000000ccc00cccccc00cccc000c8cc8c0000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cccccc0ccccc000000008c000cc8cc00cccc000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000
00000000000cccc0ccccc000000000cc0000cccc0000000000cccc00000000000000000000000000000000000000000000000000000000000000000000000000
00000000000cccc0cccc00000000000c00000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000cc00000cccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000cc00000cccc000c8cc8c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000cc00000cccc000cccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000cccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000c00000000c00000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000cc0000c0c0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cc0cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0cc8ccc0c0c0c0000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc80cc0c000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c0cc000c00c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c0cc000000c0c00000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444b33bbb3bb333bb3399999999a00aa00aaaaaaaaa999999990088800005b3000043344444b55544440000000000000000444444449a099a9900000000
400000043bb33b3b3bbb333b9aaaaaa990099009aaaaaaaa9999999908888000005b30004b344444bb35544400000000000000004aa99aa49a009aa900000a00
40444404b3b3b3b3333b33b39aaaaaa99999999999aaaa999999999988a880000535b30043b444444bb3554400000000000000004a9999949a90990000009900
4040040444444444b333b3339aa99aa999999999aaaaaaaa999999998888800003bb300035444444444b334400000000000000004a999994aa90000900000009
4040040445455544bb3333b39aa99aa999999999aaaaaaaa999999990008800005b3000043b44444444b34440000000000000000499aa9a4999aa0aa099aa0a0
404444044444454433bbbbb39aaaaaa99999999999aaaa99999999990008800005b30000445b4444bbbb344400000000000000004999aaa49990000a09900000
4000000444544545b33333339aaaaaa999999999aaaaaaaa99999999000880005b30000043b34443355b344400000000000000004a999994a000990900000000
44444444444444443b3bb3bb9999999999999999aaaaaaaa9999999900088000b30000003334444b33353355000000000000000044444444a099990a00090000
444444440000000000000000000000000006600000000000000000000000000053bb00003bb44bbb4435bb35000000000000000006cccc600000000000000000
4444444400000000000000000000000000066000005555500055555000555550553b000033b4bb4444435b33000000000000000006cccc600000000000000000
44444444000000000000000000000000006556000588888505ccccc505aaaaa5053bb00055333bbb44433bb30000000000000000006cc60006cccc6000006000
444444440000000000000000000000000065560005588855055ccc55055aaa550553b0004555533bb444b4bb0000000000000000006cc60006cccc600006c600
44444444000000000000000000000000006556000055555000555550005555500053bb0044445553b4bb34440000000000000000000cc000006cc6000006cc60
444444440000000000000000000000000655556000555550005555500055555000553b0044444453bb333444000000000000000000066000006cc600006cccc6
44444444000000003333333300000000065555600005550000055500000555000053bb004444443344444444000000000000000000000000000cc000006cc660
4444444400000033333333333300000056555565000000000000000000000000053bb00044444433b44444440000000000000000000000000006600000666000
0b0b0b0b0000333333333333333300005655556500000077770000000000088888800000777777777777777777777777ccccccccccccccc70aaaaaaaaaaaaaa0
b3b3b3b300033333333333333333300006555560000007777770000000008eeeeee80000777cccccccccc777777cc777ccccccccccccccc7aaaaaaaaaaaaaaaa
333333330033333333333333333333000065560000070777777070000008ebbbbbbe800077cc77ccccc7cc7777cccc77ccccccccccccccc7aaaaaaaaaaaaaaaa
b3b3b3b3033333333333333333333330006556000077777777777700008ebbbbbbbbe8007ccc77ccccccccc77cccccc7ccccccccccccccc70aaaaaaaaaaaaaa0
bbbbbbbb03333333333333333333333000655600077777777777777008ebbbbbbbbbbe807cccccccccccccc77cccccc7ccccccccccccccc70000000000000000
05b300000033333333333333333333000006600077777777777777778ebbb111111bbbe87ccccccccc77ccc777cccc77ccccccccccccccc70000000000000000
005b30000003333333333333333330000006600007777777777777708ebbb1bbbbbbbbe87ccc7ccccc77ccc7777cc777ccccccccccccccc70000000000000000
0535b3000000333333333333333300000006600000777777777777008ebbb1bbbbbbbbe87cccccccccccccc77777777777777777ccccccc70000000000000000
0b0b0b0b0000000000000000777777770000000066600000000006668ebbb1bb111bbbe87cccccccccccccc777777777cccccccc7ccccccc0555555555555550
b3b3b3b300000000000000007788887700aaaa0055560000000065558ebbb1bbbb1bbbe87cccc77ccccc7cc7cccccccccccccccc7ccccccc5888888888888885
333333330000000000000000778777770aaaaaa055566660066665558ebbb111111bbbe87cccc77cccccccc7cccccccccccccccc7ccccccc5888888888888885
b3b3b3b30000000000000000778877770aaaaaa0555555566555555508ebbbbbbbbbbe807cc7ccccc77cccc7cccccccccccccccc7ccccccc0555555555555550
bbbbbbbb00000000000000007778887700aaaa005555555665555555008ebbbbbbbbe8007cccccccc77cccc7cccccccccccccccc7ccccccc0000000000000000
00000000000000000000000077777877000aa00055566660066665550008ebbbbbbe800077cccccccccccc77cccccccccccccccc7ccccccc0000000000000000
0000000000000000000000007788887700066000555600000000655500008eeeeee80000777cccccccccc777cccccccccccccccc7ccccccc0000000000000000
0000000000000000000000007777777700000000666000000000066600000888888000007777777777777777cccccccccccccccc7ccccccc0000000000000000
00000000000000000000000000000000000000000000000000000090000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000090000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000090000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000007400000000000000000000000090000074000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000d43434543400000000000000d4d400000090900000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000d4d43434345400000000000000d4d4d4d40000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000d4d40000343454340000d4d4d40000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000d4d40000000000003434345400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000d4d4000000003434543400000000000000d4d4d4000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000d4d400003434345400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000003434543400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000d4d40034340000000000000000000000000000e7000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d4d4d4d4d4d4d4d400000000343400000000e600000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000453434650055004545454545454545454545450000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90909090909090909090909090909090909090909090909090909090909090900000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
64646464646464646464646464646464646464646464646464646464646464640000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003030707030707810107070101000000030101010911111101070701010000000301010109000000000707270707000003000000110909000007070707070000
0000000000000000000707070700000000000000000000000007070707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000000000000000000000000000004a000000000000000000420000000000000000000000000000000000000000000000000000000000000000000000000042424242424242424242000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000005a000000000000000000420000000000000000000000000000000000000000000000000000000000000000000000000042424242424242424242000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
525253000000000000000000000000004a000000000000000000420000004700000000000000000000000000000000000000000000000000000000000000000042424242424242424242000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
626263000000000000000000000047005a000000000000000000420000764242000000000000000054000000000000470000000000000000000000000000000000000000640000006464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
494a000000000000000000000000494a4a0000004242424200004200000042424a0000424200004242424200004242420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
595a000000000000000000000000595a5a000000595a000000004200000042425a000000000000000000000000000000000054000042424242424242000000490000004200006e000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
494a000000000000000000004242494a4a000000494a000000004200000042424a0000000000000000000000000000000000420000480000000000000000005900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
595a00000042000042424242595a595a5a000000595a000000004200000042425a4242000000000000000000000000000000480000540000000000000000004900000000000000000000000000470000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
494a000000480000580000000000494a4a000000494a000000004200000042424a00000000000000000000000000515200005800004200006e00000000000059007e0000420000004200000000494a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
595a000000580000480000000000595a5a000000595a000000004200000042425a000000006e000000730000000061620000540000580000000000005454544900000042420000000000000000595a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
494a000000480000580000000000494a4a000000494a00000000420000004242000000000000000000005400000000490000420000480000424200007070705900000000000000000000000000494a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
595a424242424242424242000000595a5a000000595a00000000427500004242000000000000000042424242420000590000480000540000000000000000004900000000000000000000000000595a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000048000000480000000000494a4a000000494a000000000000000042420000000000000000480000004800004900005800004200000000006e0000005900000000000000000000000000494a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000058000000580000000000595a5a000000595a00000000000000004242000000000000000058000000585700590056480000580000000000000000000000000000000000000000000000595a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4242424242424242424242424242424242424242424242424242424242424242424242000000004242420000484242424242420000480000000000000074470000000000000000000000007e00494a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
414141414141414141414141414141414141414141414141414141414141414141414100000000414141000058414141414100000058000000000000007070494141415454736e000000000000595a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c6d000000000000000000000000000047000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7c7c7c6c6c6c6c6c6c6c6c6c6c6c6c6c6d00000000000000000000000000006b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7c7c6d5d5d00005d5d00005d5d0000006d00740000000000000000000000007d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7c7c6d000000000000000000000000007c6c6c00006e0000545400006e00007d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6c6c7a000000000000000000000047006d5d5d0000000000696a00000000007d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000697c6d00000000000000797a00000000007d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000007d7c6d00006b6b6b6b6b6b6b6b6b6b6b6b7d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b6a0000000000000000000000796c6d0000005d005d5d00005d5d0000007d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7c7c6d00000000696a0000696a0000006d00000000000000000000000000007d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7c7c6d00000000797a0000797a0000006d6b6b0000000000000000000000007d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6c6c7a000000000000545400000000006d6b6b6b6b6b6b6b6b6b6b6b6b00007d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000697b7b7b7b7b7b6a00007a000000005d5d00000000000000007d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000697c7c7c7c7c7c7c6d00000000000000000000000000000000007d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
697b7b7b7b7c7c7c7c7c7c7c7c6d00000000000000000000000000000000007d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7c7c7c7c7c7c7c7c7c7c7c7c7c6d54547b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011000080231502315093150931505315053150c3150c315000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000001c535105151c535105151c535105151c535105151e535125151e535125151e535125151e535125151f535215352353517515235351751523535175152453523535215351551521535155152153515515
012000001f5352153523532235322353223532235322353523530235301e5311e5321e5321e5321e5321e5321f530215301f5301f5301f5301f5301f5301f5301f5321f5321f5321f5321f5321f5321f5321f532
012000101a5650e5421a5650e542185650c542185650c5421d565115421d565115421c565105421c5651054200000000000000000000000000000000000000000000000000000000000000000000000000000000
011000080000024610000002461000000000002461024600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01200010260222605226025260512402224052240252405129022290522902529051280222805228025280510c3000c30011300113000c3000c30011300113000c3000c30011300113000c3000c3001130011300
0120001021152211521c1521c1521d1521d1521f1521f1521d1521f1521d1521f15218152181521a1521a15200002000020000000000000000000000000001000010000000000000000000000000000000000000
010200001e57020570225702357025570285702b5701c5701f570225702457027570295702c5702f5703157034570365700000000000000000000000000000000000000000000000000000000000000000000000
01010000000001357015570165700c5700d5700e5701c5702057019570225702e5702b5001e5001b5001840014300123000c30007300043001e6001c600186001560012600106000000000000000000000000000
01020000066300d64005640086400d64004630096300b63012640076300a640116300863008610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000280702607023070200701c070180701307013070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010000000000a57009570095700957009570095700957009570095700957009570095700a5700b5700d5701057013570175701a5701d5701e570205701f5701f57020570215702257024570275702857000000
010800000507000070022000220002200022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002a650296502665024650226501f6501c65019650176501465014650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600002a7503275033750327502c75026750277502a7502f7502d7502775024750267502c750287502375000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 00424344
01 00014344
02 00024344
01 03044544
02 04050344
00 06424344

