# 7-Zip this project
#
# To run:  python archive.py
#
# op sys:   Windows 11
# language: Python 3.13.5
# author:   RK
# date:     7/27/2025 - 8/16/2025

import subprocess
import time


# Main
def main():
    PROJECT_DIR = r'..\image_filter'
    ARCHIVE_FN  = PROJECT_DIR + time.strftime(' %Y-%m-%d %H_%M.7z')

    print(f'\nArchiving "{PROJECT_DIR}" to "{ARCHIVE_FN}"')
    subprocess.run( f'7z a "{ARCHIVE_FN}" "{PROJECT_DIR}"', shell = True )

    print()


if __name__ == '__main__':
    main()
