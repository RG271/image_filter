# PYNQ-Z2 Top-Level Timing Constraints
#
# 9/29/2022 - 10/11/2022  RK

## HDMI Source Clocks
## set_false_path -from [get_clocks clk_fpga_0] -to [get_clocks -of_objects [get_pins base_wrapper_i/base_i/hdmi_source_clocks/inst/mmcm_adv_inst/CLKOUT0]]
#set_clock_groups -asynchronous  \
#    -group {clk_fpga_0}  \
#    -group {clk_out1_base_clk_wiz_0_0 clk_out2_base_clk_wiz_0_0}

## HDMI Sink Clock
#create_clock -period 8.334 [get_ports hdmi_in_clk_p]

## HDMI Source SerialClk
#create_clock -period 2.694 [get_pins base_wrapper_i/base_i/rgb2dvi/U0/SerialClk]
