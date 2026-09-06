# md-viewer

**[markdown.informededucation.com](https://markdown.informededucation.com)**

A single HTML page that opens a Markdown file and renders it for reading. No server, no
build step, no network — the file is read in your browser and never leaves it.

Use it on the web at the link above, or open `site/index.html` from a copy of this
repository. Both are the same file.

## Use it

Open the site, or `site/index.html` from a local copy, then either press **Choose a file**
or drop a `.md` file anywhere on the page. The file is read in the browser tab; nothing is
uploaded anywhere.

`site/sample.md` is included so you can see what it looks like.

## What it renders

Standard Markdown plus the GitHub extensions that show up in notes and reports: tables,
task lists, strikethrough and fenced code. Documents with three or more subheadings get a
contents rail that marks the section you are reading. Wide tables scroll on their own.

Dark mode follows the operating system setting.

## Saving a PDF

**Save as PDF** in the top bar, or Ctrl+P, prints the document as a report rather than a
screenshot of a web page:

- A title page carrying the document's own first heading, the filename, the word count and
  the date.
- A contents page for documents with three or more subheadings. Each entry hangs its
  markdown heading level in the margin, so the structure is legible at a glance.
- Headings are never stranded at the foot of a page, paragraphs keep three lines either
  side of a break, and table headers repeat when a table runs on.
- Code blocks wrap instead of being clipped at the page edge, and wide tables print in
  full rather than scrolling.
- A4 with 18-20mm margins. Page numbers come from the browser's own print header and
  footer settings, which CSS cannot control.

The title appears on the cover and is then suppressed in the body, so it does not print
twice.

## Opening .md files straight from Windows Explorer

`windows/` sets md-viewer up as a program Windows can open Markdown files with, including
files kept in WSL.

```powershell
powershell -ExecutionPolicy Bypass -File "\\wsl.localhost\Ubuntu\home\<you>\projects\md-viewer\windows\install.ps1"
```

That copies the viewer to `%LOCALAPPDATA%\md-viewer` and registers a ProgID under
`HKEY_CURRENT_USER` — no admin rights, nothing machine-wide. The Windows copy means
opening a document does not have to wait for WSL to start or read the viewer back across
the WSL filesystem.

Windows does not allow a script to seize a file type, so make it the default yourself,
once: right-click any `.md` file, **Open with → Choose another app**, pick **Markdown
viewer**, tick **Always use this app**.

The installed copy refreshes itself: `windows/hooks/post-commit` re-runs the file copy on
every commit and merge, so the association always opens the current viewer rather than
drifting behind the repository. Install the hooks in a fresh clone with:

```bash
cp windows/hooks/post-commit .git/hooks/post-commit
cp windows/hooks/post-commit .git/hooks/post-merge
chmod +x .git/hooks/post-commit .git/hooks/post-merge
```

The hook never blocks a commit: if Windows or WSL interop is unavailable it skips quietly.
Run `install.ps1` by hand any time to force a refresh. Your default survives either way —
Windows binds that choice to the ProgID, not to the path behind it.

To remove everything: run `unregister-file-association.ps1` from the installed copy, then
delete `%LOCALAPPDATA%\md-viewer`.

`register-file-association.ps1` on its own points the association at whichever folder it
sits in, if you would rather run straight from the repository.

### Why it needs a script

A page loaded from `file://` cannot read another local file, so the viewer cannot simply be
pointed at a path on the command line. `windows/open-md.ps1` instead reads the document,
bakes it into a self-contained copy of the viewer in `%TEMP%\md-viewer`, and opens that in
your default browser. Generated pages are reused per document and cleared after a week.

The same script is a usable command on its own:

```powershell
powershell -File windows\open-md.ps1 notes.md
```

## Repository layout

| Path | What it is |
| --- | --- |
| `site/` | Everything that is published. Nothing else is. |
| `windows/` | Scripts that make `.md` files open in this viewer from Explorer |
| `wrangler.jsonc` | Deploy config — Cloudflare serves `site/` from its edge |

Pushing to `main` deploys the site. Only `site/` is published, so the repository can hold
things the website should not serve.

## How it works

`site/index.html` holds the whole viewer — markup, styles and script. It uses two vendored
libraries in `site/vendor/`, committed so the page works offline:

- [marked](https://github.com/markedjs/marked) 12.0.2 — Markdown to HTML
- [DOMPurify](https://github.com/cure53/DOMPurify) 3.1.6 — sanitises the result, since
  Markdown can contain raw HTML

## What it will not do

- **Load anything from the internet.** A remote image in a document would tell its host
  that you opened that document, and when. Those are replaced by a placeholder you can
  click if you want it. Links you click are your choice and open normally.
- **Apply CSS from a document.** A `<style>` block or `style` attribute in the source
  applies to the whole page, so a document could hide or cover the viewer's own interface.
  Both are dropped.

Relative links and images resolve against the document's own folder when it is opened
through the Windows association, which passes that folder to the viewer. The file picker
and drag-and-drop cannot know it — the browser does not tell the page where a chosen file
came from — so relative paths stay unresolved there.

`window.mdViewer.open(text, filename, baseUri)` renders a document without the file picker.
The optional `baseUri` is the folder the document came from. That is
the hook `open-md.ps1` uses, and it is the way to drive the viewer from anything else.
