# Read/Write a 128x128 24-bit Color BMP File
#
# The file image_in.bmp is a 24-bit color BMP file that
# was saved with its colorspace options.
#
# 7/30/2025 RK



def main():
    with open('image_in.bmp', 'rb') as src:
        data = bytearray(src.read())
    assert len(data) == 49290, 'Incorrect 128x128 24-bit BMP file format'
    print(f'data = {type(data)} of {len(data)} bytes')
    for y in range(0, 30):
        for x in range(0, 10):
            # Write RGB value to pixel x,y
            # where 0,0 is in the upper left corner
            i = 0x8A + 3 * x + (3 * 128) * (127 - y)
            data[i]   = 0      # blue
            data[i+1] = 0xFF   # green
            data[i+2] = 0      # red
    with open('image_out.bmp', 'wb') as dst:
        dst.write(data)



if __name__ == '__main__':
    main()
