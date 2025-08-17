# Upload and make the C++ project ctrl
#
# To run:  python upload_and_make_ctrl.py
#
# op sys:   Windows 11
# language: Python 3.13.5
# author:   RK
# date:     7/27/2025 - 7/28/2025

import subprocess
import time


# Main
def main():
    LOCAL_APP_DIR  = 'ctrl'
    REMOTE_CPP_DIR = '/home/xilinx/Documents/c++'
    REMOTE_APP_DIR = REMOTE_CPP_DIR + '/ctrl'
    REMOTE_IP_ADDR = '192.168.2.99'
    REMOTE_ROOT    = 'root@' + REMOTE_IP_ADDR
    REMOTE_USER    = 'xilinx@' + REMOTE_IP_ADDR

    print('\nSetting date and time')
    subprocess.run(
        f"ssh {REMOTE_ROOT} date -s '{time.strftime('%Y-%m-%d %H:%M:%S')}'",
        shell = True )

    print(f'\nUploading {LOCAL_APP_DIR} to {REMOTE_APP_DIR} on the PYNQ-Z2')
    subprocess.run(
        f'ssh {REMOTE_USER} rm -rf {REMOTE_APP_DIR}/*',
        shell = True )
    subprocess.run(
        f'scp -r {LOCAL_APP_DIR} {REMOTE_USER}:{REMOTE_CPP_DIR}',
        shell = True )

    print('\nMake project ctrl')
    subprocess.run(
        f'ssh {REMOTE_USER} make -C {REMOTE_APP_DIR}',
        shell = True )

    print()


if __name__ == '__main__':
    main()
