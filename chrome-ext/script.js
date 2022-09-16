function findTextNodes(node)
{
	var res = [];

	function rec(node)
	{
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

const formula_regex = /\d+d\d+\s*[\+\-]\s*\d+/g;

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

findTextNodes(document.body).forEach(treatNode);
