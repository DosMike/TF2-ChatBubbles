#!/bin/bash
fname="spsauce/"$(ls -r1A spsauce | grep '^SPSauce-.*-all\.jar$' | head -n1)
if [[ -f $fname ]]; then
  java -jar $fname $@
fi
