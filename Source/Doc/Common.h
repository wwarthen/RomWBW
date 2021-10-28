$define{doc_ver}{3.1 Pre-release}$
$define{doc_product}{RomWBW}$
$ifndef{doc_title}$ $define{doc_title}{Document Title}$ $endif$
$ifndef{doc_author}$ $define{doc_author}{Wayne Warthen}$ $endif$
$define{doc_date}{$date{%d %b %Y}$}$
$ifndef{doc_authmail}$ $define{doc_authmail}{wwarthen@gmail.com}$ $endif$
$define{doc_orgname}{RetroBrew Computers Group}$
$define{doc_orgurl}{www.retrobrewcomputers.org}$

---
# Force pandoc to enable graphics for Logo in title page!
graphics: true
title: $doc_product$ $doc_title$
author: $doc_author$ (mailto:$doc_authmail$)
date: $doc_date$
institution: $doc_orgname$
documentclass: book
classoption:
- oneside
toc: true
toc-depth: 1
numbersections: true
secnumdepth: 1
papersize: letter
geometry:
- top=1.5in
- bottom=1.5in
- left=1.5in
- right=1.5in
# - showframe
# - pass
linestretch: 1.25
colorlinks: true
fontfamily: helvet
fontsize: 12pt
header-includes:
- \setlength{\headheight}{15pt}
- |
  ```{=latex}
  \usepackage{fancyhdr}
  \usepackage{xcolor}
  \usepackage{xhfill}
  \renewcommand*{\familydefault}{\sfdefault}
  \renewcommand{\maketitle}{
    \begin{titlepage}
      \centering
      \par
      \vspace*{0pt}
      \includegraphics[width=\textwidth]{Graphics/Logo.pdf} \par
      \vfill
      \raggedleft
      {\scshape \bfseries \fontsize{48pt}{56pt} \selectfont $doc_product$ \par}
      {\bfseries \fontsize{32pt}{36pt} \selectfont $doc_title$ \par}
      \vspace{24pt}
      {\huge Version $doc_ver$ \\ $doc_date$ \par}
      \vspace{24pt}
      {\large \itshape $doc_orgname$ \\ \href{http://$doc_orgurl$}{$doc_orgurl$} \par}
      \vspace{12pt}
      {\large \itshape $doc_author$ \\ \href{mailto:$doc_authmail$}{$doc_authmail$} \par}
    \end{titlepage}
  }
  \pagestyle{empty}
  ```
include-before:
- \renewcommand{\chaptername}{Section}
- |
  ```{=latex}
  \pagestyle{fancyplain}
  \fancyhf{}
  \lfoot{\small RetroBrew Computing Group ~~ {\xrfill[3pt]{1pt}[cyan]} ~~ \thepage}
  \pagenumbering{roman}
  ```
---

```{=latex}
\clearpage
\pagenumbering{arabic}
\lhead{\fancyplain{}{\nouppercase{\footnotesize \bfseries \leftmark \hfill $doc_product$  $doc_title$}}}
```
