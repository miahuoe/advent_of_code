add_executable(day_01 main.cpp)

target_compile_options(day_01 PRIVATE -Wall -Wextra)

add_custom_target(day_01_run_all)
add_dependencies(day_01_run_all day_01)
add_custom_command(
	TARGET day_01_run_all
	COMMAND ./${name} 1 < ${INPUTS_BUILD_DIR}/day_01_example.txt
	DEPENDS ${name}
	COMMENT "${name} example"
)

add_custom_command(
	TARGET day_01_run_all
	COMMAND ./${name} 1 < ${INPUTS_BUILD_DIR}/day_01_input.txt
	DEPENDS ${name}
	COMMENT "${name} star1"
)

add_custom_command(
	TARGET day_01_run_all
	COMMAND ./${name} 2 < ${INPUTS_BUILD_DIR}/day_01_input.txt
	DEPENDS ${name}
	COMMENT "${name} star2"
)

