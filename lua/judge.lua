---@class judge.Validator
---@field validate fun(obj: any): boolean, string
local Validator = {}

---@return judge.Validator
function Validator.optional(validator)
	return setmetatable({
		validate = function(obj)
			if obj == nil then
				return true
			end
			return validator.validate(obj)
		end,
	}, getmetatable(validator))
end

---@return judge.Validator
function Validator.min_length(validator, length)
	return setmetatable({
		validate = function(obj)
			if #obj < length then
				return false, string.format("too short: expected at least %d, got %d", length, #obj)
			end
			return true
		end,
	}, getmetatable(validator))
end

---@return judge.Validator
function Validator.max_length(validator, length)
	return setmetatable({
		validate = function(obj)
			if #obj > length then
				return false, string.format("too long: expected at most %d, got %d", length, #obj)
			end
			return true
		end,
	}, getmetatable(validator))
end

---@return judge.Validator
function Validator.matches(validator, pattern)
	return setmetatable({
		validate = function(obj)
			if not string.match(obj, pattern) then
				return false, string.format("invalid pattern: expected %s, got %s", pattern, obj)
			end
			return true
		end,
	}, getmetatable(validator))
end

---@return judge.Validator
function Validator.enum(validator, values)
	return setmetatable({
		validate = function(obj)
			for _, v in ipairs(values) do
				if v == obj then
					return true
				end
			end
			return false, string.format("invalid value: expected one of %s, got %s", table.concat(values, ", "), obj)
		end,
	}, getmetatable(validator))
end

function Validator.array(validator)
	return setmetatable({
		validate = function(obj)
			for _, v in ipairs(obj) do
				local ok, err = validator.validate(v)
				if not ok then
					return false, err
				end
			end
			return true
		end,
	}, getmetatable(validator))
end

---@class judge.Atom: judge.Validator

local judge = {}

local atom_mt = {
	---@return fun(...): judge.Atom
	__index = function(self, k)
		return function(...)
			return Validator[k](self, ...)
		end
	end,
}

---@return judge.Atom
function judge.object(schema)
	return setmetatable({
		validate = function(obj)
			for k, validator in pairs(schema) do
				local ok, err = validator.validate(obj[k])
				if not ok then
					return false, err
				end
			end
			return true
		end,
	}, atom_mt)
end

---@return judge.Atom
function judge.array(elements, length)
	return setmetatable({
		validate = function(obj)
			if type(obj) ~= "table" then
				return false, "not a table"
			end
			if length and #obj ~= length then
				return false, string.format("invalid length: expected %d, got %d", length, #obj)
			end
			for _, v in ipairs(obj) do
				local ok, err = elements.validate(v)
				if not ok then
					return false, err
				end
			end
			return true
		end,
	}, atom_mt)
end

---@return judge.Atom
function judge.map(key, value)
	return setmetatable({
		validate = function(obj)
			if type(obj) ~= "table" then
				return false, "not a table"
			end
			for k, v in pairs(obj) do
				local k_ok, k_err = key.validate(k)
				if not k_ok then
					return false, k_err
				end
				local v_ok, v_err = value.validate(v)
				if not v_ok then
					return false, v_err
				end
			end
			return true
		end,
	}, atom_mt)
end

---@return judge.Atom
function judge.string()
	return setmetatable({
		validate = function(obj)
			local ok = type(obj) == "string"
			if not ok then
				return false, "not a string"
			end
			return true
		end,
	}, atom_mt)
end

---@return judge.Atom
function judge.number()
	return setmetatable({
		validate = function(obj)
			local ok = type(obj) == "number"
			if not ok then
				return false, "not a number"
			end
			return true
		end,
	}, atom_mt)
end

---@return judge.Atom
function judge.any()
	return setmetatable({
		validate = function()
			return true
		end,
	}, atom_mt)
end

---@return judge.Atom
function judge.one_of(...)
	local validators = { ... }
	return setmetatable({
		validate = function(obj)
			for _, validator in ipairs(validators) do
				local ok = validator.validate(obj)
				if ok then
					return true
				end
			end
			return false, "no valid validator"
		end,
	}, atom_mt)
end

return judge
