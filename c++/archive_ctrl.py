# 7-Zip the ctrl project
#
# To run:  python archive_ctrl.py
#
# op sys:   Windows 11
# language: Python 3.13.5
# author:   RK
# date:     7/27/2025

import subprocess
import time


# Main
def main():
    APP_DIR    = 'ctrl'
    ARCHIVE_FN = APP_DIR + time.strftime(' %Y-%m-%d %H_%M.7z')

    print(f'\nArchiving "{APP_DIR}" to "{ARCHIVE_FN}"')
    subprocess.run( f'7z a "{ARCHIVE_FN}" "{APP_DIR}"', shell = True )

    print()


if __name__ == '__main__':
    main()
