add_executable(day_02 main.cpp)

target_compile_options(day_02 PRIVATE -Wall -Wextra)

add_custom_target(day_02_run_all)
add_dependencies(day_02_run_all day_02)
add_custom_command(
	TARGET day_02_run_all
	COMMAND ./${name} 1 < ${INPUTS_BUILD_DIR}/day_02_example.txt
	DEPENDS ${name}
	COMMENT "${name} star1 example"
)

add_custom_command(
	TARGET day_02_run_all
	COMMAND ./${name} 1 < ${INPUTS_BUILD_DIR}/day_02_input.txt
	DEPENDS ${name}
	COMMENT "${name} star1"
)

add_custom_command(
	TARGET day_02_run_all
	COMMAND ./${name} 2 < ${INPUTS_BUILD_DIR}/day_02_example.txt
	DEPENDS ${name}
	COMMENT "${name} star2 example"
)

add_custom_command(
	TARGET day_02_run_all
	COMMAND ./${name} 2 < ${INPUTS_BUILD_DIR}/day_02_input.txt
	DEPENDS ${name}
	COMMENT "${name} star2"
)

