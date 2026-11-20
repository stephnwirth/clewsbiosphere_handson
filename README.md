# CLEWS hands-on session (browser version)

Students run the hands-on R script in their browser with [webR](https://docs.r-wasm.org/webr/latest/),
which is R compiled to WebAssembly. They don't install anything or register anywhere: one link opens
an RStudio-like editor with the script already loaded.

## For students

Open the link from the lecture slides. Then run the script line by line with **Ctrl+Enter**
(**Cmd+Enter** on a Mac). Unlike RStudio, webR's editor sends only the current line (or the
selection), so every command in the script is kept on a single line. The first run takes a minute or two, while the packages and the
~27 MB of data are downloaded into the browser tab. Use a recent Chrome, Firefox, Edge or Safari.

## What is in here

| File | Purpose |
|---|---|
| `hands_on_session.R` | The session script, adapted for the browser (see below) |
| `plot_map.R` | Small base-R map helper, opened as a second tab and loaded with `source()` |
| `data/lpjml_lecture.zip` | LPJmL output (SSP5-8.5, MPI-ESM1-2-HR): `grid`, `terr_area`, and `fpc` cut to 2015–2025 and 2085–2095 |
| `tools/make_link.py` | Writes the data URL into the script and prints the share link |
| `tools/crop_data.R` | How the data was cut from the full `lpjml_output.zip` (`fpc` 2015–2100, 278 MB) |

## Making / updating the link

After you push this repo (or after editing the script):

```bash
python3 tools/make_link.py OWNER/REPO   # e.g. stenzelf/clews-hands-on
git commit -am "update data URL" && git push
```

The script travels inside the link, so if you edit it, generate the link again.
The data is fetched at run time from `raw.githubusercontent.com`, so the repo must be public.

## Differences from the desktop script

- Packages come from pre-built WebAssembly binaries (`pik-piam.r-universe.dev`, `repo.r-wasm.org`),
  not `devtools::install_github()`.
- `fpc` comes as two files, one per period, and is read into `fpc_2020_raw` and `fpc_2090_raw`
  (the full 2015–2100 file needs >1 GB RAM, too much for a browser tab). All results are
  identical to the desktop script on the full data.
- Every command is on one line (webR's Ctrl+Enter runs only the current line).
- Maps are drawn with a small base-R helper `plot_map()` rather than `$plot()` or
  `biospheremetrics::plot_global()`. Those need `raster`/`terra` (GDAL) and a long chain of
  dependencies, each of which is a chance for an install to fail in the browser.

## Fallback

If the browser version fails on the day, the desktop route still works: install R + RStudio,
`install.packages(c("magrittr", "lpjmlkit"), repos = c("https://pik-piam.r-universe.dev", "https://cloud.r-project.org"))`,
download `data/lpjml_lecture.zip` into the working directory and skip the `download.file()` line.
