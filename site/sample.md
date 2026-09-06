# Reading a document, not a file

This sample exists so you can see what the viewer does before pointing it at
your own work. Open it, and this page is what you get.

## What it handles

Everything in standard Markdown, plus the GitHub extensions people actually
use in notes and reports: tables, task lists, strikethrough and fenced code.

- Ordinary lists, with **bold**, *italic* and `inline code`
- Nested items, which keep their own spacing
  - Like this one
- [Links](https://commonmark.org), which open in a new tab

1. Numbered lists are numbered
2. And continue in order

- [x] Task lists render as checkboxes
- [ ] Including the unfinished ones

> Block quotes sit against a pencil-blue rule, in italic, a little quieter
> than the surrounding text.

## Tables

| Element      | Set in            | Notes                          |
| ------------ | ----------------- | ------------------------------ |
| Body text    | Charter / Georgia | Roughly 66 characters a line   |
| Headings     | The same serif    | Heavier, tighter               |
| Code         | System monospace  | On a tinted ground             |

Wide tables scroll on their own rather than pushing the page sideways.

## Code

```js
function render(text) {
  return DOMPurify.sanitize(marked.parse(text));
}
```

## Long documents

Any document with three or more subheadings gets a contents rail on the left,
on a wide enough screen. The current section is marked as you scroll.

### Deeper headings

Third-level headings are indented in that rail, so the shape of a long report
stays legible.

### Printing

Press Ctrl+P and the chrome disappears — you get the document on white paper
with black type.

---

Nothing here is uploaded anywhere. The file is read in the browser tab and
stays on this computer.
