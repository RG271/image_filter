# Upload BIT File and Configure PL
#
# This script converts top.bit to top.bit.bin,
# uploads it to /lib/firmware/top.bin on the PYNQ-Z2,
# and configures the PYNQ-Z2's PL with it.
#
# To run:  python upload_and_configure.py
#
# op sys:   Windows 11
# language: Python 3.13.5
# author:   RK
# date:     7/24/2025 - 7/27/2025

import os
# import shutil
import subprocess


# Main
def main():
    print('Creating top.bif')
    with open('top.bif', 'w') as dst:
        dst.write('all: { image_filter.runs/impl_1/top.bit }')

    print('Converting BIT to BIT.BIN file by running bootgen')
    status = subprocess.run(
        'bootgen -arch zynq -image top.bif -process_bitstream bin -w',
        capture_output = True,
        shell = True )
    if not b'Bootimage generated successfully' in status.stdout:
        print('ERROR: bootgen failed to convert the BIT file to a BIT.BIN')
        return

    print('Removing top.bif')
    os.remove('top.bif')

    print('Uploading top.bit.bin to /lib/firmware/top.bin on the PYNQ-Z2')
#   shutil.move('image_filter.runs/impl_1/top.bit.bin', 'top.bin')
    subprocess.run(
        'scp image_filter.runs/impl_1/top.bit.bin root@192.168.2.99:/lib/firmware/top.bin',
        shell = True )

    print('Configuring the PL with /lib/firmware/top.bin')
    subprocess.run(
        'ssh root@192.168.2.99 echo top.bin ">/sys/class/fpga_manager/fpga0/firmware"',
        shell = True )

    print('Done.')


if __name__ == '__main__':
    main()
