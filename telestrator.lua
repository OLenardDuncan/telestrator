local points = {}
local joints = {}
local is_telestrating = false
local color = {{r = 0, g = 0, b = 0}, {r = 1, g = 1, b = 1}} --2 rgb arrays, part of the double color quick switch thing, one starts as black and the other as white
local current_color = 1 --1 or 2, used as keys on the color array
local mouse = {x = -1, y = -1}
local is_drawing = false
local is_changing_color = false --specific var names yay
local dragging_slider = "none"
local sliders = {{r = {x = 0, y = 0}, g = {x = 0, y = 35}, b = {x = 0, y = 70}}, {r = {x = 255, y = 0}, g = {x = 255, y = 35}, b = {x = 255, y = 70}}}
local mode = false --false for drawing mode, true for joint selection mode (boolean because I'm lazy)
local help_menu = true
local dragging_joint = false --true if you're resizing a joint circle
local clicks = {} --handles the out-of-telestrator left click thing

local function draw_rounded_quad(x, y, width, height, cornerRadius) --thanks lapsus - sdk/draw_rounded_quad.lua
	draw_disk(x + cornerRadius, y + cornerRadius, 0, cornerRadius, 32, 1, -90, -90, 0)
	draw_quad((x + cornerRadius), y, (width - cornerRadius * 2), height)
	draw_disk(x + (width - cornerRadius), y + cornerRadius, 0, cornerRadius, 32, 1, 180, -90, 0)
	draw_quad(x, (y + cornerRadius), cornerRadius, (height - cornerRadius * 2))
	draw_quad((x + (width - cornerRadius)), (y + cornerRadius), cornerRadius, (height - cornerRadius * 2))
	draw_disk(x + cornerRadius, y + cornerRadius + (height - cornerRadius * 2), 0, cornerRadius, 32, 1, 0, -90, 0)
	draw_disk(x + (width - cornerRadius), y + cornerRadius + (height - cornerRadius * 2), 0, cornerRadius, 32, 1, 0, 90, 0)
end

local function position_between(pos_x, pos_y, left_x, top_y, right_x, bottom_y)
	if pos_x >= left_x and pos_x <= right_x and pos_y >= top_y and pos_y <= bottom_y then
		return true
	end
	return false
end

local function key_down(k)
	if (k == 303 or k == 304) and help_menu then --right shift, left shift
		help_menu = false
	end
	
	if is_telestrating then
		if k == 307 or k == 308 then --alt gr, alt
			is_changing_color = not is_changing_color
			is_drawing = false
			dragging_joint = false
		end
		
		if k == 32 then --spacebar
			points = {}
			joints = {}
			is_drawing = false
			dragging_joint = false
		end
		
		if k == 305 or k == 306 then --right ctrl, left ctrl
			mode = not mode
			is_drawing = false
			dragging_joint = false
		end
		
		if k == 122 then --z
			if mode then
				table.remove(joints)
			else
				table.remove(points)
			end
			is_drawing = false
			dragging_joint = false
		end
		return 1
	end
end

local function key_up()
	if is_telestrating then
		return 1
	end
end

local function mouse_down(b, x, y)
	mouse.x, mouse.y = x, y
		
	if b == 4 then
		is_telestrating = true
	elseif b == 5 then
		is_telestrating = false
		is_drawing = false
		dragging_joint = false
		points = {}
		joints = {}
	end
	
	if is_telestrating then
		if is_changing_color then
			for key, value in pairs(sliders[current_color]) do
				if position_between(mouse.x, mouse.y, 104 + value.x, 105 + value.y, 106 + value.x, 135 + value.y) then
					dragging_slider = key
				elseif position_between(mouse.x, mouse.y, 105, 105 + value.y, 361, 135 + value.y) then
					sliders[current_color][key].x = mouse.x - 105
				end
			end
		elseif b == 1 then
			if mode then
				table.insert(joints, {x = x, y = y, radius = 5, color = {r = color[current_color].r, g = color[current_color].g, b = color[current_color].b}}) --joints had to be simpler because of a few technical issues
				dragging_joint = true
			else
				is_drawing = true
				table.insert(points, {x = x, y = y, line = false, color = {r = color[current_color].r, g = color[current_color].g, b = color[current_color].b}}) --I'd use color = color, but for some reason the color picker changes ALL points' color when using that
			end	
		end
		return 1
	else
		if b == 1 then
			table.insert(clicks, {radius = 0, opacity = 1, x = x, y = y})
		end
	end
end

local function mouse_up(b, x, y)
	mouse.x, mouse.y = x, y

	if is_telestrating then
		if is_changing_color then
			dragging_slider = "none"
		else
			if b == 1 then
				dragging_joint = false
				is_drawing = false
			end
		end
		
		if b == 2 then
			current_color = 3 - current_color
		end
		return 1
	end
end

local function mouse_move(x, y)
	mouse.x, mouse.y = x, y
	
	if is_telestrating then
		if is_drawing then
			table.insert(points, {x = x, y = y, line = true, color = {r = color[current_color].r, g = color[current_color].g, b = color[current_color].b}})
		end
		
		if is_changing_color and dragging_slider ~= "none" then
			sliders[current_color][dragging_slider].x = mouse.x - 105
			if sliders[current_color][dragging_slider].x < 0 then
				sliders[current_color][dragging_slider].x = 0
			elseif sliders[current_color][dragging_slider].x > 255 then
				sliders[current_color][dragging_slider].x = 255
			end
		end
		
		if dragging_joint and math.sqrt(((x - joints[#joints].x) ^ 2) + ((y - joints[#joints].y) ^ 2)) >= 5 then
			joints[#joints].radius = math.sqrt(((x - joints[#joints].x) ^ 2) + ((y - joints[#joints].y) ^ 2))
		end
	end
end

local function draw()
	if is_telestrating then
		for i = 1, #points do
			set_color(points[i].color.r, points[i].color.g, points[i].color.b, 1)
			draw_disk(points[i].x, points[i].y, 0, 5, 90, 1, 0, 360, 0)
			
			if i ~= 1 and points[i].line then
				draw_line(points[i].x, points[i].y, points[i-1].x, points[i-1].y, 10)
			end
		end

		for i = 1, #joints do
			set_color(joints[i].color.r, joints[i].color.g, joints[i].color.b, 1)
			draw_disk(joints[i].x, joints[i].y, joints[i].radius, 5 + joints[i].radius, 90, 1, 0, 360, 0)
		end

		if is_changing_color then
			set_color(0, 0, 0, 1)
			draw_rounded_quad(100, 100, 266, 145, 5)
			
			for i = 0, 255 do
				set_color(1, 0, 0, i / 255)
				draw_quad(105 + i, 105, 1, 30)
				set_color(0, 1, 0, i / 255)
				draw_quad(105 + i, 140, 1, 30)
				set_color(0, 0, 1, i / 255)
				draw_quad(105 + i, 175, 1, 30)
			end
			
			for key, value in pairs(sliders[current_color]) do
				set_color(0.25, 0.25, 0.25, 1)
				draw_quad(104 + value.x, 105 + value.y, 3, 30)
				color[current_color][key] = value.x / 255
			end
			
			set_color(color[1].r, color[1].g, color[1].b, 1)
			draw_quad(120, 210, 113, 30)
			set_color(color[2].r, color[2].g, color[2].b, 1)
			draw_quad(233, 210, 113, 30)
	
			set_color(0.4, 0.4, 0.4, 0.7)
			draw_disk(120, 225, 0, 15, 90, 1, 180, 180, 0)
			draw_disk(346, 225, 0, 15, 90, 1, 0, 180, 0)

			set_color(0, 0, 0, 0.7)
			if current_color == 1 then
				draw_disk(120, 225, 0, 10, 90, 1, 180, 180, 0)
			else
				draw_disk(346, 225, 0, 10, 90, 1, 0, 180, 0)
			end
		else
			if is_drawing then
				set_color(color[current_color].r + 0.2, color[current_color].g + 0.2, color[current_color].b + 0.2, 0.75)
			else
				set_color(color[current_color].r, color[current_color].g, color[current_color].b, 0.50)
			end
			
			if mode then
				draw_disk(mouse.x, mouse.y, 5, 10, 90, 1, 0, 360, 0)
			else
				draw_disk(mouse.x, mouse.y, 0, 5, 90, 1, 0, 360, 0)
			end
		end
	end
	
	if help_menu then
		set_color(0.15, 0.15, 0.15, 0.80)
		draw_rounded_quad(10, 298, 470, 187, 10)
		
		set_color(0.15, 0.15, 0.15, 0.85)
		draw_rounded_quad(10, 298, 470, 30, 10)
		
		set_color(0.75, 0.75, 0.75, 0.50)
		draw_rounded_quad(15, 335, 460, 18, 9)
		draw_rounded_quad(15, 360, 460, 18, 9)
		draw_rounded_quad(15, 385, 460, 18, 9)
		draw_rounded_quad(15, 410, 460, 18, 9)
		draw_rounded_quad(15, 435, 460, 18, 9)
		draw_rounded_quad(15, 460, 460, 18, 9)
		
		set_color(0, 0, 0, 1)
		draw_text("Telestrator help", 20, 300, 2)
		draw_text("Spacebar to clear the screen (exiting the telestrator also works).", 20, 335, 1)
		draw_text("Alt to access the color picker (click the bar or drag the sliders).", 20, 360, 1)
		draw_text("Press the mousewheel to swap between the 2 selected colors.", 20, 385, 1)
		draw_text("Ctrl to swap between drawing and joint selection mode.", 20, 410, 1)
		draw_text("Drag mouse in joint mode to change brush size.", 20, 435, 1)
		draw_text("Press z to undo last action (both modes).", 20, 460, 1)
	end
	
	if #clicks > 0 then
		for i = #clicks, 1, -1 do
			local min_rad = 10
			if clicks[i].radius > 10 then
				min_rad = clicks[i].radius
			end
			
			set_color(color[current_color].r, color[current_color].g, color[current_color].b, clicks[i].opacity)
			draw_disk(clicks[i].x, clicks[i].y, min_rad - 10, clicks[i].radius, 90, 1, 0, 360, 0)
			
			clicks[i].opacity = clicks[i].opacity - 0.02
			clicks[i].radius = clicks[i].radius + 1
			
			if clicks[i].opacity <= 0 then
				table.remove(clicks, i)
			end
		end
	end
end

add_hook("key_down", "y_telestrator", key_down)
add_hook("key_up", "y_telestrator", key_up)
add_hook("mouse_button_down", "y_telestrator", mouse_down)
add_hook("mouse_button_up", "y_telestrator", mouse_up)
add_hook("mouse_move", "y_telestrator", mouse_move)
add_hook("draw2d", "y_telestrator", draw)

echo("^07----------------------")
echo("^07telestrator.lua by yoyo.")
echo("^07mouse wheel up/down to enter/exit telestrating mode, respectively.")
echo("^07press shift to dismiss the help menu.")
echo("^07----------------------")