// This is a grammar file for the peggy library
// Run `peggy grammar.peggy` to generate `grammar.js`

{{
	var module = {}; // Silence errors that expect the JS file to be used as module
}}

start
	= not_formula formulas:(@formula not_formula)+
	{
		return formulas;
	}

not_formula
	= (!formula .)*

formula
	= expression: additive
	{
		return {
			expression: expression,
			range: range()
		}
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
	= amount:integer? 'd' faces:integer
	{
		return {
			kind: "die",
			amount: amount,
			faces: faces
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
