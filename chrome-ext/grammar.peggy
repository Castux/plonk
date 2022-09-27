// This is a grammar file for the peggy library
// Run `peggy grammar.peggy` to generate `grammar.js`

{{
	var module = {}; // Silence errors that expect the JS file to be used as module
}}

start
	= head:not_formula tail:(formula not_formula)+
	{
		return [head, ...tail].flat();
	}

not_formula
	= $(!formula .)*

formula
	= expression:(implied_d20 / additive)
	{
		return {
			expression: expression,
			text: text(),
			range: range()
		}
	}

implied_d20
	= op:('+' / '-') value:integer
	{
		return {
			kind: "d20",
			op: op,
			value: value.value
		};
	}

additive
	= left:multiplicative ws op:('+' / '-') ws right:additive
		{ return {kind: "op", left: left, op: op, right: right}; }
 	/ multiplicative

multiplicative
	= left:atomic ws op:('*' / '/') ws right:atomic
		{ return {kind: "op", left: left, op: op, right: right}; }
	/ atomic

atomic
	= '(' ws @additive ws ')'
		/ die
		/ integer

die
	= amount:integer? [dD] faces:integer
	{
		return {
			kind: "die",
			amount: amount ? amount.value : 1,
			faces: faces.value
		}
	}

integer "integer"
	= digits:$[0-9]+
	{
		return {
			kind: "integer",
			value: parseInt(digits, 10)
		};
	}

ws
	= [ \t\r\n]*
