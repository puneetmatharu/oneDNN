# ******************************************************************************
# Copyright 2020-2025 Arm Limited and affiliates.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ******************************************************************************

if(acl_cmake_included)
    return()
endif()
set(acl_cmake_included true)
include("cmake/options.cmake")

if(NOT DNNL_TARGET_ARCH STREQUAL "AARCH64")
    return()
endif()

if(NOT DNNL_AARCH64_USE_ACL)
    return()
endif()

find_package(ACL REQUIRED)

set(ACL_MINIMUM_VERSION "24.11.1")

set(ACL_LAST_VERSION_BEFORE_GRAPH_LIB_DEPRECATED "25.01")

if(ACL_FOUND)
    file(GLOB_RECURSE ACL_VERSION_FILE ${ACL_INCLUDE_DIR}/*/arm_compute_version.embed)
    if ("${ACL_VERSION_FILE}" STREQUAL "")
        message(WARNING
            "Build may fail. Could not determine ACL version.\n"
            "Supported ACL versions:\n"
            "- minimum required is ${ACL_MINIMUM_VERSION}\n"
        )
    else()
        file(READ ${ACL_VERSION_FILE} ACL_VERSION_STRING)
        string(REGEX MATCH "v([0-9]+\\.[0-9]+\\.?[0-9]*)" ACL_VERSION "${ACL_VERSION_STRING}")
        set(ACL_VERSION "${CMAKE_MATCH_1}")
        if ("${ACL_VERSION}" VERSION_EQUAL "0.0")
            # Unreleased ACL versions come with version string "v0.0-unreleased", and may not be compatible with oneDNN.
            # It is recommended to use the latest release of ACL.
            message(WARNING
                "Build may fail. Using unreleased ACL version.\n"
                "Supported ACL versions:\n"
                "- minimum required is ${ACL_MINIMUM_VERSION}\n"
            )
        elseif("${ACL_VERSION}" VERSION_LESS "${ACL_MINIMUM_VERSION}")
            message(FATAL_ERROR
                "Detected ACL version ${ACL_VERSION}, but minimum required is ${ACL_MINIMUM_VERSION}\n"
            )
        endif()

        # If the Arm Compute Graph library is missing. It was eventually deprecated in favour of
        # having a single 'arm_compute' library. If ACL is not versioned, we'll assume this is okay.
        # If it is, however, versioned, we need to make sure it is recent enough version
        if(NOT ACL_GRAPH_LIBRARY_FOUND)
            # If it's not an unreleased version
            if(NOT("${ACL_VERSION}" VERSION_EQUAL "0.0"))
                # We have an old enough version of ACL where the 'arm_compute_graph' lib *should* exist
                if("${ACL_VERSION}" VERSION_LESS_EQUAL "${ACL_LAST_VERSION_BEFORE_GRAPH_LIB_DEPRECATED}")
                    message(FATAL_ERROR
                        "Arm Compute Graph library is missing in version ${ACL_VERSION} of ACL.\n"
                        "However, this library was only made redundant after version ${ACL_LAST_VERSION_BEFORE_GRAPH_LIB_DEPRECATED}.\n"
                        "Make sure it exists in the same folder as the 'arm_compute' library.\n"
                    )
                endif()
            endif()
        endif()
    endif()

    if(NOT ACL_GRAPH_LIBRARY_FOUND)
        message(STATUS "Found 'arm_compute' library but not 'arm_compute_graph'. Will assume they have been merged into a single library artifact.")
    endif()

    list(APPEND EXTRA_SHARED_LIBS ${ACL_LIBRARIES})

    include_directories(${ACL_INCLUDE_DIRS})

    message(STATUS "Arm Compute Library: ${ACL_LIBRARIES}")
    message(STATUS "Arm Compute Library headers: ${ACL_INCLUDE_DIRS}")

    add_definitions(-DDNNL_AARCH64_USE_ACL)
    set(CMAKE_CXX_STANDARD 14)
    set(CMAKE_CXX_EXTENSIONS "OFF")
endif()
