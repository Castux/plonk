local js = require "js"

local input_div
local rolls_div

local formula_in = '<span class="formula">'
local formula_out = '</span>'

local update_events

local default_text = [[
Welcome to <b>Plonk</b>, a minimalistic dice roller!<br>
<br>
You can type any text you want in here. Anything within brackets is considered to be a dice formula. For instance: [2d20 + 1]. Click on a formula to roll it! After editing the text, press tab or click outside the box to process it.<br>
<br>
Your text will be saved locally in your browser, but to be safe you should probably prepare and save the text in another editor!<br>
<br>
The notations "dX" and "XdY" are recognized, as well as all basic arithmetic operations:<br>
<br>
Just a [d6].<br>
With a modifier [d10 + 3].<br>
Multiple dice are added together as per the usual notation: [4d6 + 10].<br>
You can go as crazy as you like! [(3d6 * 5) + (4 + d4) * 3].<br>
Use "//" for integer division, rounded down: [3d10 // 2].<br>
<br>
If you don't use dice at all, it's just a calculator! [20 * 3 + 5 / 4]<br>
<br>
Click the title above to display this help text at the end of yours!<br>
<br>
<u>Details and extra modes</u><br>
<br>
Sum: XdY (the usual notation)<br>
Count: XdYc'op'Z (count occurences of faces that match condition 'op'Z)<br>
Reroll: XdYr'op'Z (reroll once faces that match condition 'op'Z)<br>
Keep highest: XdYkZ (keep highest Z results, take the sum)<br>
Drop highest: XdYdZ (drop highest Z results, take the sum)<br>
<br>
Valid operators: =, &lt;, &gt;, &lt;=, &gt;=<br>
Shortcuts: c can be omitted if an operator is present. Operator can be omitted if c is present (means =). A formula that starts with + or - gets d20 added in front automatically.<br>
<br>
<u>Examples</u><br>
<br>
Roll 10 d6, count the sixes [10d6c6] or [10d6=6] or [10d6c=6]<br>
Roll 5 d10, count the eights and above [5d10c>=8] or [5d10>=8]<br>
Damage with great weapon fighting in DnD (reroll 1 and 2): [2d10r<=2 + 5]<br>
Ability scores in DnD: [4d6k3]<br>
Advantage and disadvantage rolls with modifier: [2d20k1 + 2] [2d20d1 + 2]<br>
<br>
<u>Cloud Giant (example DnD stat block)</u><br>
<br>
AC 14<br>
Hit points [16d12 + 96]<br>
<br>
STR [+8] DEX [+0] CON [+1]<br>
INT [+1] WIS [+3] CHA [+3]<br>
<br>
Con [+10] Wis [+7] Cha [+7]<br>
Insight [+7] Perception [+7]<br>
<br>
(Some magic stuff omitted)<br>
<br>
Multi: two morningstar attacks<br>
Morningstar: 10 ft, [+12], [3d8 + 8] piercing<br>
Rock: 60/240 ft, [+12], [4d10 + 8] bludgeoning<br>
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
			rolls[#rolls] = "<b>" .. rolls[#rolls] .. "</b>"
			count = count + 1
		end
	end

	return "{" .. table.concat(rolls, ",") .. "}" .. " " .. count
end

local function keep(faces, dice, num, drop)

	if num > dice then
		num = dice
	end

	local rolls = {}
	local total = 0

	for i = 1, dice or 1 do
		local r = math.random(faces)
		table.insert(rolls, r)
		total = total + r
	end

	table.sort(rolls)

	local tag = drop and "s" or "b"

	local sum = 0
	for i = #rolls - num + 1, #rolls do
		sum = sum + rolls[i]
		rolls[i] = "<" .. tag .. ">" .. rolls[i] .. "</" .. tag .. ">"
	end

	if drop then
		sum = total - sum
	end

	for i = 1,#rolls do
		local j = math.random(i, #rolls)
		rolls[i],rolls[j] = rolls[j],rolls[i]
	end

	return "{" .. table.concat(rolls, ",") .. "}" .. " " .. sum
end

local function roll(str)

	local display = str:gsub(
		"(%d*)d(%d+)([crkd]?)([<>=]*)(%d*)",
		function(dice, faces, mode, comparator, arg)
			dice = tonumber(dice) or 1
			faces = tonumber(faces)
			arg = tonumber(arg)

			if mode == "" and comparator == "" then
				return sum(faces, dice)
			elseif mode == "" then
				return count(faces, dice, comparator, arg)
			elseif mode == "r" then
				return sum(faces, dice, comparator, arg)
			elseif mode == "c" then
				return count(faces, dice, comparator, arg)
			elseif mode == "k" then
				return keep(faces, dice, arg)
			elseif mode == "d" then
				return keep(faces, dice, arg, "drop")
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

    local text = treated and
		(treated .. " → <span class='result'>" .. result .. "</span>") or
		"Invalid formula"

    p.innerHTML = formula_in .. "[" .. formula .. "]" .. formula_out ..
        '<br />' .. text

    rolls_div:insertBefore(p, rolls_div.firstChild)
    update_events()
end

local function on_formula_clicked(elem, event)

    local formula = elem.innerHTML:sub(2,-2)

	formula = formula:gsub("&lt;", "<")
	formula = formula:gsub("&gt;", ">")

	if formula:match "^%s*[%+%-]" then
		formula = "d20 " .. formula
	end

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

local function append_help()
	input_div.innerHTML = input_div.innerHTML .. "<br>" .. default_text

	treat_formulas()
end

local function setup()

    input_div = js.global.document:getElementById "mainText"
    input_div:addEventListener("blur", treat_formulas)

    rolls_div = js.global.document:getElementById "rolls"

	local title = js.global.document:getElementById "title"
	title.onclick = append_help

	local lock = js.global.document:getElementsByClassName "lock"
	lock = lock[0]
	lock.onclick = function()
		lock.classList:toggle "unlocked"
		local editable = input_div:getAttribute "contenteditable"
		input_div:setAttribute("contenteditable", editable == "true" and "false" or "true")
	end

    math.randomseed(os.time())

    load_locally()
    treat_formulas()
end

setup()
