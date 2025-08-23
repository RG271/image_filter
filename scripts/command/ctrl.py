# Command Zynq PL Firmware Control Utility
#
# This command-line utility commands the Zynq PL's firmware
# over a serial line.  The serial data is processed by the
# Debug Access Port (DAP) module in the firmware.
#
# References:
# 1. https://docs.python.org/3/library/argparse.html
#
# author: RK
# date:   8/16/2025 - 8/23/2025

import argparse
import debug_access_port


# Main
def main():
    parser = argparse.ArgumentParser(
                    prog='python ctrl.py',
                    description='Command-line utility to control Zynq PL firmware',
                    epilog='(c)2025 Richard Kaminsky')

    parser.add_argument( '-b', '--baud',
                         metavar = 'BAUD_RATE',
                         type = int,
                         default = 921600,
                         help = 'Baud rate (e.g., 921600)' )

    parser.add_argument( '--dcm-clear', dest = 'dcmClear',
                         help = 'Clear the debug capture buffer',
                         action = 'store_true' )

    parser.add_argument( '--dcm-dec', dest = 'dcmDec',
                         metavar = ('PORT', 'DECIMATION'),
                         nargs = 2,
                         type = int,
                         help = 'Set decimation on DCM port (0..5) to 1..65535 or 0 to disable the port' )

    parser.add_argument( '--dcm-dump', dest = 'dcmDump',
                         metavar = 'FILENAME',
                         type = str,
                         help = "Download DCM's data, and write it to a binary file" )

    parser.add_argument( '-p', '--port',
                         type = str,
                         default = 'COM7',
                         help = 'Serial port (e.g., COM7)' )

    parser.add_argument( '-s', '--status',
                         help = "Print the firmware modules' status",
                         action = 'store_true' )

    parser.add_argument( '-v', '--verbose',
                         help = 'Print debugging messages',
                         action = 'store_true' )

    parser.add_argument( '-l', '--leds',
                         metavar = 'MASK',
                         type = int,
                         help = "LEDs' mask (0..15)" )

    parser.add_argument( '--LD4',
                         metavar = 'MASK',
                         type = int,
                         help = "RGB LED LD4's mask (0..7)" )

    parser.add_argument( '--LD5',
                         metavar = 'MASK',
                         type = int,
                         help = "RGB LED LD5's mask (0..7)" )

    print()
    args = parser.parse_args()

    with debug_access_port.Dap(args.port, verbose = args.verbose) as dap:
        if args.status:
            dap.printStatus()
        if args.leds != None:
            dap.write(dap.basicio.MODULE, 3, args.leds)
        if args.LD4 != None:
            dap.write(dap.basicio.MODULE, 4, args.LD4)
        if args.LD5 != None:
            dap.write(dap.basicio.MODULE, 5, args.LD5)
        if args.dcmClear:
            dap.dcm.clear()
        if args.dcmDec != None:
            p, d = args.dcmDec
            dap.dcm.setDecimation(p, d)
        if args.dcmDump != None:
            data = dap.dcm.dump(args.dcmDump)
            print(f'Wrote {len(data)} 32-bit words to binary file: {args.dcmDump}')


if __name__ == '__main__':
    main()
