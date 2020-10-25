#!/usr/bin/env bash
a=("teste 1" "teste 2" "teste 3")
b="teste 1"
[[ $b =~ ${a} ]] && echo "true" || echo "false"
