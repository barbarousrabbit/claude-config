---
name: markitdown
description: >
  Use when READING, extracting, searching, or summarising the contents of any
  document file — .pdf, .docx, .xlsx, .xls, .pptx, .msg (Outlook), .epub,
  .html, .csv, .json, .xml, or .zip archives. Converts the file to Markdown on
  disk with Microsoft's MarkItDown so the binary never enters the context
  window, then reads only the parts actually needed. Use whenever asked to
  read, analyse, review, summarise, compare, or pull data out of a document,
  and whenever a document read would otherwise be large. Do NOT use for
  CREATING or editing these formats (use the pdf / docx / xlsx / pptx skills),
  and do NOT rely on it for scanned image-only PDFs or photographs — it
  extracts no text from those, see the empty-output guard below.
user-invocable: true
license: MIT
---

# MarkItDown — read documents without burning context

Reading a document binary directly is the expensive path: a PDF enters the
context window as page images, costs tens of thousands of tokens, and is
re-sent on every subsequent turn. Converting it to Markdown first costs
nothing and the text stays a fraction of the size.

## The rule

**Never send a document binary into context.** Convert to Markdown on disk,
then read the Markdown — and for anything long, read it selectively.

Only exception: the task genuinely needs the *visual* page (checking a
signature, a stamp, a chart's appearance, a layout complaint). Then read the
page image deliberately, and only the page you need.

## Workflow

```bash
markitdown report.pdf -o report.md     # 1. convert
wc -c report.md                        # 2. how big is it actually?
```

Then pick based on step 2:

- **Small (under ~40 KB)** — just Read the .md.
- **Large** — do NOT read it whole. Grep for structure first
  (`grep -n '^#' report.md` for headings), then Read with `offset`/`limit`
  around the hits. Grep for the specific thing you were asked about.
- **You only need one fact** — grep for it and never read the rest.

Write the .md next to the source, or into the scratchpad if it is throwaway.
Keep it: re-reading a converted file later is free, re-converting is not.

## Empty output means SCANNED, not empty — MANDATORY check

MarkItDown fails **silently** on files with no text layer: exit code 0, no
warning, zero bytes out. Verified locally on this machine (2026-08-10,
markitdown 0.1.7): an image-only PDF and a standalone PNG both produced
**0 bytes** with no error.

So after every convert:

```bash
[ -s out.md ] || echo "EMPTY -> scanned or image-only, do NOT report as blank"
```

If the output is empty or implausibly short for the page count, the document
is a scan. **Never** tell the user the document is empty or has no content —
that is the wrong conclusion and it looks like a confident answer. Say it is
image-only and needs OCR, then take the fallback.

## OCR fallback (scanned PDFs, photos)

MarkItDown has no built-in OCR in this install. Options, cheapest first:

1. **Tesseract** — `pip install pytesseract` plus the Tesseract binary
   (Windows: `winget install UB-Mannheim.TesseractOCR`). Then use the OCR
   recipe in the `pdf` skill (pdf2image + pytesseract).
2. **Azure Document Intelligence** — `pip install 'markitdown[az-doc-intel]'`,
   then `markitdown file.pdf -d -e "<endpoint>"`. Best quality on forms and
   tables, needs an Azure endpoint and sends the document to Microsoft.
   Do not use on personnel or client files without asking first.
3. **Read the page image directly** — fine for one or two pages, not for a
   50-page scan.

## Verified format behaviour

Tested on this machine, markitdown 0.1.7:

| Input | Result |
|---|---|
| Text-layer PDF | Clean Markdown, headings and paragraphs preserved |
| Image-only PDF | **0 bytes, silent** — see guard above |
| Standalone PNG/JPG | **0 bytes, silent** — EXIF/OCR path needs extra setup |
| .xlsx | Proper Markdown tables, one `## Sheet` per worksheet |
| .docx / .pptx / .msg | Supported via installed extras |

Installed extras: `pdf, docx, pptx, xlsx, xls, outlook`. Audio transcription,
YouTube, and Azure groups were deliberately not installed — add one only if a
task actually needs it.

## Batch

```bash
for f in *.pdf; do markitdown "$f" -o "${f%.pdf}.md"; done
find . -name '*.pdf' -exec sh -c 'markitdown "$1" -o "${1%.pdf}.md"' _ {} \;
```

For many files, convert them all first, then grep across the .md set — that
is one cheap pass instead of N expensive reads.

## Python API

```python
from markitdown import MarkItDown
md = MarkItDown(enable_plugins=False)
print(md.convert("test.xlsx").text_content)
```

## Not this skill's job

| Task | Use instead |
|---|---|
| Create / edit / merge / split / fill forms in a PDF | `pdf` skill |
| Write or edit .docx, tracked changes | `docx` skill |
| Write or edit spreadsheets, formulas | `xlsx` skill |
| Build a slide deck | `pptx` / `revealjs` skill |
| Query tabular data at scale | `duckdb-query` skill |

MarkItDown is one-way: document in, Markdown out. It never writes the source
format back.
