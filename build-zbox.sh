#!/bin/sh

rm -rf output-zbox-*

packer build \
    --var-file="zbox-builder.pkrvars.hcl" \
    --var-file="zbox-12.10.pkrvars.hcl" \
    zbox.pkr.hcl
