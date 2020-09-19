local js = require "js"

local input_div
local rolls_div

local formula_in = '<span class="formula">'
local formula_out = '</span>'

local update_events

local default_text = [[
Welcome to Plonk, a minimalistic dice roller!<br>
<br>
You can type any text you want in here. Anything within brackets is considered to be a dice formula. For instance: [2d20 + 1]. Click on a formula to roll it! After editing the text, press tab or click outside the box to process it.<br>
<br>
Your text will be saved locally in your browser, but to be safe you should probably prepare and save the text in another editor!<br>
<br>
The notations "dX" and "XdY" are recognized, as well as all basic arithmetic operations:<br>
<br>
Just a [d6].<br>
With a modifier [d10 + 3].<br>
Multiple dice are added together: [4d6 + 10].<br>
You can go as crazy as you like! [(3d6 * 5) + (4 + d4) * 3].<br>
Use "//" for integer division, rounded down: [3d10 // 2].<br>
<br>
That's about it!<br>
]]

local comparators =
{
	[""] = function(value, test) return value == test end,
	["="] = function(value, test) return value == test end,
	[">"] = function(value, test) return value > test end,
	["<"] = function(value, test) return value < test end,
	[">="] = function(value, test) return value >= test end,
	["<="] = function(value, test) return value <= test end
}

local function sum(faces, dice, reroll_comparator, arg)

	if reroll_comparator and not comparators[reroll_comparator] then
		return nil
	end

	local rolls = {}
	local sum = 0

	for i = 1, dice or 1 do
		local r = math.random(faces)
		table.insert(rolls, r)

		if reroll_comparator and comparators[reroll_comparator](r, arg) then

			rolls[#rolls] = "<s>" .. rolls[#rolls] .. "</s>"

			r = math.random(faces)
			table.insert(rolls, r)
		end

		sum = sum + r
	end

	if #rolls > 1 then
		return "{" .. table.concat(rolls, ",") .. "}" .. " " .. sum
	else
		return sum
	end
end
local function count(faces, dice, comparator, arg)

	if not comparators[comparator] then
		return nil
	end

	local rolls = {}
	local count = 0

	for i = 1, dice or 1 do
		local r = math.random(faces)
		table.insert(rolls, r)
		if comparators[comparator](r, arg) then
			count = count + 1
		end
	end

	return "{" .. table.concat(rolls, ",") .. "}" .. " " .. count
end

local function roll(str)

	local display = str:gsub(
		"(%d*)d(%d+)([cr]?)([<>=]*)(%d*)",
		function(dice, faces, mode, comparator, arg)
			dice = tonumber(dice) or 1
			faces = tonumber(faces)
			arg = tonumber(arg)

			if mode == "" then
				return sum(faces, dice)
			elseif mode == "r" then
				return sum(faces, dice, comparator, arg)
			elseif mode == "c" then
				return count(faces, dice, comparator, arg)
			end
		end
	)

	local code = display:gsub("{", "--[["):gsub("}", "]]")
	local func = load("return (" .. code .. ")")

	if func then
        local success, value = pcall(func)
        if success and value then
            return display, value
        end
	end

    return nil
end

local function output_roll(formula, treated, result)

    local p = js.global.document:createElement "p"

    local text = treated and (treated .. " → " .. result) or "Invalid formula"

    p.innerHTML = formula_in .. "[" .. formula .. "]" .. formula_out ..
        '<br />' .. text

    rolls_div:appendChild(p)
    p:scrollIntoView()

    update_events()
end

local function on_formula_clicked(elem, event)

    local formula = elem.innerHTML:sub(2,-2)

	formula = formula:gsub("&lt;", "<")
	formula = formula:gsub("&gt;", ">")

    local treated, result = roll(formula)
    output_roll(formula, treated, result)
end

local storageKey = "lastText"

local function save_locally()

    local storage = js.global.window.localStorage
    if storage then
        storage:setItem(storageKey, input_div.innerHTML);
    end
end

local function load_locally()

    local function check_empty(text)
        return text:gsub("<(.-)>", ""):gsub("%s", "") == ""
    end

    local storage = js.global.window.localStorage
    if storage then
        local text = storage:getItem(storageKey);

        if text and not check_empty(text) then
            input_div.innerHTML = text
        else
            input_div.innerHTML = default_text
        end
    end
end

local function treat_formulas()

    local txt = input_div.innerHTML

    txt = txt:gsub(formula_in .. "(.-)" .. formula_out, "%1")
    txt = txt:gsub("%[[^%[%]]+%]", formula_in .. "%1" .. formula_out)
    input_div.innerHTML = txt

    update_events()
    save_locally()
end

update_events = function()
    local spans = js.global.document:getElementsByClassName "formula"

    for i = 0, spans.length - 1 do
        spans[i].onclick = on_formula_clicked
    end
end

local function setup()

    input_div = js.global.document:getElementById "mainText"
    input_div:addEventListener("blur", treat_formulas)

    rolls_div = js.global.document:getElementById "rolls"

    math.randomseed(os.time())

    load_locally()
    treat_formulas()
end

setup()
