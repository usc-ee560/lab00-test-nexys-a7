set proj_dir [file dirname [info script]]
create_project test-nexys-a7 $proj_dir -part xc7a100tcsg324-1
add_files $proj_dir/../src/constr_a7.xdc
add_files $proj_dir/../src/test_nexys_a7.v
update_compile_order -fileset sources_1