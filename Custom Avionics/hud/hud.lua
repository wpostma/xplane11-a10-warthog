-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Head Up Display for A-10 Warthog
-- Version: 2016.02.02
--
-- History:
-- 2016.02.02 - Initial version (Fabrice Kauffmann)
-- 2016,02.14 - Added "PULL UP" warning, removed VV bal from gun mode
-- This script requires sasl-plugin-1.0.0-rc2 or greater
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
size = { 2048, 2048 }

-- fonts
local fontSmall  = loadFont('Console12.fnt')
local fontMedium = loadFont('Console14.fnt')
local fontLarge  = loadFont('Console16.fnt')
local fontHuge   = loadFont('Console18.fnt')


-- datarefs
defineProperty("ias",		 globalPropertyf("sim/flightmodel/position/indicated_airspeed"))
defineProperty("mag_hdg",    globalPropertyf("sim/cockpit2/gauges/indicators/heading_AHARS_deg_mag_pilot"))
defineProperty("altitude",   globalPropertyf("sim/cockpit2/gauges/indicators/altitude_ft_pilot"))
defineProperty("rdr_alt",    globalPropertyf("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot"))
defineProperty("theta", 	 globalPropertyf("sim/flightmodel/position/theta"))
defineProperty("roll",       globalPropertyf("sim/cockpit2/gauges/indicators/roll_AHARS_deg_pilot"))
defineProperty("aoa",        globalPropertyf("sim/flightmodel2/misc/AoA_angle_degrees"))--read only
defineProperty("beta",  	 globalPropertyf("sim/flightmodel/position/beta"))-- yaw path
defineProperty("vvi",        globalPropertyf("sim/cockpit2/gauges/indicators/vvi_fpm_pilot"))
defineProperty("g_force",    globalPropertyf("sim/flightmodel2/misc/gforce_normal"))
defineProperty("mach",       globalPropertyf("sim/flightmodel/misc/machno"))
defineProperty("wind_dir",   globalPropertyf("sim/cockpit2/gauges/indicators/wind_heading_deg_mag"))
defineProperty("wind_spd",   globalPropertyf("sim/cockpit2/gauges/indicators/wind_speed_kts"))
defineProperty("gear_handle",globalPropertyi("sim/cockpit2/controls/gear_handle_down"))
defineProperty("spd_brk",    globalPropertyf("sim/cockpit2/controls/speedbrake_ratio"))
defineProperty("prk_brk",    globalPropertyf("sim/cockpit2/controls/parking_brake_ratio"))
--defineProperty("burn",       globalPropertyi("sim/cockpit/warnings/annunciators/afterburners_on"))
defineProperty("guns_armed", globalPropertyi("sim/cockpit/weapons/guns_armed"))
defineProperty("miss_armed", globalPropertyi("sim/cockpit/weapons/missiles_armed"))
defineProperty("bomb_armed", globalPropertyi("sim/cockpit/weapons/bombs_armed"))
defineProperty("brightness", globalPropertyf("sim/cockpit2/electrical/HUD_brightness_ratio"))
defineProperty("hud_on",     globalPropertyi("sim/cockpit2/switches/HUD_on"))
defineProperty("wep_sel",    globalPropertyi("sim/cockpit2/weapons/weapon_select_console_index"))


-- texts
local txtMaghdg;
local txtIas;
local txtAltitude;
local txtVVI;
local txtG;
local txtMag;
local txtRadAlt;
local txtG;

-- constants
local offsetX = 516;
local offsetY = -50;
local width = 300;
local height = 380;
local increment = 100;

local centerX = offsetX + (width/2);
local centerY = offsetY + (height/2);

local red = 0;
local green = 1;
local blue = 0;
local alpha = 1;

-- local vars
local direction = 0;
local gps_dir = 0;

local weapon=0
set(guns_armed,0)
set(bomb_armed,0)
set(miss_armed,0)
set(wep_sel,26)

-- panel components
components = {
}

--Draw a 2d circle
function drawCircle(x, y, radius)
	local twopi = 2 * math.pi;
	local step = 0.0436;
	
	for a = 0, twopi, step do 
		drawLine(x + radius * math.cos(a), y + radius * math.sin(a), 
			x + radius * math.cos(a-step), y + radius * math.sin(a-step), red, green, blue, alpha);
	end 
end

--Draw a 2d rectangle
function drawRectangle(x, y, width, height) 
	drawLine(x, y, x+width, y, red, green, blue, alpha);
	drawLine(x, y-height, x+width, y-height, red, green, blue, alpha);
	drawLine(x, y, x, y-height-1, red, green, blue, alpha);
	drawLine(x+width, y, x+width, y-height, red, green, blue, alpha);	
end

--Rotate artificial horizon line centred on cx, cy by angleDeg degrees
function rotateLine(x1, y1, x2, y2, cx, cy, angleDeg) 
	local the = angleDeg * math.pi/180.0 
	local s = math.sin(the)
	local c = math.cos(the)
	
	x1 = x1 - cx
	y1 = y1 - cy
	
	local newx1 = x1 * c - y1 * s
	local newy1 = x1 * s + y1 * c
	
	x1 = newx1 + cx
	y1 = newy1 + cy
	
	x2 = x2 - cx
	y2 = y2 - cy
	
	local newx2 = x2 * c - y2 * s
	local newy2 = x2 * s + y2 * c
	
	x2 = newx2 + cx
	y2 = newy2 + cy	
	
	drawLine(x1, y1, x2, y2, red, green, blue, alpha)--draw artificial horizon & pitch ladder lines
end

--Rotate a text (pitch ladder degrees) on cx, cy by angleDeg degrees
function rotateText(text, x1, y1, cx, cy, angleDeg) 
	local the = angleDeg * math.pi/180.0 
	local s = math.sin(the)
	local c = math.cos(the)
	
	x1 = x1 - cx
	y1 = y1 - cy
	
	local newx1 = x1 * c - y1 * s
	local newy1 = x1 * s + y1 * c
	
	x1 = newx1 + cx
	y1 = newy1 + cy
	
	drawText(fontSmall, x1, y1, text, red, green, blue, alpha)--draw pitch ladder degree numbers
end


function update()
	--Heading info
	local mh = get(mag_hdg);

	--HUD luminosity
	local level = get(brightness);
	
	if (level>1) then
		level = 1
	end
	
	red=level/3;
	green=level;
	blue=0;
	
	txtMagHdg   = string.format("%03d", mh)--fixed forward view
	txtIas 		= string.format("%3d",  get(ias))
	txtAltitude = string.format("%5d",get(altitude))
	txtVVI      = string.format("%6d",get(vvi))
	txtG        = "G " .. string.format("%1.1f",get(g_force))


	-- Only one weapon can be armed at a time
	-- Select weapons up/down commands are not working
	-- Use Fire any armed weapon instead
	set(wep_sel,26)

	if (weapon==1) then
		if get(miss_armed)==1 then
			set(guns_armed,0)
			set(bomb_armed,0)
			weapon=2
		end
		if get(bomb_armed)==1 then
			set(guns_armed,0)
			set(miss_armed,0)
			weapon=3
		end
	end
	if (weapon==2) then
		if get(guns_armed)==1 then
			set(miss_armed,0)
			set(bomb_armed,0)
			weapon=1
		end
		if get(bomb_armed)==1 then
			set(guns_armed,0)
			set(miss_armed,0)
			weapon=3
		end
	end
	if (weapon==3) then
		if get(guns_armed)==1 then
			set(miss_armed,0)
			set(bomb_armed,0)
			weapon=1
		end
		if get(miss_armed)==1 then
			set(guns_armed,0)
			set(bomb_armed,0)
			weapon=2
		end
	end
	if (weapon==0) then
		if get(guns_armed)==1 then
			weapon=1
		end
		if get(miss_armed)==1 then
			weapon=2
		end
		if get(bomb_armed)==1 then
			weapon=3
		end	
	end
	if (get(guns_armed)==0 and get(miss_armed)==0 and get(bomb_armed)==0) then
		weapon=0
	end
end 

function draw() 
	drawAll(components);
	
	if get(hud_on)==1 then

		--Readings
		drawText(fontHuge,   centerX-015, centerY+121, txtMagHdg, red, green, blue, alpha)
		drawText(fontHuge,   centerX-140, centerY-008, txtIas, red, green, blue, alpha)
		drawText(fontHuge,   centerX+090, centerY-008, txtAltitude, red, green, blue, alpha)
		drawText(fontMedium, centerX+095, centerY-029, txtVVI, red, green, blue, alpha)
		drawText(fontSmall,  centerX-142, centerY+015, txtG, red, green, blue, alpha)

		drawRectangle(centerX-145, centerY+009, 42, 20);
		drawRectangle(centerX+087, centerY+009, 62, 20);
		drawRectangle(centerX-020, centerY+138, 44, 20);

		-- Radar altimeter
		if (get(rdr_alt)<=5000) then
			txtRadAlt = string.format("R %4d",get(rdr_alt));
			drawText(fontMedium, centerX+95, centerY+15, txtRadAlt, red, green, blue, alpha)
		end 

		--Gear down indicator
		if (get(gear_handle)==1)  then
			drawText(fontSmall, centerX-140, centerY-86, "GEAR", red, green, blue, alpha)
		end
		
		--Gear down indicator
		if (get(gear_handle)==0)  then
			if (get(rdr_alt)<2000) then
				if (get(theta)<-20) or (get(vvi)<-6000) then
					drawText(fontHuge, centerX-35, centerY-70, "PULL UP", red, green, blue, alpha)
				end
			end
		end
	
		--Speed brake indicator
		if (get(spd_brk)>0)  then
			drawText(fontSmall, centerX-140, centerY-110, "SPD BRK", red, green, blue, alpha)
		end	

		--Parking brake indicator
		if (get(prk_brk)>0)  then
			drawText(fontSmall, centerX-140, centerY-98, "BRAKE", red, green, blue, alpha)
		end	

		--Nav mode		
		if (get(guns_armed)==0 and get(miss_armed)==0 and get(bomb_armed)==0) then
			drawText(fontSmall, centerX+110, centerY-86, "NAV", red, green, blue, alpha)				
			--HUD middle marker
			drawLine(centerX-10, centerY, centerX-30, centerY, red, green, blue, alpha);
			drawLine(centerX-10, centerY, centerX-10, centerY-10, red, green, blue, alpha);
			drawLine(centerX+10, centerY, centerX+30, centerY, red, green, blue, alpha);
			drawLine(centerX+10, centerY, centerX+10, centerY-10, red, green, blue, alpha);
		end

		--Weapon modes
		if (get(guns_armed)==1) then
			local gunpos = 95;
			drawText(fontSmall, centerX+110, centerY-86, "GUN", red, green, blue, alpha)	
			drawLine(centerX+5, centerY-gunpos, centerX+20, centerY-gunpos, reg, green, blue, alpha)	
			drawLine(centerX-6, centerY-gunpos, centerX-21, centerY-gunpos, reg, green, blue, alpha)	
			drawLine(centerX, centerY-6-gunpos, centerX, centerY-21-gunpos, reg, green, blue, alpha)	
			drawLine(centerX, centerY+5-gunpos, centerX, centerY+20-gunpos, reg, green, blue, alpha)	
		end
		if (get(miss_armed)==1) then
			drawText(fontSmall, centerX+110, centerY-86, "A/A", red, green, blue, alpha)
			drawCircle(centerX, centerY, 60, reg, green, blue, alpha);		
		end
		if (get(bomb_armed)==1) then
			drawText(fontSmall, centerX+110, centerY-86, "A/G", red, green, blue, alpha)
			drawLine(centerX+5, centerY, centerX+20, centerY, reg, green, blue, alpha)	
			drawLine(centerX-6, centerY, centerX-21, centerY, reg, green, blue, alpha)	
			drawLine(centerX, centerY+5, centerX, centerY+20, reg, green, blue, alpha)	

			local bank = get(roll)
			if (bank>=-50 and bank<=50) then
				rotateLine(centerX, centerY-5, centerX, centerY-100, centerX, centerY, bank)
				rotateLine(centerX-11, centerY-100, centerX+10, centerY-100, centerX, centerY, bank)
			end
		end
	
	
		--Horizon line
		local h_ty= -(get(theta))*20--pitch
		local r_amount=get(roll)--roll
		if (h_ty < 180 and h_ty > -180) then
			rotateLine(centerX-100, centerY+h_ty, centerX+100, centerY+h_ty, centerX, centerY, r_amount)
		end	
		
		--Pitch ladder
		for h=-18*increment,18*increment,increment do
		if ((h_ty+h) < 150 and (h_ty+h) > -180) then
		
			local h2 = h  + 3
			local h3 = h2 + 3
			if (h<0) then
				h2 = h  - 3
				h3 = h2 - 3
			end
				if (h==0) then
					h2 = h
					h3 = h2
				end 
		
				local txtPitch  = string.format("%2d",h/increment*5)
				if (h~=0) then
					rotateText(txtPitch, centerX-85, h+centerY+h_ty, centerX, centerY, r_amount)
					rotateText(txtPitch, centerX+65, h+centerY+h_ty, centerX, centerY, r_amount)
					rotateLine(centerX-60, h+centerY+h_ty,  centerX-20, h2+centerY+h_ty, centerX, centerY, r_amount)
					rotateLine(centerX-20, h2+centerY+h_ty, centerX-20, h3+centerY+h_ty, centerX, centerY, r_amount)
					rotateLine(centerX+20, h2+centerY+h_ty, centerX+60, h+centerY+h_ty,  centerX, centerY, r_amount)
					rotateLine(centerX+20, h2+centerY+h_ty, centerX+20, h3+centerY+h_ty, centerX, centerY, r_amount)			
				end	
			end
		end
	
		if (get(guns_armed)==0) then
			--Velocity Vector ball
			local a = get(aoa)
			local b = get(beta)
			local vec_ball_ty=(-a*20)+centerY
			local vec_ball_tx=(-b*20)+centerX
			drawCircle(vec_ball_tx,   vec_ball_ty, 5, red, green, blue, alpha)
			drawLine(vec_ball_tx-10,vec_ball_ty,   vec_ball_tx-05, vec_ball_ty,    red, green, blue, alpha)
			drawLine(vec_ball_tx+05,vec_ball_ty,   vec_ball_tx+10, vec_ball_ty,    red, green, blue, alpha)
			drawLine(vec_ball_tx,   vec_ball_ty+5, vec_ball_tx,    vec_ball_ty+10, red, green, blue, alpha)
		end
	end
end