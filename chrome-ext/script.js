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

const formula_regex = /\d+?d\d+(\s*[\+\-]\s*\d+)?|(?<!\d)[\+\-]\s*\d+/g;

function treatNode(node)
{
	var text = node.nodeValue;
	var replaced = text.replaceAll(formula_regex, function(match)
	{
		return "<span class='plonk-formula'>" + match + "</span>";
	});

	if (replaced != text)
	{
		var span = document.createElement('span');
		span.innerHTML = replaced;
		var nodes = Array.from(span.childNodes);
		node.replaceWith(...nodes);
	}
}

function onFormulaClicked(event)
{
	var text = event.target.innerText;
	var parsed = peg$parse(text);
	console.log(parsed);

}

function setup()
{
	findTextNodes(document.body).forEach(treatNode);
	var formulas = document.getElementsByClassName("plonk-formula");
	for (var formula of formulas)
	{
		formula.addEventListener("click", onFormulaClicked);
	}

	var parsed = peg$parse("Some random bull with 23d45 + 4 in the middle but also (3d12 + d4 ) * 5.");
	console.log(parsed);
}

setup();
