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
	for (var i = 0; i < amount; i++)
	{
		sum += Math.floor(Math.random() * die.faces) + 1;
	}
	return sum;
}

function rolld20(d20)
{
	var sum = Math.floor(Math.random() * 20) + 1;
	switch (d20.op)
	{
		case "+":
			return sum + d20.value;
		case "-":
			return sum - d20.value;
	}
}

function computeOp(formula)
{
	var left = computeExpression(formula.left);
	var right = computeExpression(formula.right);

	switch(formula.op)
	{
		case "+": return left + right;
		case "-": return left - right;
		case "*": return left * right;
		case "/": return Math.floor(left / right);
	}
}

function computeExpression(formula)
{
	switch (formula.kind)
	{
		case "integer":
			return formula.value;
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

function onFormulaClicked(event)
{
	var text = event.target.innerText;
	var formula = formulas[text];
	var result = computeExpression(formula);
	console.log(formula, result);
}

function setup()
{
	findTextNodes(document.body).forEach(treatNode);
	var formulas = document.getElementsByClassName("plonk-formula");
	for (var formula of formulas)
	{
		formula.addEventListener("click", onFormulaClicked);
	}
}

setup();
