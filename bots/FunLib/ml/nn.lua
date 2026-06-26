----------------------------------------------------------------------------------------------------
--- Pure-Lua neural-network forward pass (no native deps, runs inside Valve's bot sandbox).
--- Supports a simple feed-forward MLP: relu hidden layers + sigmoid output.
--- Weights are produced offline by ml/train_sniper_assassinate.py and exported as Lua tables.
---
--- This is the in-game half of the "hybrid" experiment: rules keep the safety gates,
--- a tiny learned model decides the desire scalar.
----------------------------------------------------------------------------------------------------

local NN = {}

local function relu(x)
	if x > 0 then return x else return 0 end
end

local function sigmoid(x)
	-- clamp to avoid overflow in exp for extreme logits
	if x >= 30 then return 1.0 end
	if x <= -30 then return 0.0 end
	return 1.0 / (1.0 + math.exp(-x))
end

-- y = W * x + b   where W is [out][in], x is [in], b is [out]
local function affine(W, b, x)
	local out = {}
	for o = 1, #W do
		local row = W[o]
		local sum = b[o]
		for i = 1, #row do
			sum = sum + row[i] * x[i]
		end
		out[o] = sum
	end
	return out
end

local function applyActivation(vec, fn)
	local out = {}
	for i = 1, #vec do out[i] = fn(vec[i]) end
	return out
end

--- model = {
---   inputMean = {..}, inputStd = {..},          -- optional feature normalisation
---   layers = { {W=.., b=.., act='relu'}, {W=.., b=.., act='sigmoid'} }
--- }
--- features = { f1, f2, ... } (raw, un-normalised)
--- returns: number in the range of the final activation (sigmoid -> 0..1)
function NN.Forward(model, features)
	if model == nil or model.layers == nil then return nil end

	local x = features
	-- optional standardisation: (x - mean) / std
	if model.inputMean ~= nil and model.inputStd ~= nil then
		local z = {}
		for i = 1, #x do
			local std = model.inputStd[i]
			if std == nil or std == 0 then std = 1 end
			z[i] = (x[i] - model.inputMean[i]) / std
		end
		x = z
	end

	for _, layer in ipairs(model.layers) do
		x = affine(layer.W, layer.b, x)
		if layer.act == 'relu' then
			x = applyActivation(x, relu)
		elseif layer.act == 'sigmoid' then
			x = applyActivation(x, sigmoid)
		end
		-- act == 'linear' / nil -> no activation
	end

	-- single-output network: return the scalar directly
	if #x == 1 then return x[1] end
	return x
end

return NN
