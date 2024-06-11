# CMake initial cache file for Perlmutter using nvidia compiler
# 6/10/24 Skyler Ruiter

# Module List that worked for this cache file
# Currently Loaded Modules:
#   1) craype-x86-milan   (cpe)   5) craype/2.7.30          (c)     9) cray-dsmml/0.2.2               13) cray-hdf5/1.12.2.9  (io)
#   2) libfabric/1.15.2.0         6) gcc-native/12.3               10) cmake/3.24.3     (buildtools)  14) cray-netcdf/4.9.0.9 (io)
#   3) craype-network-ofi         7) perftools-base/23.12.0 (dev)  11) cudatoolkit/12.2 (g)
#   4) PrgEnv-gnu/8.5.0   (cpe)   8) cpe/23.12              (cpe)  12) openmpi/5.0.0    (mpi)


# Run instructions on Perlmutter
# 0) cd ~/E3SM/; mkdir aaa; cd aaa (get a cmake build folder)
# 1) cmake -C ~/E3SM/components/homme/cmake/machineFiles/perlmutter-nvidia.cmake ~/E3SM/components/homme/
# 2) make -j16 theta-nlev128-kokkos
# 3) cd test_execs/theta-nlev128-kokkos/
# 4) salloc --nodes 1 --qos interactive --time 00:05:00 --constraint gpu --gpus 4 --account=e3sm_g
# 5) source ~/load-pm (load environment modules)
# 6) srun -n 1 --gpus 1 -c 128 ./theta-nlev128-kokkos < namelist.nl


############################################
#                                          #
#                ENV PATHS                 #
#                                          #
############################################

EXECUTE_PROCESS(COMMAND nf-config --prefix
  RESULT_VARIABLE NFCONFIG_RESULT
  OUTPUT_VARIABLE NFCONFIG_OUTPUT
  ERROR_VARIABLE  NFCONFIG_ERROR
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
SET (NetCDF_Fortran_PATH "${NFCONFIG_OUTPUT}" CACHE STRING "")

EXECUTE_PROCESS(COMMAND nc-config --prefix
  RESULT_VARIABLE NCCONFIG_RESULT
  OUTPUT_VARIABLE NCCONFIG_OUTPUT
  ERROR_VARIABLE  NCCONFIG_ERROR
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
SET (NetCDF_C_PATH "${NCCONFIG_OUTPUT}" CACHE STRING "")

# cray-hdf5-parallel/1.12.0.6  cray-netcdf-hdf5parallel/4.7.4.6 cray-parallel-netcdf/1.12.1.6
SET(NETCDF_DIR $ENV{CRAY_NETCDF_HDF5PARALLEL_PREFIX} CACHE FILEPATH "")
SET(PNETCDF_DIR $ENV{CRAY_PARALLEL_NETCDF_DIR} CACHE FILEPATH "")
SET(HDF5_DIR $ENV{CRAY_HDF5_PARALLEL_PREFIX} CACHE FILEPATH "")
SET(CPRNC_DIR /global/cfs/cdirs/e3sm/tools/cprnc CACHE FILEPATH "")
#SET (NetCDF_C_PATH $ENV{CRAY_NETCDF_HDF5PARALLEL_PREFIX} CACHE FILEPATH "")
#SET (NetCDF_Fortran_PATH $ENV{CRAY_NETCDF_HDF5PARALLEL_PREFIX} CACHE FILEPATH "")

# Compilers
SET(CMAKE_C_COMPILER "mpicc" CACHE STRING "")
SET(CMAKE_Fortran_COMPILER "mpif90" CACHE STRING "")
SET(CMAKE_CXX_COMPILER "${CMAKE_CURRENT_SOURCE_DIR}/../../externals/ekat/extern/kokkos/bin/nvcc_wrapper" CACHE STRING "")


############################################
#                                          #
#             BUILD SETTINGS               #
#                                          #
############################################

# Flag Settings
SET (CMAKE_C_FLAGS "-w" CACHE STRING "")
SET (ADD_CXX_FLAGS " -DCPRGNU -Xcudafe -I/global/common/software/nersc/pe/gpu/gnu/openmpi/5.0.0/include" CACHE STRING "")
SET (ADD_Fortran_FLAGS " -DCPRGNU -I/global/common/software/nersc/pe/gpu/gnu/openmpi/5.0.0/include" CACHE STRING "")
#SET (CMAKE_EXE_LINKER_FLAGS "-ldl -lopenblas" CACHE STRING "")
#SET (OPT_FLAGS "-O3" CACHE STRING "")
#SET (DEBUG_FLAGS "" CACHE STRING "")

# Homme Settings
SET(HOMMEXX_EXEC_SPACE CUDA CACHE STRING "")
#SET(HOMMEXX_MPI_ON_DEVICE FALSE CACHE BOOL "")
SET(HOMMEXX_CUDA_MAX_WARP_PER_TEAM "16" CACHE STRING  "")
SET(BUILD_HOMME_WITHOUT_PIOLIBRARY TRUE CACHE BOOL "")
SET(HOMME_FIND_BLASLAPACK TRUE CACHE BOOL "")
SET(HOMME_ENABLE_COMPOSE TRUE CACHE BOOL "")
#CRAY_LIBSCI_PREFIX_DIR=/opt/cray/pe/libsci/21.08.1.2/NVIDIA/20.7/x86_64
#SET(HOMME_TESTING_PROFILE "dev" CACHE STRING "")
SET(WITH_PNETCDF FALSE CACHE FILEPATH "")
SET(ENABLE_OPENMP OFF CACHE BOOL "")
SET(ENABLE_COLUMN_OPENMP OFF CACHE BOOL "")
SET(ENABLE_HORIZ_OPENMP OFF CACHE BOOL "")
SET(USE_QUEUING FALSE CACHE BOOL "")
SET(BUILD_HOMME_THETA_KOKKOS TRUE CACHE BOOL "")
#SET(HOMMEXX_BFB_TESTING TRUE CACHE BOOL "")
SET(USE_TRILINOS OFF CACHE BOOL "")
SET(HAVE_EXTRAE TRUE CACHE BOOL "")
SET(CXXLIB_SUPPORTED_CACHE FALSE CACHE BOOL "")
#SET(CMAKE_VERBOSE_MAKEFILE ON CACHE BOOL "")
SET(USE_NUM_PROCS 4 CACHE STRING "")
SET(USE_MPIEXEC "srun" CACHE STRING "")

# Kokkos Settings
SET(Kokkos_ENABLE_OPENMP OFF CACHE BOOL "")
SET(Kokkos_ENABLE_CUDA ON CACHE BOOL "")
SET(Kokkos_ENABLE_CUDA_LAMBDA TRUE CACHE BOOL "")
SET(Kokkos_ARCH_AMPERE80 ON CACHE BOOL "")
SET(Kokkos_ENABLE_DEBUG FALSE CACHE BOOL "")
SET(Kokkos_ENABLE_AGGRESSIVE_VECTORIZATION FALSE CACHE BOOL "")
#SET(Kokkos_ENABLE_CUDA_UVM ON CACHE BOOL "")
SET(Kokkos_ENABLE_EXPLICIT_INSTANTIATION OFF CACHE BOOL "")
#SET(Kokkos_ENABLE_CUDA_ARCH_LINKING OFF CACHE BOOL "")


##################
# CMake Messages #
##################

#/usr/lib64/gcc/x86_64-suse-linux/12/../../../../x86_64-suse-linux/bin/ld: warning: libgfortran.so.4, needed by /usr/lib64/libblas.so, may conflict with libgfortran.so.5
#/usr/lib64/gcc/x86_64-suse-linux/12/../../../../x86_64-suse-linux/bin/ld: warning: libgfortran.so.4, needed by /usr/lib64/libblas.so, may conflict with libgfortran.so.5

# comes at very end of make for theta-nlev128-kokkos, fortran linking issues with different versions

