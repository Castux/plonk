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
const die_regex = /[dD]\d+/g;


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

		return "<span class='plonk-formula'>" + e.text + "</span>";
	});

	var span = document.createElement('span');
	span.innerHTML = replaced.join('');
	var nodes = Array.from(span.childNodes);
	node.replaceWith(...nodes);
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
}

setup();
