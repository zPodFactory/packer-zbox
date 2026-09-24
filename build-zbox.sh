#!/bin/sh

rm -rf output-zbox-*

packer build \
    --var-file="zbox-builder.json" \
    --var-file="zbox-13.7.json" \
    zbox.json

chmod 644 output-zbox-*/*.ova
