-- micro test framework
local function testing(name, groups)
	groups = groups or {}

	if groups[name] then
		return groups[name]
	end

	local tests = {}
	local children = {}

	local root = {
		run = function()
			if name then
				print(string.format("Running group %s", name))
			else
				print("Running tests")
			end
			for _, test in ipairs(tests) do
				print(string.format("- Test %s", test.name))
				local ok, err = pcall(test.fn)
				if test.should_fail then
					if not ok then
						print(string.format("  - Passed"))
					else
						print(string.format("  - Failed: test should have failed"))
					end
				else
					if ok then
						print(string.format("  - Passed"))
					else
						print(string.format("  - Failed: %s", err))
					end
				end
			end
			for _, child in ipairs(children) do
				child.run()
			end
		end,
		test = function(test_name, fn, should_fail)
			table.insert(tests, {
				name = test_name,
				fn = fn,
				should_fail = should_fail,
			})
		end,
		group = function(group_name)
			if groups[group_name] then
				return groups[group_name]
			end
			local id
			if name == nil then
				id = group_name
			else
				id = string.format("%s/%s", name, group_name)
			end
			local res = testing(id, groups)
			table.insert(children, res)
			groups[id] = res
			return res
		end,
	}

	groups[name] = root

	return root
end

package.path = package.path .. ";lua/?.lua"
local judge = require("judge")

local tests = testing("tests")

local atoms = tests.group("atoms")

atoms.group("string").test("basic", function()
	local ok, err = judge.string().validate("hello")
	assert(ok == true, err)
end)

atoms.group("string").test("invalid", function()
	local ok, err = judge.string().validate(42)
	assert(ok == false, err)
end)

atoms.group("array").test("basic", function()
	local ok, err = judge.array(judge.number()).validate({ 1, 2, 3 })
	assert(ok == true, err)
end)

atoms.group("array").test("invalid", function()
	local ok, err = judge.array(judge.number()).validate({ 1, 2, "3" })
	assert(ok == false, err)
end)

atoms.group("array").test("invalid length", function()
	local ok, err = judge.array(judge.number(), 3).validate({ 1, 2 })
	assert(ok == false, err)
end)

atoms.group("array").test("mixed types", function()
	local ok, err = judge.array(judge.any()).validate({ 1, "2", 3 })
	assert(ok == true, err)
end)

tests.run()
