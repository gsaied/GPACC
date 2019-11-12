set_property SRC_FILE_INFO {cfile:/home/gsaied/Desktop/verilog_rtl/pool/comb_pool/pool.xdc rfile:../../../pool.xdc id:1} [current_design]
set_property src_info {type:XDC file:1 line:1 export:INPUT save:INPUT read:READ} [current_design]
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]
set_property src_info {type:XDC file:1 line:3 export:INPUT save:INPUT read:READ} [current_design]
set_input_delay -clock clk -max 4.000 [all_inputs]
set_property src_info {type:XDC file:1 line:4 export:INPUT save:INPUT read:READ} [current_design]
set_input_delay -clock clk -min 1.000 [all_inputs]
set_property src_info {type:XDC file:1 line:5 export:INPUT save:INPUT read:READ} [current_design]
set_output_delay -clock clk -max 9.000 [all_outputs]