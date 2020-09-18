local js = require "js"

local main_text

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
		return treated, func()
	else
		return nil, "Syntax error in: " .. treated
	end
end


local function on_formula_clicked(elem, event)

    local formula = elem.innerHTML:sub(2,-2)

    local treated, result = roll(formula)
    print(formula, treated, result)
end

local function treat_formulas()

    local txt = main_text.innerHTML

    txt = txt:gsub('<span class="formula">(.-)</span>', "%1")
    txt = txt:gsub("%[[^%[%]]+%]", '<span class="formula">%1</span>')
    main_text.innerHTML = txt

    local spans = js.global.document:getElementsByClassName "formula"

    for i = 0, spans.length - 1 do
        spans[i]:addEventListener("click", on_formula_clicked)
    end
end

local function setup()

    main_text = js.global.document:getElementById "mainText"
    main_text:addEventListener("blur", treat_formulas)

    math.randomseed(os.time())


end

setup()
