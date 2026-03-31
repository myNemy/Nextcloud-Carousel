# Refactor & rollback log (Nextcloud Carousel)

Use this file for **architectural refactors** (pipeline changes, transitions, Data URL fallback, I/O, crashes).
Primary rollback tool is **git** (branches, small commits, tags). This document adds quick operational notes.

---

## Change log

<!-- Copy/paste the block below for each work batch -->

### (template)

- **Date:**
- **Goal:**
- **Commit / tag:** (hash or tag name)
- **Files touched:**
- **Rollback:** (`git revert …` / checkout tag / restore option in `config.qml`)
- **Manual tests:** (Plasma, with/without C++ module, large photo list, slow network)

---

## History

### 2025-03-24 — Remove StackView / transitions (single image surface)

- **Goal:** avoid keeping two images in memory for fade/slide/zoom; only one `ImageComponent` child under `imageHost`.
- **Files touched:** `nextcloud-carousel/contents/ui/main.qml`, `nextcloud-carousel/contents/ui/ImageComponent.qml` (comments).
- **Rollback:** `git revert` the commit that introduced this change (or restore a previous `main.qml` from a branch/tag).
- **Notes:** transition-related config keys were **removed** from `main.xml` and the UI (`config.qml`); any old values in the Plasma profile are no longer read by the plugin.
- **Manual tests:** slide switching with C++ enabled and QML fallback; EXIF OSD check; no errors in `journalctl` / `plasmashell` logs.
