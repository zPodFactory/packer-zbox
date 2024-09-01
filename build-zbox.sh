#!/bin/sh

rm -rf output-zbox-*

packer build \
    --var-file="zbox-builder.json" \
    --var-file="zbox-12.7.json" \
    zbox.json
