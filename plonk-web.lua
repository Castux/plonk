local js = require "js"

local input_div
local rolls_div

local formula_in = '<span class="formula">'
local formula_out = '</span>'

local update_events

local function expand(num_faces, num_dice)

	local res = {}

	for i = 1, num_dice or 1 do
		table.insert(res, math.random(num_faces))
	end

	res = table.concat(res, "+")

	if num_dice > 1 then
		res = "(" .. res .. ")"
	end

	return res
end

local function roll(str)

	local treated = str:gsub("(%d*)d(%d+)", function(dice, faces)
		dice = tonumber(dice) or 1
		faces = tonumber(faces)

		return expand(faces, dice)
	end)

	local func = load("return (" .. treated .. ")")

	if func then
        local success, value = pcall(func)
        if success and value then
            return treated, value
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

    local treated, result = roll(formula)
    output_roll(formula, treated, result)
end

local function treat_formulas()

    local txt = input_div.innerHTML

    txt = txt:gsub(formula_in .. "(.-)" .. formula_out, "%1")
    txt = txt:gsub("%[[^%[%]]+%]", formula_in .. "%1" .. formula_out)
    input_div.innerHTML = txt

    update_events()
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

    update_events()
end

setup()
