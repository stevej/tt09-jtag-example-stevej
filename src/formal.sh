#!/bin/bash

set -ex

sby -f formal.sby -T bmc
sby -f formal.sby -T prove
sby -f formal.sby -T cover
