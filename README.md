# md-viewer

A single local HTML page that opens a Markdown file and renders it for reading in your
browser. No server, no build step, no network — open `index.html` and choose a file.

## Use it

Open `index.html` in a browser, then either press **Choose a file** or drop a `.md` file
anywhere on the page. The file is read in the browser tab; nothing is uploaded anywhere.

`sample.md` is included so you can see what it looks like.

## What it renders

Standard Markdown plus the GitHub extensions that show up in notes and reports: tables,
task lists, strikethrough and fenced code. Documents with three or more subheadings get a
contents rail that marks the section you are reading. Wide tables scroll on their own.
Ctrl+P prints the document without the surrounding interface.

Dark mode follows the operating system setting.

## How it works

`index.html` holds the whole viewer — markup, styles and script. It uses two vendored
libraries in `vendor/`, committed so the page works offline:

- [marked](https://github.com/markedjs/marked) 12.0.2 — Markdown to HTML
- [DOMPurify](https://github.com/cure53/DOMPurify) 3.1.6 — sanitises the result, since
  Markdown can contain raw HTML

Links in a document open in a new tab. Relative image paths will not resolve when the page
is opened from `file://`.
