$include{"Basic.h"}$

---
# Force pandoc to enable graphics for Logo in title page!
graphics: true
documentclass: book
classoption:
- oneside
toc: true
toc-depth: 2
numbersections: true
secnumdepth: 2
header-includes:
- |
  ```{=latex}
  \setlength{\headheight}{15pt}
  \usepackage{fancyhdr}
  \usepackage{xcolor}
  \usepackage{xhfill}
  \usepackage{tocloft}
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
      {\huge $doc_ver$ \par}
      \vspace{12pt}
      {\large Updated $doc_date$ \par}
      \vspace{24pt}
      {\large \itshape $doc_orgname$ \\ \href{http://$doc_orgurl$}{$doc_orgurl$} \par}
      \vspace{12pt}
      {\large \itshape $doc_author$ \\ \href{mailto:$doc_authmail$}{$doc_authmail$} \par}
    \end{titlepage}
  }
  \pagestyle{empty}
  ```
include-before:
# - \renewcommand{\chaptername}{Section}
- |
  ```{=latex}
  \pagestyle{fancyplain}
  \fancyhf{}
  \lhead{\fancyplain{}{\nouppercase{\bfseries \leftmark \hfill $doc_product$  $doc_title$}}}
  \lfoot{\small RetroBrew Computing Group ~~ {\xrfill[3pt]{1pt}[cyan]} ~~ \thepage}
  \pagenumbering{roman}
  ```
---

```{=latex}
\clearpage
\pagenumbering{arabic}
```
