#!/bin/sh

rm -rf output-zbox-* 

packer build \
    --var-file="zbox-builder.json" \
    --var-file="zbox-11.5.json" \
    zbox.json
