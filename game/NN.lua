local NN = {}

-- Internal Classes
local _Neuron = {}
local _NeuronLayer = {}

function _Neuron:new(inputs, bias, o)
	-- if inputs is a number, it is used as n_inputs as the neuron is initialized with random values
	-- if inputs is a table, is is used as init values for the neuron
	local o = o or {}

	local this_type = type(inputs)
	if this_type == "table" then
		for key, value in ipairs(inputs) do
			o[key] = value
		end
	elseif this_type == "number" then
		for i = 1, inputs, 1 do
			o[i] = love.math.random()
		end
	else
		print("[ERROR] - _Neuron:new() - Could not initialize Neuron with type:", this_type)
		return nil
	end

	local bias_index = #o + 1
	o[bias_index] = bias or love.math.random()

	setmetatable(o, self)
	self.__index = self
	return o
end

function _NeuronLayer:new(neurons, inputs, bias, o)
	-- if neurons is a number, it is used as n_neurons as the layer is initialized with random neurons
	-- if neurons is a table, is is used as init values for neurons
	local o = o or {}

	local this_type = type(neurons)
	if this_type == "table" then
		for key, value in ipairs(neurons) do
			o[key] = value
		end
	elseif this_type == "number" then
		for i = 1, neurons, 1 do
			o[i] = _Neuron:new(inputs, bias)
		end
	else
		print("[ERROR] - _NeuronLayer:new() - Could not initialize NeuronLayer with type:", this_type)
		return nil
	end

	setmetatable(o, self)
	self.__index = self
	return o
end

-- NN Class
function NN:new(inputs, outputs, hidden_layers, neurons_per_hidden_layer, o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self

	o[1] = _NeuronLayer(inputs, 1)
	local last_layer_count = inputs
	for i = 2, hidden_layers + 1 do
		o[i] = _NeuronLayer(neurons_per_hidden_layer, last_layer_count)
		last_layer_count = neurons_per_hidden_layer
	end
	local output_layer_index = #o + 1
	o[output_layer_index] = _NeuronLayer(outputs, last_layer_count)

	return o
end

return NN