#!/bin/sh
pandoc --include-in-header start.tex *.md -o example.pdf
