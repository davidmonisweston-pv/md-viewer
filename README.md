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

## Opening .md files straight from Windows Explorer

`windows/` sets md-viewer up as a program Windows can open Markdown files with, including
files kept in WSL.

```powershell
powershell -ExecutionPolicy Bypass -File "\\wsl.localhost\Ubuntu\home\<you>\projects\md-viewer\windows\register-file-association.ps1"
```

That writes a ProgID under `HKEY_CURRENT_USER` — no admin rights, nothing machine-wide.
Windows does not allow a script to seize a file type, so make it the default yourself,
once: right-click any `.md` file, **Open with → Choose another app**, pick **Markdown
viewer**, tick **Always use this app**.

`windows/unregister-file-association.ps1` removes all of it.

### Why it needs a script

A page loaded from `file://` cannot read another local file, so the viewer cannot simply be
pointed at a path on the command line. `windows/open-md.ps1` instead reads the document,
bakes it into a self-contained copy of the viewer in `%TEMP%\md-viewer`, and opens that in
your default browser. Generated pages are reused per document and cleared after a week.

The same script is a usable command on its own:

```powershell
powershell -File windows\open-md.ps1 notes.md
```

## How it works

`index.html` holds the whole viewer — markup, styles and script. It uses two vendored
libraries in `vendor/`, committed so the page works offline:

- [marked](https://github.com/markedjs/marked) 12.0.2 — Markdown to HTML
- [DOMPurify](https://github.com/cure53/DOMPurify) 3.1.6 — sanitises the result, since
  Markdown can contain raw HTML

Links in a document open in a new tab. Relative image paths will not resolve when the page
is opened from `file://`.

`window.mdViewer.open(text, filename)` renders a document without the file picker. That is
the hook `open-md.ps1` uses, and it is the way to drive the viewer from anything else.
