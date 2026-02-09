add_executable(day_03 main.cpp)

target_compile_options(day_03 PRIVATE -Wall -Wextra)

add_custom_target(day_03_run_all)
add_dependencies(day_03_run_all day_03)
add_custom_command(
	TARGET day_03_run_all
	COMMAND ./${name} 1 < ${INPUTS_BUILD_DIR}/day_03_example.txt
	DEPENDS ${name}
	COMMENT "${name} star1 example"
)

add_custom_command(
	TARGET day_03_run_all
	COMMAND ./${name} 1 < ${INPUTS_BUILD_DIR}/day_03_input.txt
	DEPENDS ${name}
	COMMENT "${name} star1 input"
)

add_custom_command(
	TARGET day_03_run_all
	COMMAND ./${name} 2 < ${INPUTS_BUILD_DIR}/day_03_example.txt
	DEPENDS ${name}
	COMMENT "${name} star2 example"
)

add_custom_command(
	TARGET day_03_run_all
	COMMAND ./${name} 2 < ${INPUTS_BUILD_DIR}/day_03_input.txt
	DEPENDS ${name}
	COMMENT "${name} star2 input"
)
