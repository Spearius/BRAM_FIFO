
# BRAM FIFO - Vivado Project Creation Script

# Get the folder containing this Tcl script
set script_dir [file dirname [file normalize [info script]]]

# Get the main repository folder
set project_root [file dirname $script_dir]

# Set the new Vivado project location
set project_dir [file join $project_root generated_project]

# Create the Vivado project
create_project bram_fifo_auto $project_dir -part xc7z010clg400-1

# Add FIFO design source
add_files -fileset sources_1 [file join $project_root src sc_fifo.sv]

# Add FIFO testbench
add_files -fileset sim_1 [file join $project_root sim tb_sc_fifo.sv]

# Add Python-generated test data
add_files -fileset sim_1 [file join $project_root sim input_data.txt]

# Configure the source files as SystemVerilog
set_property file_type SystemVerilog [get_files [file join $project_root src sc_fifo.sv]]
set_property file_type SystemVerilog [get_files [file join $project_root sim tb_sc_fifo.sv]]

# Set top modules
set_property top sc_fifo [get_filesets sources_1]
set_property top tb_sc_fifo [get_filesets sim_1]

# Set simulation runtime
set_property xsim.simulate.runtime 10us [get_filesets sim_1]

# Save project configuration
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "BRAM FIFO Vivado project created successfully."