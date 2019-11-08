pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--initial variables etc

function _init()

	bnp = false
	b_time = 0
	wall_x = 0

	jump_from = ""
	time_held = 0
	ticker = 0
	g_friction = .9
	a_friction = .93
	gravity = 0.25

	screen = "controls"

	world = 1
	level = 1

	mapx_ofst = 0
	mapy_ofst = 0

	sprites = {
		standing = 1,
		running = 3,
		jumping = 18,
		falling = 17,
		charge = 5,
		sliding = 19
	}

	plr = {
		x = 8,
		y = 104,
		w = 8,
		h = 8,
		dx = 0,
		dy = 0,
		max_dy = 3,
		max_dx = 4,
		sprite = sprites.standing,
		on_ground = true,
		face_r = true,
		j_left = 1,
		max_jump = 1,
		wall_jumps = 1,
		has_charge = false,
		has_grapple = true,
		grapple_dir = "right",
		grapple = false,
		charge_j = false,
		on_wall = false,
		clr = "blue"
		}
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
		print("hold in the down key to",0,80,7)
		print("do a charged up high jump!",0,90,7)
		print("press x to continue to the game",0,110,7)
	else

		cls()

		--palt(0,false)

		rectfill(0,0,128,128,1)

		map(0+mapx_ofst,0,0,0,16,16)

		spr(plr.sprite,plr.x,plr.y,1,1,plr.face_r)

		if plr.grapple then
		 rectfill(plr.x+4,plr.y+4, plr.x+grapple_tick,plr.y+5,12)
		end
		--uncomment to debug

		print("wall_jumps: "..plr.wall_jumps,10,10,7)
		--print("x:"..plr.x.." dy:"..plr.dy,16,16,7)
		--print(plr.on_wall,20,20,5)
		--print(wall_x,30,30,5)
	end
end

function _update()


	if screen == "controls" then
		if btn(5) then
			screen = "game"
		end
	else

		if fget(mget((plr.x+(level-1)*128)/8,plr.y/8),7) then
			level +=1
			plr.x = 8
			plr.y = 104
		end

		if mapx_ofst < (level-1)*16 then
			mapx_ofst +=1
		end


		if btn(0) then
			if jump_from == "right" then
				plr.wall_jumps = 1
			end
			if btn(5) then
				plr.dx-=.25
			end
			plr.dx-=.25
		end
		if btn(1) then
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
			if plr.j_left > 0 and not bnp then
				plr.on_wall = false
				plr.dy=-1.5
				plr.on_ground = false
				plr.j_left -=1
				bnp = true
			elseif bnp and b_time < 6 then
				b_time +=1
				plr.dy=-2
			end
		else
			bnp = false
			b_time = 0
		end

		if btn(3) then
			time_held+=1
			if time_held > 20 and plr.has_charge then
				plr.charge_j = true
			end
		else
			time_held = 0
			if plr.charge_j == true then
				plr.dy -=5
				plr.on_ground = false
				plr.j_left -=1
				plr.charge_j = false
			end
		end

		if btn(4) and plr.has_grapple and not plr.grapple then
			plr.grapple = true
			grapple_tick = 0
			if not plr.face_r then
				grapple_tick = 8
				plr.grapple_dir = "right"
			else
				plr.grapple_dir = "left"
			end
		end

		if plr.grapple then
			if plr.grapple_dir == "right" then
    grapple_tick += 3
			else
				grapple_tick -= 3
			end
			if fget(mget((plr.x+grapple_tick)/8,(plr.y+4)/8),0) then
				plr.x = plr.x+grapple_tick
				if plr.grapple_dir == "right" then
				 plr.x -= 8
				end
				grapple_tick = 0
				plr.grapple = false
			end
			if grapple_tick > 70 or grapple_tick < -70 then
				grapple_tick = 0
				plr.grapple = false
		 end
		end

		physics_update()
		sprite_update()
	end
end
-->8
--collision checking and physics
function move()
	startx = plr.x
	starty = plr.y
	x_ofst = 0
	y_ofst = 0

	--attempt to change dy
	plr.dy+=gravity

	plr.x += plr.dx

	if plr.x < 0 then
		plr.x = 0
	end

	if plr.dx > 0 then
		x_ofst = 7
	end

	--get the object at center y, x + offset
	local obj_at = mget((plr.x+x_ofst+(level-1)*128)/8,(plr.y+4)/8)

	--if player touches deadly object such as spikes
	--die and restart the level
	if fget(obj_at,3) then
	 _init()
	 reboot()
	end

	--if they touch a paint bucket
	--change color and stats
	if fget(obj_at,4) then
	 if obj_at == 85 then
	  plr.clr = "red"
	  g_friction = .7
	  plr.max_jump =  1
	 elseif obj_at == 86 then
	  plr.clr = "blue"
	  g_friction = .9
	  plr.max_jump =  1
 	elseif obj_at == 87 then
	  plr.clr = "yellow"
	  plr.max_jump =  2
	  g_friction = .9
	 end
	end

	--if power up
	if fget(obj_at,5) then
	 mset((plr.x+x_ofst+(level-1)*128)/8,(plr.y+4)/8,0)
		--assuming theres only 1 permanent upgrade per world,
		--this is how we'll detect which power to get
	 if world == 1 then
	   plr.has_charge = true
	 end
	end

	--if theres an object where this would move us
	--go back to where we started in terms of x
	if fget(obj_at,0) then

		if plr.dx > 0 then
			jump_from = "right"
			plr.x = flr((plr.x)/8)*8
		elseif plr.dx < 0 then
			jump_from = "left"
			plr.x = flr((plr.x+8)/8)*8
		end

		plr.dx = 0
		if not plr.on_ground then
			if fget(obj_at,1) then
				plr.on_wall = true
				wall_x = plr.x
				if plr.wall_jumps > 0 then
					plr.j_left += 1
					plr.wall_jumps -=1
				end
			else
				plr.on_wall = false
			end
		end
	end

	plr.y += plr.dy

	if plr.dy > 0 then
		y_ofst = 7
	end

	--get object at where we'd fall to, center of player
	obj_at = mget((plr.x+4+(level-1)*128)/8,(plr.y+y_ofst)/8)

	if fget(obj_at,0) then
		--gets the top of the object that we're hitting

		--if we were moving down
		if plr.dy > 0 then
			plr.y = flr(plr.y/8)*8


			--stops our movement
			plr.dy = 0
			--we're on the ground
			plr.on_ground = true
			if plr.j_left < plr.max_jump then
				plr.j_left = plr.max_jump
				plr.wall_jumps = 1
			end
		end

		if plr.dy < 0 then
			plr.y = flr((plr.y+8)/8)*8
			plr.dy = 0
		end

	end
end

function physics_update()

	if plr.j_left > plr.max_jump then
		plr.j_left = plr.max_jump
	end

	if plr.on_wall then
		local dist = abs(plr.x - wall_x)
		if dist > abs(plr.dx) then
			plr.on_wall = false
			wall_x = 0
		end
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

	move()

	if abs(plr.dx) < 0.1 then
		plr.dx = 0
	end

end



-->8
--animation functions

function sprite_update()
	ticker += 0.5

	if plr.clr == "blue" then
	 modifier = 0
	elseif plr.clr == "red" then
	 modifier = 8
	elseif plr.clr == "yellow" then
	 modifier = 32
	end

	if plr.dx < 0 then
		plr.face_r = true
	elseif plr.dx > 0 then
		plr.face_r = false
	end

	if plr.on_wall then
		plr.sprite = sprites.sliding + modifier
	elseif not plr.on_ground and not plr.on_wall then
		if abs(plr.dx) > 0 and plr.dy < -.5 then
			plr.sprite = sprites.jumping + modifier
		else
			plr.sprite = sprites.falling + modifier
		end
	else

		if abs(plr.dx) > 0 then
			plr.sprite = sprites.running + modifier
		else
			if plr.charge_j then
				if ticker %5 > 2 then
					plr.sprite = sprites.charge
				else
					plr.sprite = sprites.standing + modifier
				end
			else
				plr.sprite = sprites.standing + modifier
			end
		end

		if ticker > 10 then
			if ticker < 20 then
				plr.sprite += 1
			else
				ticker = 0
			end
		end

	end
end

__gfx__
00000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000e0000000000000007772277777722777
00000000000cc000000000000000ccc000c0000000077000000000000000000000000000000ee000000000000000eee000e00000000000007722227777222277
0070070000cccc00000cc000000cccccc000ccc00077770000077000000000000000000000eeee00000ee000000eeeeee000eee0000000007700a077770a0077
000770000cccccc000cccc0000cc8ccc000ccccc077777700077770000000000000000000eeeeee000eeee0000ee8eee000eeeee000000002222222222222222
00077000cc8cc8cc0cccccc00ccccc8c00cc8ccc77877877077777700000000000000000ee8ee8ee0eeeeee00eeeee8e00ee8eee000000007330303773030337
00700700cccccccccc8cc8cc0ccccccc0ccccc8c77777777778778770000000000000000eeeeeeeeee8ee8ee0eeeeeee0eeeee8e000000007333033773303337
000000000cccccc0cccccccc0cccccc00ccccccc077777707777777700000000000000000eeeeee0eeeeeeee0eeeeee00eeeeeee000000007333333773333337
0000000000cccc000cccccc000cccc0000ccccc00077770007777770000000000000000000eeee000eeeeee000eeee0000eeeee0000000007330003773000337
000000000000cc00000000000000000c00000cc0000000000000000000000000000000000000ee00000000000000000e00000ee0000000000000000000000000
000000000000cc000000cc00000000cc0000cccc000000000000000000000000000000000000ee000000ee00000000ee0000eeee000000000000000000000000
00000000000cccc0000cccc00000008c000cc8cc00000000000000000000000000000000000eeee0000eeee00000008e000ee8ee000000000000000000000000
00000000000cccc000c8c8c000000ccc00cccccc00000000000000000000000000000000000eeee000e8e8e000000eee00eeeeee000000000000000000000000
0000000000c8cc8c0cccccc000000ccc00cccccc0000000000000000000000000000000000e8ee8e0eeeeee000000eee00eeeeee000000000000000000000000
0000000000cccccc0ccccc000000008c000cc8cc0000000000000000000000000000000000eeeeee0eeeee000000008e000ee8ee000000000000000000000000
00000000000cccc0ccccc000000000cc0000cccc00000000000000000000000000000000000eeee0eeeee000000000ee0000eeee000000000000000000000000
00000000000cccc0cccc00000000000c00000cc000000000000000000000000000000000000eeee0eeee00000000000e00000ee0000000000000000000000000
00000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aa000000000000000aaa000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa00000aa000000aaaaaa000aaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaa000aaaa0000aa8aaa000aaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aa8aa8aa0aaaaaa00aaaaa8a00aa8aaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaaaa8aa8aa0aaaaaaa0aaaaa8a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaa0aaaaaaaa0aaaaaa00aaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa000aaaaaa000aaaa0000aaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000aa00000000000000000a00000aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000aa000000aa00000000aa0000aaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aaaa0000aaaa00000008a000aa8aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aaaa000a8a8a000000aaa00aaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a8aa8a0aaaaaa000000aaa00aaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaaaa0aaaaa000000008a000aa8aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aaaa0aaaaa000000000aa0000aaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aaaa0aaaa00000000000a00000aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444b33bbb3bb333bb33666666660000000055555555555555550088800005b3000043344444b55544440aaa000aa0000aa0000000000000000000000000
400000043bb33b3b3bbb333b6555555600000000555555555555555508888000005b30004b344444bb355444000a00aaaa00a000000000000000000000000000
40444404b3b3b3b3333b33b36555555660066006dd5555dd5555555588a880000535b30043b444444bb3554400000aaaaaa0000a000000000000000000000000
4040040444444444b333b333655665565005500555566555555555558888800003bb300035444444444b3344aa00aaaaaaaa00aa000000000000000000000000
4040040445455544bb3333b3655665565555555555566555555555550008800005b3000043b44444444b3444000aaaaaaaaaa000000000000000000000000000
404444044444454433bbbbb36555555655555555dd5555dd555555550008800005b30000445b4444bbbb344400aaaaaaaaaaaa00000000000000000000000000
4000000444544545b333333365555556555555555555555555555555000880005b30000043b34443355b34440aaaaaaaaaaaaaa0000000000000000000000000
44444444444444443b3bb3bb6666666655555555555555555555555500088000b30000003334444b33353355aaaaaaaaaaaaaaaa000000000000000000000000
444444440000000000000000000000000006000000000000000000000000000053bb00003bb44bbb4435bb35aaaaaaaaaaaaaaaa000000000000000000000000
4444444400000000000000000000000000060000005555500055555000555550553b000033b4bb4444435b330aaaaaaaaaaaaaa0000000000000000000000000
44444444000000000000000000000000006560000588888505ccccc505aaaaa5053bb00055333bbb44433bb300aaaaaaaaaaaa00000000000000000000000000
444444440000000000000000000000000065600005588855055ccc55055aaa550553b0004555533bb444b4bb000aaaaaaaaaa000000000000000000000000000
44444444000000000000000000000000006560000055555000555550005555500053bb0044445553b4bb3444aa00aaaaaaaa00aa000000000000000000000000
444444440000000000000000000000000655560000555550005555500055555000553b0044444453bb333444a0000aaaaaa00000000000000000000000000000
44444444000000003333333300000000065556000005550000055500000555000053bb004444443344444444000a00aaaa00a000000000000000000000000000
4444444400000033333333333300000006555600000000000000000000000000053bb00044444433b4444444000a000aa0000a00000000000000000000000000
0b0b0b0b000033333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b3b3b3b30003333333333333333330000000000000aaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333003333333333333333333300000000000aaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000
b3b3b3b3033333333333333333333330000000000aaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb0333333333333333333333300000000000aaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000333333333333333333330000000000000aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000333333333333333333000000000000005500000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000033333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010303800003030000000000030000000810101000030300000000000100000000200000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000004b4c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52525300000000000000005b5c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6262630000000000000000000000470000000000000000000000000000000047000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
494a000000000000000000000000494a00000000000000000000000000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
595a000000000000000000000065595a00000000000000000000000000000058000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
494a000000000000000000004242494a00000000000000000000000042000048000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
595a00000042000042000042595a595a00000000000000000000000048000058000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
494a000000480000580000000000494a00000000000000004200000058000048000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
595a000000580000480000000000595a00000057000000005800000048000058000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
494a000000480000580000000000494a00000042000000004800000058000048000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
595a424242424242424242000000595a00000048000000005800000048000058000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000048000000480000000000494a00000058000000004800000058000048000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000058000000580000000000595a56000048000055005854545448545458000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4242424242424242424242424242424242424242424242424242424242424242000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141414141414141414141414141414141414141414141414141414141414141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
