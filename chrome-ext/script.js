function findTextNodes(node)
{
	var res = [];

	function rec(node)
	{
		if (node.tagName == "SCRIPT" || node.tagName == "STYLE")
		{
			return;
		}

		if (node.nodeType === document.TEXT_NODE)
		{
			res.push(node);
		}
		else if (node.nodeType === document.ELEMENT_NODE)
		{
			for (var i = 0; i < node.childNodes.length; i++)
			{
				rec(node.childNodes[i]);
			}
		}
	}

	rec(node);
	return res;
}

function containsDie(formula)
{
	switch (formula.kind)
	{
		case "die":
		case "d20":
			return true;
		case "op":
			return containsDie(formula.left) || containsDie(formula.right);
		default:
			return false;
	}
}

function rollDie(die)
{
	var sum = 0;
	var amount = die.amount || 1;

	var rolls = [];

	for (var i = 0; i < amount; i++)
	{
		var r = Math.floor(Math.random() * die.faces) + 1;
		rolls.push(r);
		sum += r;
	}

	return {value: sum, text: "{" + rolls.join(",") + "}"};
}

function rolld20(d20)
{
	var sum = Math.floor(Math.random() * 20) + 1;
	var text = "{" + sum + "}";
	switch (d20.op)
	{
		case "+":
			sum += d20.value;
			text += " + " + d20.value;
			break;
		case "-":
			sum -= d20.value;
			text += " - " + d20.value;
			break;
	}

	return {value: sum, text: text};
}

function computeOp(formula)
{
	var left = computeExpression(formula.left);
	var right = computeExpression(formula.right);

	var value;
	switch(formula.op)
	{
		case "+": value = left.value + right.value; break;
		case "-": value = left.value - right.value; break;
		case "*": value = left.value * right.value; break;
		case "/": value = Math.floor(left.value / right.value); break;
	}

	var text = "(" + left.text + " " + formula.op + " " + right.text + ")";

	return {value: value, text: text};
}

function computeExpression(formula)
{
	switch (formula.kind)
	{
		case "integer":
			return {value: formula.value, text: formula.value};
		case "die":
			return rollDie(formula);
		case "d20":
			return rolld20(formula);
		case "op":
			return computeOp(formula);
	}
}

const die_regex = /[dD\+\-]\d+/g;
var formulas = {};

function treatNode(node)
{
	var text = node.nodeValue;
	if (!text.match(die_regex))
		return;

	var parsed = peg$parse(text);

	var replaced = parsed.map(e =>
	{
		if (typeof e === 'string')
			return e;

		if (containsDie(e.expression))
		{
			formulas[e.text] = e.expression;
			return "<span class='plonk-formula'>" + e.text + "</span>";
		}
		else
			return e.text;
	});

	var span = document.createElement('span');
	span.innerHTML = replaced.join('');
	var nodes = Array.from(span.childNodes);
	node.replaceWith(...nodes);
}

function stripOuterParens(text)
{
	if (text.charAt(0) == "(" && text.charAt(text.length - 1) == ")")
		return text.slice(1, -1);

	return text;
}

function onFormulaClicked(event)
{
	var text = event.target.innerText;
	var formula = formulas[text];
	var result = computeExpression(formula);

	var p = document.createElement('p');

	p.innerHTML = "<span class='plonk-formula'>" + text + "</span>" +
		'<br />' + stripOuterParens(result.text) + " → " + result.value;

	makeFormulasClickable(p);

	var div = document.getElementById("plonk-box");
	div.insertBefore(p, div.firstChild);

	div.classList.add("plonk-fade");
	div.addEventListener("animationend", function(e)
	{
		div.classList.remove("plonk-fade");
	});
}

function createBox()
{
	var div = document.createElement('div');
	div.setAttribute("id", "plonk-box");
	document.body.appendChild(div);
}

function makeFormulasClickable(root)
{
	var found = false;
	var formulas = root.getElementsByClassName("plonk-formula");
	for (var formula of formulas)
	{
		found = true;
		formula.addEventListener("click", onFormulaClicked);
	}

	return found;
}

function setup()
{
	findTextNodes(document.body).forEach(treatNode);
	var foundFormulas = makeFormulasClickable(document.body);

	if (foundFormulas)
		createBox();
}

setup();
