set(MPICC "cc")
set(MPICXX "CC")
set(MPIFC "ftn")
set(SCC "nvcc")
set(SCXX "nvc++")
set(SFC "nvfortran")
string(APPEND CPPDEFS " -DFORTRANUNDERSCORE -DNO_R16 -DCPRNVIDIA")
if (NOT DEBUG)
  string(APPEND CFLAGS " -O0 -Mnofma -Mvect=nosimd")
endif()
if (DEBUG)
  string(APPEND CFLAGS " -g")
endif()
string(APPEND FFLAGS " -i4 -Mstack_arrays  -Mextend -byteswapio -Mflushz -Kieee -DHAVE_IEEE_ARITHMETIC -Mallocatable=03 -DNO_R16 -traceback")
if (DEBUG)
  string(APPEND FFLAGS " -O0 -g -Ktrap=fp -Mbounds -Kieee")
endif()
if (NOT DEBUG)
  string(APPEND FFLAGS " -O1")
endif()
if (DEBUG)
  string(APPEND CXXFLAGS " -g -O0 -Mnofma -Wall -Kieee -traceback")
endif()
if (NOT DEBUG)
  string(APPEND CXXFLAGS " -O2")
endif()
if (compile_threaded)
  string(APPEND FFLAGS " -mp")
  string(APPEND CFLAGS " -mp")
  string(APPEND CXXFLAGS " -mp")
  string(APPEND LDFLAGS " -mp")
endif()
set(CXX_LINKER "CXX")
string(APPEND CXX_LIBS " -lstdc++")
string(APPEND FFLAGS_NOOPT " -O0 -Mnofma")
string(APPEND FIXEDFLAGS " -Mfixed")
string(APPEND FREEFLAGS " -Mfree")
set(HAS_F2008_CONTIGUOUS "FALSE")
string(APPEND LDFLAGS " -Wl,--allow-multiple-definition")
