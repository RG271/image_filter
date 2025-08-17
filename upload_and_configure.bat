@echo off
rem  Convert .\image_filter.runs\impl_1\top.bit to top.bit.bin,
rem  upload top.bit.bin to PYNQ-Z2 and rename as top.bin, and
rem  configure the PL with top.bin .
rem
rem  7/24/2025 - 7/26/2025  RK

python upload_and_configure.py
pause