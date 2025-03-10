cmake_minimum_required(VERSION 3.14)
set(CMAKE_C_STANDARD 11)

set(ENVSDK $ENV{PLAYDATE_SDK_PATH})
set(PLAYDATE_PROJ_NAME $ENV{PLAYDATE_PROJ_NAME})

if (NOT ${ENVSDK} STREQUAL "")
	# Convert path from Windows
	file(TO_CMAKE_PATH ${ENVSDK} SDK)
else()
	execute_process(
			COMMAND bash -c "egrep '^\\s*SDKRoot' $HOME/.Playdate/config"
			COMMAND head -n 1
			COMMAND cut -c9-
			OUTPUT_VARIABLE SDK
			OUTPUT_STRIP_TRAILING_WHITESPACE
	)
endif()

if (NOT EXISTS ${SDK})
	message(FATAL_ERROR "SDK Path not found; set ENV value PLAYDATE_SDK_PATH")
	return()
endif()

function(generate_compile_flags TARGET_NAME DST_DIR)
    message(STATUS "Generate compile_flags.txt: ${DST_DIR}")
    set(COMPILE_FLAGS "-I${SDK}/C_API\n")
    get_target_property(include_dirs ${TARGET_NAME} INCLUDE_DIRECTORIES)
    foreach(dir IN LISTS include_dirs)
        string(APPEND COMPILE_FLAGS "-I${dir}\n")
    endforeach()
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/compile_flags.txt.in" "${DST_DIR}/compile_flags.txt" @ONLY)
endfunction()

set(CMAKE_CONFIGURATION_TYPES "Debug;Release")
set(CMAKE_XCODE_GENERATE_SCHEME TRUE)

file(GLOB SOURCE RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "src/*.c")

if (NOT "${CMAKE_BUILD_TYPE}" STREQUAL "")
    string(TOLOWER ${CMAKE_BUILD_TYPE} BUILD_TYPE)
else()
    set(BUILD_TYPE "ide")
endif()

message("name: ${PLAYDATE_PROJ_NAME}")
set(PLAYDATE_GAME_NAME ${PLAYDATE_PROJ_NAME}.simulator.${BUILD_TYPE})
set(PLAYDATE_GAME_DEVICE ${PLAYDATE_PROJ_NAME}.device.${BUILD_TYPE})

project(${PLAYDATE_PROJ_NAME} C ASM)

if (TOOLCHAIN STREQUAL "armgcc")
    set(TARGET_NAME ${PLAYDATE_GAME_DEVICE})
    set(BUILD_ARCH "device")
    add_executable(${PLAYDATE_GAME_DEVICE} ${SDK}/C_API/buildsupport/setup.c ${SOURCE})
else()
    set(TARGET_NAME ${PLAYDATE_GAME_NAME})
    set(BUILD_ARCH "simulator")
    add_library(${PLAYDATE_GAME_NAME} SHARED ${SOURCE})

    enable_testing()
    file(GLOB TEST_SOURCE test/*.c)
    add_compile_options(-D UNIT_TEST)
    foreach(test_src IN ITEMS ${TEST_SOURCE})
        get_filename_component(TEST_NAME ${test_src} NAME_WE)
        set(TEST_NAME "${PLAYDATE_PROJ_NAME}_${TEST_NAME}")
        add_executable(${TEST_NAME} ${SOURCE} ${test_src})
        target_include_directories(${TEST_NAME} PUBLIC src)
        add_test(NAME ${test_src} COMMAND ${TEST_NAME})
    endforeach()
endif()

set_target_properties(${TARGET_NAME} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/_output")
target_include_directories(${TARGET_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/include)



# ================================================================================
# packages
message("Check packages")

file(GLOB tmp RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "packages/*")
foreach(package IN LISTS tmp)
    message("Package: ${package}")
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${package}/CMakeLists.txt")
        message(STATUS "Link package")
        add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/${package}")
        get_filename_component(lib_name ${package} NAME)
        list(APPEND LIBRARIES "${lib_name}.${BUILD_ARCH}.${BUILD_TYPE}")
        target_link_libraries(${TARGET_NAME} PUBLIC "${lib_name}.${BUILD_ARCH}.${BUILD_TYPE}")
        target_link_libraries(${TEST_NAME} PUBLIC "${lib_name}.${BUILD_ARCH}.${BUILD_TYPE}")
    else()
        message(STATUS "Include only")
    endif()
    target_include_directories(${TARGET_NAME} PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/${package}/include")
    target_include_directories(${TEST_NAME} PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/${package}/include")
endforeach()
message("Libraries: ${LIBRARIES}")


generate_compile_flags(${TARGET_NAME} ${CMAKE_CURRENT_SOURCE_DIR})


include(${SDK}/C_API/buildsupport/playdate_game.cmake)

