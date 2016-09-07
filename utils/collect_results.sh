#!/bin/sh

`dirname "$0"`/collect_results.pl "$@" | less -SR
