#ifndef SCREAM_DP_FUNCTIONS_F90_HPP
#define SCREAM_DP_FUNCTIONS_F90_HPP

#include "share/scream_types.hpp"
#include "physics/share/physics_test_data.hpp"

#include "dp_functions.hpp"
#include "physics_constants.hpp"

#include <vector>
#include <array>
#include <utility>

//
// Bridge functions to call fortran version of dp functions from C++
//

namespace scream {
namespace dp {

struct AdvanceIopForcingData : public PhysicsTestData {
  // Inputs
  Real scm_dt, ps_in;
  Real *u_in, *v_in, *t_in, *q_in, *t_phys_frc;
  
  // Outputs
  Real *u_update, *v_update, *t_update, *q_update;
  
  AdvanceIopForcingData(Int plev_, Int pcnst_, Real scm_dt_, Real ps_in_) :
    PhysicsTestData({{ plev_ }, { plev_, pcnst_ }}, {{ &u_in, &v_in, &t_in, &t_phys_frc, &u_update, &v_update, &t_update }, { &q_in, &q_update }}), plev(plev_), pcnst(pcnst_), scm_dt(scm_dt_), ps_in(ps_in_) {}
  
  PTD_STD_DEF(AdvanceIopForcingData, 4, plev, pcnst, scm_dt, ps_in);
};

// Glue functions to call fortran from from C++ with the Data struct

void advance_iop_forcing(AdvanceIopForcingData& d);
extern "C" { // _f function decls

void advance_iop_forcing_f(Real scm_dt, Real ps_in, Real* u_in, Real* v_in, Real* t_in, Real* q_in, Real* t_phys_frc, Real* u_update, Real* v_update, Real* t_update, Real* q_update);
} // end _f function decls

}  // namespace dp
}  // namespace scream

#endif // SCREAM_DP_FUNCTIONS_F90_HPP
