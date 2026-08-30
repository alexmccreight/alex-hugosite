# alexmccreight.com

Personal academic site. A single static page — no framework, no build step.

    site/
      index.html    the whole page
      style.css     styles (light + dark via prefers-color-scheme)
      photo.jpg
      _redirects    301s from the old Hugo site's URLs

Netlify publishes `site/` directly; there is no build command. To preview
locally, serve that directory over HTTP (opening the file directly will not
load the stylesheet):

    cd site && python3 -m http.server 8788

## Adding a publication

Copy an existing `<article class="paper">` block in `index.html` and edit it.
Entries are ordered newest first. Wrap your own name in `<strong>` in the
author list. The `.chips` links and the `<details>` abstract are both optional.
