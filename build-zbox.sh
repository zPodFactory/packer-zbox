#!/bin/sh

rm -rf output-zbox-*

packer build \
    --var-file="zbox-builder.json" \
    --var-file="zbox-12.11.json" \
    zbox.json
