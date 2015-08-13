# - Try to find NetCDF
#
# This can be controlled by setting the NetCDF_DIR (or, equivalently, the 
# NETCDF environment variable), or NetCDF_<lang>_DIR CMake variables, where
# <lang> is the COMPONENT language one needs.
#
# Once done, this will define:
#
#   NetCDF_<lang>_FOUND        (BOOL) - system has NetCDF
#   NetCDF_<lang>_IS_SHARED    (BOOL) - whether library is shared/dynamic
#   NetCDF_<lang>_INCLUDE_DIR  (PATH) - Location of the C header file
#   NetCDF_<lang>_INCLUDE_DIRS (LIST) - the NetCDF include directories
#   NetCDF_<lang>_LIBRARY      (FILE) - Path to the C library file
#   NetCDF_<lang>_LIBRARIES    (LIST) - link these to use NetCDF
#   NetCDF_<lang>_DEFINITIONS  (LIST) - preprocessor macros to use with NetCDF
#   NetCDF_<lang>_OPTIONS      (LIST) - compiler options to use NetCDF
#
# The available COMPONENTS are: C Fortran
# If no components are specified, it assumes only C
include (LibFindLibraryMacros)

# Define NetCDF C Component
define_package_component (NetCDF DEFAULT
                          COMPONENT C
                          INCLUDE_NAMES netcdf.h
                          LIBRARY_NAMES netcdf)

# Define NetCDF Fortran Component
define_package_component (NetCDF
                          COMPONENT Fortran
                          INCLUDE_NAMES netcdf.mod netcdf.inc
                          LIBRARY_NAMES netcdff)
                       
# Search for list of valid components requested
find_valid_components (NetCDF)

#==============================================================================
# SEARCH FOR VALIDATED COMPONENTS
foreach (NetCDF_comp IN LISTS NetCDF_FIND_VALID_COMPONENTS)

    # If not found already, search...
    if (NOT NetCDF_${NetCDF_comp}_FOUND)

        # Manually add the MPI include and library dirs to search paths
        if (MPI_${NetCDF_comp}_FOUND)
            set (NetCDF_${NetCDF_comp}_INCLUDE_HINTS ${MPI_${NetCDF_comp}_INCLUDE_PATH})
            set (NetCDF_${NetCDF_comp}_LIBRARY_HINTS)
            foreach (lib IN LISTS MPI_${NetCDF_comp}_LIBRARIES)
                get_filename_component (libdir ${lib} PATH)
                list (APPEND NetCDF_${NetCDF_comp}_LIBRARY_HINTS ${libdir})
                unset (libdir)
            endforeach ()
        endif ()
        
        # Search for the package component    
        find_package_component(NetCDF COMPONENT ${NetCDF_comp}
                               INCLUDE_HINTS ${NetCDF_${NetCDF_comp}_INCLUDE_HINTS}
                               LIBRARY_HINTS ${NetCDF_${NetCDF_comp}_LIBRARY_HINTS})
                               
        # Continue only if found
        if (NetCDF_${NetCDF_comp}_FOUND)

        #----------------------------------------------------------------------
        # Check & Dependencies for COMPONENT: C
        if (NetCDF_comp STREQUAL C AND NOT NetCDF_C_FINISHED)

            find_path (NetCDF_C_META_DIR
                       NAMES netcdf_meta.h
                       HINTS ${NetCDF_C_INCLUDE_DIRS})
            if (NetCDF_C_META_DIR)
            
                # Get version string
                try_run (NetCDF_C_VERSION_RUNVAR NetCDF_C_VERSION_COMPVAR
                         ${CMAKE_CURRENT_BINARY_DIR}/tryNetCDF_C_VERSION
                         ${CMAKE_SOURCE_DIR}/cmake/TryNetCDF_VERSION.c
                         COMPILE_DEFINITIONS -I${NetCDF_C_META_DIR}
                         COMPILE_OUTPUT_VARIABLE TryNetCDF_OUT
                         RUN_OUTPUT_VARIABLE NetCDF_C_VERSION)
                if (NetCDF_C_VERSION)
                    if (NetCDF_C_VERSION VERSION_LESS NetCDF_FIND_VERSION)
                        message (FATAL_ERROR "NetCDF_C version insufficient")
                    else ()
                        message (STATUS "Found NetCDF_C version ${NetCDF_C_VERSION}")
                    endif ()
                endif ()
                
                # Test for DAP support (requires CURL)
                try_compile(NetCDF_C_HAS_DAP 
                            ${CMAKE_CURRENT_BINARY_DIR}/tryNetCDF_DAP
                            SOURCES ${CMAKE_SOURCE_DIR}/cmake/TryNetCDF_DAP.c
                            COMPILE_DEFINITIONS -I${NetCDF_C_META_DIR}
                            OUTPUT_VARIABLE TryNetCDF_OUT)
                if (NetCDF_C_HAS_DAP)
                    message (STATUS "NetCDF_C has DAP support")
                else ()
                    message (STATUS "NetCDF_C does not have DAP support")
                endif ()
    
                # Test for PARALLEL support
                try_compile(NetCDF_C_HAS_PARALLEL 
                            ${CMAKE_CURRENT_BINARY_DIR}/tryNetCDF_PARALLEL
                            SOURCES ${CMAKE_SOURCE_DIR}/cmake/TryNetCDF_PARALLEL.c
                            COMPILE_DEFINITIONS -I${NetCDF_C_META_DIR}
                            OUTPUT_VARIABLE TryNetCDF_OUT)
                if (NetCDF_C_HAS_PARALLEL)
                    message (STATUS "NetCDF_C has parallel support")
                else ()
                    message (STATUS "NetCDF_C does not have parallel support")
                endif ()
                    
                # Test for PNETCDF support
                try_compile(NetCDF_C_HAS_PNETCDF
                            ${CMAKE_CURRENT_BINARY_DIR}/tryNetCDF_PNETCDF
                            SOURCES ${CMAKE_SOURCE_DIR}/cmake/TryNetCDF_PNETCDF.c
                            COMPILE_DEFINITIONS -I${NetCDF_C_META_DIR}
                            OUTPUT_VARIABLE TryNetCDF_OUT)
                if (NetCDF_C_HAS_PNETCDF)
                    message (STATUS "NetCDF_C requires PnetCDF")
                else ()
                    message (STATUS "NetCDF_C does not require PnetCDF")
                endif ()
                
            else ()
            
                message (WARNING "Could not find netcdf_meta.h")
                 
            endif ()
            
            # Dependencies
            if (NOT NetCDF_C_IS_SHARED)
            
                # DEPENDENCY: HDF5
                find_package (HDF5 COMPONENTS HL C)
                if (HDF5_C_FOUND)
                    list (APPEND NetCDF_C_INCLUDE_DIRS ${HDF5_C_INCLUDE_DIRS}
                                                       ${HDF5_HL_INCLUDE_DIRS})
                    list (APPEND NetCDF_C_LIBRARIES ${HDF5_C_LIBRARIES}
                                                    ${HDF5_HL_LIBRARIES})
                endif ()

                # DEPENDENCY: CURL (If DAP enabled)
                if (NetCDF_C_HAS_DAP)
                    find_package (CURL)
                    if (CURL_FOUND)
                        list (APPEND NetCDF_C_INCLUDE_DIRS ${CURL_INCLUDE_DIRS})
                        list (APPEND NetCDF_C_LIBRARIES ${CURL_LIBRARIES})
                    endif ()
                endif ()
                
                # DEPENDENCY: PnetCDF (if PnetCDF enabled)
                if (NetCDF_C_HAS_PNETCDF)
                    find_package (PnetCDF COMPONENTS C)
                    if (CURL_FOUND)
                        list (APPEND NetCDF_C_INCLUDE_DIRS ${PnetCDF_C_INCLUDE_DIRS})
                        list (APPEND NetCDF_C_LIBRARIES ${PnetCDF_C_LIBRARIES})
                    endif ()
                endif ()
                                
                # DEPENDENCY: LIBDL Math
                list (APPEND NetCDF_C_LIBRARIES -ldl -lm)

            endif ()

            # Checks and dependecies finished
            set (NetCDF_C_FINISHED TRUE 
                 CACHE BOOL "NetCDF_C Module Fully Found")

        #----------------------------------------------------------------------
        # Check & Dependencies for COMPONENT: Fortran
        elseif (NetCDF_comp STREQUAL Fortran AND NOT NetCDF_Fortran_FINISHED)

            # Get dependencies
            if (NOT NetCDF_Fortran_IS_SHARED)
            
                # DEPENDENCY: NetCDF -- CAREFUL!  This is recursive!
                find_package (NetCDF COMPONENTS C)
                if (NetCDF_C_FOUND)
                    list (APPEND NetCDF_Fortran_INCLUDE_DIRS ${NetCDF_C_INCLUDE_DIRS})
                    list (APPEND NetCDF_Fortran_LIBRARIES ${NetCDF_C_LIBRARIES})
                endif ()
                
            endif ()

            # Get version string
            set (COMP_DEFS)
            foreach (incdir IN LISTS NetCDF_Fortran_INCLUDE_DIRS)
                list (APPEND COMP_DEFS "-I${incdir}")
            endforeach ()
            try_run (NetCDF_Fortran_VERSION_RUNVAR
                     NetCDF_Fortran_VERSION_COMPVAR
                     ${CMAKE_CURRENT_BINARY_DIR}/tryNetCDF_Fortran_VERSION
                     ${CMAKE_SOURCE_DIR}/cmake/TryNetCDF_VERSION.f90
                     COMPILE_DEFINITIONS ${COMP_DEFS}
                     LINK_LIBRARIES ${NetCDF_Fortran_LIBRARIES}
                     COMPILE_OUTPUT_VARIABLE TryNetCDF_OUT
                     RUN_OUTPUT_VARIABLE NetCDF_Fortran_VERSION)
            if (NetCDF_Fortran_VERSION)
                string (STRIP ${NetCDF_Fortran_VERSION} NetCDF_Fortran_VERSION)
                if (NetCDF_Fortran_VERSION VERSION_LESS NetCDF_FIND_VERSION)
                    message (FATAL_ERROR "NetCDF_Fortan version insufficient")
                else ()
                    message (STATUS "Found NetCDF_Fortran version ${NetCDF_Fortran_VERSION}")
                endif ()
            else ()
                message (STATUS "Could not find NetCDF_Fortran version")
            endif ()

            # Checks and dependencies finished
            set (NetCDF_Fortran_FINISHED TRUE
                 CACHE BOOL "NetCDF_Fortran Module Fully Found")

        endif ()

        endif ()
        
    endif ()
    
endforeach ()
