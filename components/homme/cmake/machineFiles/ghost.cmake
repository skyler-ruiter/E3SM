# Ghost CMake Cache File
# May 29th, 2024 -- Skyler Ruiter

#----------------------------------------------#
#                                              #
#  Current Issues:                             #
#    - legacy version of netcdf-fortran is     #
#      trying to link to a version of netcdf-c #
#      (libnetcdf.so.6) but can't find it.     #
#      Current version of netcdf-c in modules  #
#      is far later version (libnetcdf.so.19)  #
#      need to provide a newer netcdf-f or     #
#      older netcdf-c.                         #
#                                              #
#----------------------------------------------#

# Modules Last Used:
#   Currently Loaded Modules:
#    1) aue/hdf5/1.14.2-oneapi-2024.1.0-openmpi-4.1.6              4) intel/21.3.0
#    2) aue/parallel-netcdf/1.12.3-oneapi-2024.1.0-openmpi-4.1.6   5) openmpi-intel/4.0
#    3) aue/netcdf-c/4.9.2-oneapi-2024.1.0-openmpi-4.1.6
# P.S. -- Make sure aue/openmpi is not loaded or cmake won't find right c compiler

# Compilers
SET (CMAKE_Fortran_COMPILER mpif90 CACHE FILEPATH "")
SET (CMAKE_C_COMPILER mpicc CACHE FILEPATH "")
SET (CMAKE_CXX_COMPILER mpicc CACHE FILEPATH "")

# Flag Settings
SET (CMAKE_EXE_LINKER_FLAGS "-ldl" CACHE STRING "")
SET (OPT_FLAGS "-O3" CACHE STRING "")
SET (ADD_Fortran_FLAGS " -O3" CACHE STRING "")

# Directory Pointers
SET (NetCDF_Fortran_PATH /projects/ccsm/netcdf-legacy/netcdf-fortran-4.4.2/ CACHE FILEPATH "")
#SET (PnetCDF_PATH /projects/ccsm/src/parallel-netcdf-1.5.0/ CACHE FILEPATH "")
#SET (PnetCDF_PATH $ENV{SEMS_NETCDF_ROOT} CACHE FILEPATH "")
#SET (PNETCDF_DIR $ENV{SEMS_NETCDF_ROOT} CACHE FILEPATH "")
SET (HDF5_DIR $ENV{SEMS_HDF5_ROOT} CACHE FILEPATH "")
SET (ZLIB_DIR $ENV{SEMS_ZLIB_ROOT} CACHE FILEPATH "")
#SET (CPRNC_DIR /projects/ccsm/cprnc/build.toss3 CACHE FILEPATH "")

# Homme Settings
# SET (BUILD_HOMME_WITHOUT_PIOLIBRARY TRUE CACHE BOOL "") # IO on/off
SET (USE_QUEUING FALSE CACHE BOOL "")
SET (HOMME_FIND_BLASLAPACK TRUE CACHE BOOL "")
SET (WITH_PNETCDF TRUE CACHE FILEPATH "")

# Kokkos Settings
SET (Kokkos_ARCH_BDW ON CACHE BOOL "")
SET (BUILD_HOMME_THETA_KOKKOS TRUE CACHE BOOL "")
SET (BUILD_HOMME_PREQX_KOKKOS TRUE CACHE BOOL "")
