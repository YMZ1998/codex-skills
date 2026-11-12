#!/usr/bin/env python3
"""Classify Office files by magic bytes in a DLP / transparent-encryption environment.

Usage:
    python probe_encryption.py FILE [FILE ...]
    python probe_encryption.py --json FILE [FILE ...]
    python probe_encryption.py --expect-plain OUTPUT.docx

Exit codes: 0 = all checks passed, 1 = at least one assertion failed, 2 = usage error.

The `%TSD-` prefix means the file is an enterprise transparent-encryption container,
not an OLE .doc and not an OOXML .docx. Only an authorized local Word process can
read it; python-docx, editor_sdk and conversion tools cannot.
"""

import argparse
import json
import os
import sys

MAGIC = [
    (b"%TSD-", "tsd-encrypted",
     "Enterprise transparent-encryption (DLP) container; read via Word COM only"),
    (b"PK\x03\x04", "plain-ooxml",
     "Plain OOXML ZIP package (docx/xlsx/pptx); safe for python-docx"),
    (b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1", "ole-compound",
     "OLE compound file (real .doc/.xls/.ppt); normal Office tooling applies"),
    (b"{\\rtf", "rtf", "Rich Text Format"),
    (b"%PDF-", "pdf", "PDF document"),
]


def classify(path):
    rec = {"path": os.path.abspath(path), "exists": False}
    if not os.path.isfile(path):
        rec.update(kind="missing", note="File not found",
                   head_hex="", head_ascii="", size=0)
        return rec

    with open(path, "rb") as fh:
        head = fh.read(16)

    rec["exists"] = True
    rec["size"] = os.path.getsize(path)
    rec["head_hex"] = " ".join("%02x" % b for b in head[:8])
    rec["head_ascii"] = "".join(
        chr(b) if 32 <= b < 127 else "." for b in head[:8]
    )

    for prefix, kind, note in MAGIC:
        if head.startswith(prefix):
            rec["kind"] = kind
            rec["note"] = note
            return rec

    rec["kind"] = "unknown"
    rec["note"] = "Unrecognised header; do not assume it is an Office file"
    return rec


def main():
    parser = argparse.ArgumentParser(
        description="Classify Office files by their first bytes."
    )
    parser.add_argument("paths", nargs="+", help="Files to inspect")
    parser.add_argument("--json", action="store_true",
                        help="Emit JSON instead of a text table")
    parser.add_argument("--expect-plain", action="store_true",
                        help="Assert every file is a plain OOXML ZIP (PK\\x03\\x04)")
    args = parser.parse_args()

    results = [classify(p) for p in args.paths]

    if args.json:
        print(json.dumps(results, ensure_ascii=False, indent=2))
    else:
        for rec in results:
            print("[%-14s] %-9s size=%-10s head=%s  %s" % (
                rec["kind"], rec["head_ascii"],
                rec["size"], rec["head_hex"], rec["path"]
            ))
            print("                 %s" % rec["note"])

    if args.expect_plain:
        bad = [r for r in results if r["kind"] != "plain-ooxml"]
        if bad:
            kinds = ", ".join(sorted({r["kind"] for r in bad}))
            print("\nFAIL: expected plain OOXML, got: %s" % kinds)
            for rec in bad:
                print("  %s  (head=%s)" % (rec["path"], rec["head_ascii"]))
            print("\nIf the head is %TSD-, the DLP client re-encrypted the file. "
                  "Regenerate the deliverable with python-docx instead of Word.")
            return 1
        print("\nOK: all files are plain OOXML ZIP packages.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
