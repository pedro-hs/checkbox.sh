#!/bin/bash
let upperBound=$1
echo "check [,  ${upperBound} iterations"
let i=0
time while [ $i -lt ${upperBound} ] ; do let i++ ; done

echo; echo;
echo "check [[, ${upperBound} iterations"
let i=0
time while [[ $i < ${upperBound} ]] ; do let i++ ; done
