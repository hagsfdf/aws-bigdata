#!/bin/bash
for i in *.md

do
    name=$(echo "$i" | cut -f 1 -d '.')
    pandoc $i -o pdfVer/$name.pdf
done
