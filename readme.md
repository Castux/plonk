# Plonk!

*A minimalistic dice roller for tabletop role-players*

See it [live](https://castux.github.io/plonk/)!

This is essentially a text editor in which dice formulas are highlighted and clickable. It is minimalistic on purpose!

The main use case is to use it on a laptop during a live tabletop RPG session: prepare the rolls you are likely to need often during a big fight, partial or full stats blocks for monsters, etc. Then just click to roll!

Since it is a text editor and a calculator, you can also add new rolls on the fly, keep track of initiative, HP, whatever you need right there in a full screen webpage.

The text is saved locally in your browser to prevent accidental loss, but you should probably prepare and save your session somewhere else!

## Dice formulas supported

Any arithmetic formulas involving parentheses and the usual operators `* + - / // ^ %`, and the following:

- Single number
- Single die: dX
- Sum: XdY (the usual notation)
- Count: XdYc'op'Z (count occurences of faces that match condition 'op'Z)
- Reroll: XdYr'op'Z (reroll once faces that match condition 'op'Z)
- Keep highest: XdYkZ (keep highest Z results, take the sum)
- Drop highest: XdYdZ (drop highest Z results, take the sum)

'op' can be any of the following comparison operators: `= < > <= >=`

Shortcuts:

- c can be omitted if an operator is present
- Operator can be omitted if c is present (means =)
- A formula that starts with + or - gets "d20" added in front automatically

## License

Plonk is free and open source software, released under the [MIT license](license.md). Feel free to fork or submit pull requests!

Includes the following:

- [Fengari](https://fengari.io/), a wonderful Lua VM written in JavaScript for the browser or node.js. MIT license.
