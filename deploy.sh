#!/bin/sh

hugo && rsync -avz --delete public/ pwt5ca@patrickwthomas.net:~/public_html/
