#!/bin/sh

# Copyright (c) 2020 Ben Bitdiddle

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

[ -z "$SBBS_DATADIR" ] && { echo 'Set $SBBS_DATADIR first.'; exit 1; }
[ $# -eq 0 ] && { echo "Usage: $0 boardname..."; exit 1; }
for board in $@; do
  if [ -f "$SBBS_DATADIR/html/$board/index" ]; then
    echo "board $board already exists"
  else
      mkdir -p "$SBBS_DATADIR/sexp/$board"
      mkdir -p "$SBBS_DATADIR/html/$board"
      echo "()" > "$SBBS_DATADIR/sexp/$board/index"
      echo '<!DOCTYPE HTML PUBLIC "ISO/IEC 15445:2000//DTD HyperText Markup Language//EN">
<HTML>
<HEAD>
<TITLE>/'"$board"'/ - SchemeBBS</TITLE>
<META content="text/html; charset=UTF-8" http-equiv="Content-Type">
<META name="viewport" content="width=device-width, initial-scale=1.0">
<LINK rel="icon" href="/static/favicon.ico" type="image/png">
<LINK href="/static/styles/default.css" rel="stylesheet" type="text/css"></HEAD>
<BODY>
<H1>'"$board"'</H1>
<P class="nav">frontpage - <A href="/'"$board"'/list">thread list</A> - <A href="#newthread">new thread</A> - <A href="/">return</A></P>
<HR>
<H2 id="newthread">New Thread</H2>
<FORM action="/'"$board"'/post" method="post">
<P class="newthread"><LABEL for="titulus">Headline</LABEL><BR>
<INPUT type="text" name="titulus" id="titulus" size="78" maxlength="78" value=""><BR>
<LABEL for="epistula">Message</LABEL><BR>
<TEXTAREA name="epistula" id="epistula" rows="12" cols="77"></TEXTAREA><INPUT type="hidden" name="ornamentum" value="3b3738ae1c9295d272cec84ecf7af5c8"><BR>
<INPUT type="submit" value="POST"></P>
<FIELDSET class="comment"><LEGEND>do not edit these</LEGEND>
<P><INPUT type="text" name="name" class="name" size="11"><BR>
<TEXTAREA name="message" class="message" rows="1" cols="11"></TEXTAREA></P></FIELDSET></FORM>
<HR>
<P class="footer">bbs.scm + <A href="https://www.gnu.org/software/mit-scheme/">MIT Scheme</A> + <A href="https://mitpress.mit.edu/sites/default/files/sicp/index.html">SICP</A> + Satori Mode</P></BODY></HTML>' > "$SBBS_DATADIR/html/$board/index"
  fi
done
