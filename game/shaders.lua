-- Guilherme Cunha Prada 2020

local shaders = {}

shaders.red = love.graphics.newShader[[
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
		vec4 pixel = Texel(texture, texture_coords );//This is the current pixel color
		vec4 redish = vec4(1, 0.1, 0.1, 0.7);
		return pixel * redish;
	}
]]

shaders.blue = love.graphics.newShader[[
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
		vec4 pixel = Texel(texture, texture_coords );//This is the current pixel color
		vec4 blueish = vec4(0, 0.5, 0.9, 0.9);
		return pixel * blueish;
	}
]]

return shaders
