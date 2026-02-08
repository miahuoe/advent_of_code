cmake_minimum_required(VERSION 3.20)
project(AOC2024 LANGUAGES CXX)

set(PROJECT_AUTHOR "Michał Czarnecki")

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(INPUTS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/inputs")
set(INPUTS_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/inputs")
set(RUN_ALL_TARGETS "")
set(INPUT_BUILD_FILES "")

file(GLOB DAYS_DIRS CONFIGURE_DEPENDS "day_*")
file(GLOB INPUT_FILES "${INPUTS_DIR}/*")
file(MAKE_DIRECTORY "${INPUTS_BUILD_DIR}")

add_custom_target(run_all)

foreach(f ${INPUT_FILES})
	get_filename_component(filename ${f} NAME)
	set(dst "${INPUTS_BUILD_DIR}/${filename}")
	add_custom_command(
		OUTPUT "${dst}"
		COMMAND ${CMAKE_COMMAND} -E create_symlink ${f} ${dst}
		DEPENDS ${f}
		COMMENT "Copying ${f} to ${dst}"
		VERBATIM
	)
	list(APPEND INPUT_BUILD_FILES ${dst})
endforeach()

add_custom_target(copy_inputs ALL DEPENDS ${INPUT_BUILD_FILES})
add_dependencies(run_all copy_inputs)

foreach(dir ${DAYS_DIRS})
	get_filename_component(name "${dir}" NAME)
	if(IS_DIRECTORY ${dir})
		add_subdirectory(${dir})
		list(APPEND RUN_ALL_TARGETS ${name}_run_all)
		add_dependencies(${name} copy_inputs)
	endif()
endforeach()

add_dependencies(run_all ${RUN_ALL_TARGETS})

