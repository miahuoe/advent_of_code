add_executable(day_04 main.cpp)

target_compile_options(day_04 PRIVATE -Wall -Wextra)

add_custom_target(day_04_run_all)
add_dependencies(day_04_run_all day_04)
add_custom_command(
	TARGET day_04_run_all
	COMMAND ./${name} 1 < ${INPUTS_BUILD_DIR}/day_04_example.txt
	DEPENDS ${name}
	COMMENT "${name} star1 example"
)

add_custom_command(
	TARGET day_04_run_all
	COMMAND ./${name} 1 < ${INPUTS_BUILD_DIR}/day_04_input.txt
	DEPENDS ${name}
	COMMENT "${name} star1 input"
)

add_custom_command(
	TARGET day_04_run_all
	COMMAND ./${name} 2 < ${INPUTS_BUILD_DIR}/day_04_example.txt
	DEPENDS ${name}
	COMMENT "${name} star1 example"
)

add_custom_command(
	TARGET day_04_run_all
	COMMAND ./${name} 2 < ${INPUTS_BUILD_DIR}/day_04_input.txt
	DEPENDS ${name}
	COMMENT "${name} star1 input"
)
