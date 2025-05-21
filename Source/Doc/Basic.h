$define{doc_ver}{Version 3.6}$
$define{doc_product}{RomWBW}$
$define{file_root}{https://github.com/wwarthen/RomWBW/raw/master}$
$define{doc_root}{$file_root$/Doc}$
$ifndef{doc_title}$ $define{doc_title}{Document Title}$ $endif$
$ifndef{doc_author}$ $define{doc_author}{Wayne Warthen}$ $endif$
$define{doc_date}{$date{%d %b %Y}$}$
$ifndef{doc_authmail}$ $define{doc_authmail}{wwarthen@gmail.com}$ $endif$
$define{doc_orgname}{RetroBrew Computers Group}$
$define{doc_orgurl}{www.retrobrewcomputers.org}$
$define{doc_intro}{[RomWBW Introduction]($doc_root$/RomWBW Introduction.pdf)}$
$define{doc_user}{[RomWBW User Guide]($doc_root$/RomWBW User Guide.pdf)}$
$define{doc_sys}{[RomWBW System Guide]($doc_root$/RomWBW System Guide.pdf)}$
$define{doc_apps}{[RomWBW Applications]($doc_root$/RomWBW Applications.pdf)}$
$define{doc_catalog}{[RomWBW Disk Catalog]($doc_root$/RomWBW Disk Catalog.pdf)}$
$define{doc_hardware}{[RomWBW Hardware]($doc_root$/RomWBW Hardware.pdf)}$

---
title: $doc_product$ $doc_title$
subtitle: $doc_ver$
author: $doc_author$ ([$doc_authmail$](mailto:$doc_authmail$))
date: $doc_date$
institution: $doc_orgname$
papersize: letter
geometry:
- top=1.5in
- bottom=1.5in
- left=1.5in
- right=1.5in
# - showframe
# - pass
fontsize: 12pt
# linestretch: 1.25
colorlinks: true
# sansfont: helvetic
sansfont: roboto
# sansfont: bera
# sansfont: DejaVuSans
# sansfont: arial
monofont: roboto-mono
# monofont: bera
# monofont: inconsolata
# monofont: DejaVuSansMono
monofontoptions: 'Scale=0.75'
header-includes:
- |
  ```{=latex}
  \renewcommand*{\familydefault}{\sfdefault}
  ```
---

```{=gfm}
**$doc_product$ $doc_title$** \
$doc_ver$ \
$doc_author$  ([$doc_authmail$](mailto:$doc_authmail$)) \
$doc_date$

```

```{=dokuwiki}
**$doc_product$ $doc_title$**\\
$doc_ver$\\
$doc_author$  <$doc_authmail$>\\
$doc_date$\\

```
