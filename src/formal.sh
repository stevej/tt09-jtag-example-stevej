#!/bin/bash

set -ex

sby -f formal_bmc.sby
sby -f formal_prove.sby
sby -f formal_cover.sby
