#include "catch2/catch.hpp"

#include "share/grid/mesh_free_grids_manager.hpp"
#include "diagnostics/longwave_cloud_forcing.hpp"
#include "diagnostics/register_diagnostics.hpp"

#include "physics/share/physics_constants.hpp"

#include "share/util/scream_setup_random_test.hpp"
#include "share/util/scream_common_physics_functions.hpp"
#include "share/field/field_utils.hpp"

#include "ekat/ekat_pack.hpp"
#include "ekat/kokkos/ekat_kokkos_utils.hpp"
#include "ekat/util/ekat_test_utils.hpp"

#include <iomanip>

namespace scream {

std::shared_ptr<GridsManager>
create_gm (const ekat::Comm& comm, const int ncols, const int nlevs) {

  const int num_local_elems = 4;
  const int np = 4;
  const int num_global_cols = ncols*comm.size();

  ekat::ParameterList gm_params;
  gm_params.set<int>("Number of Global Columns", num_global_cols);
  gm_params.set<int>("Number of Local Elements", num_local_elems);
  gm_params.set<int>("Number of Vertical Levels", nlevs);
  gm_params.set<int>("Number of Gauss Points", np);

  auto gm = create_mesh_free_grids_manager(comm,gm_params);
  gm->build_grids();

  return gm;
}

//-----------------------------------------------------------------------------------------------//
template<typename DeviceT>
void run(std::mt19937_64& engine)
{
  using PF         = scream::PhysicsFunctions<DeviceT>;
  using PC         = scream::physics::Constants<Real>;
  using Pack       = ekat::Pack<Real,SCREAM_PACK_SIZE>;
  using KT         = ekat::KokkosTypes<DeviceT>;
  using ExecSpace  = typename KT::ExeSpace;
  using MemberType = typename KT::MemberType;
  using view_1d    = typename KT::template view_1d<Pack>;
  using rview_1d   = typename KT::template view_1d<Real>;

  const     int packsize = SCREAM_PACK_SIZE;
  constexpr int num_levs = packsize*2 + 1; // Number of levels to use for tests, make sure the last pack can also have some empty slots (packsize>1).
  const     int num_mid_packs    = ekat::npack<Pack>(num_levs);

  // A world comm
  ekat::Comm comm(MPI_COMM_WORLD);

  // Create a grids manager - single column for these tests
  const int ncols = 1; //TODO should be set to the size of the communication group.
  auto gm = create_gm(comm,ncols,num_levs);

  // Kokkos Policy
  auto policy = ekat::ExeSpaceUtils<ExecSpace>::get_default_team_policy(ncols, num_mid_packs);

  // Input (randomized) views
  view_1d LW_flux_up("LW_flux_up",num_mid_packs),
          LW_clrsky_flux_up("LW_clrsky_flux_up",num_mid_packs);


  auto dview_as_real = [&] (const view_1d& v) -> rview_1d {
    return rview_1d(reinterpret_cast<Real*>(v.data()),v.size()*packsize);
  };

  // Construct random input data
  using RPDF = std::uniform_real_distribution<Real>;
  RPDF pdf_LW_flux_x(0.0,400);

  // A time stamp
  util::TimeStamp t0 ({2022,1,1},{0,0,0});

  // Construct the Diagnostic
  ekat::ParameterList params;
  params.set<std::string>("Diagnostic Name", "Longwave Cloud Forcing");
  params.set<std::string>("Grid", "Point Grid");
  register_diagnostics();
  auto& diag_factory = AtmosphereDiagnosticFactory::instance();
  auto diag = diag_factory.create("LongwaveCloudForcing",comm,params);
  diag->set_grids(gm);


  // Set the required fields for the diagnostic.
  std::map<std::string,Field> input_fields;
  for (const auto& req : diag->get_required_field_requests()) {
    Field f(req.fid);
    auto & f_ap = f.get_header().get_alloc_properties();
    f_ap.request_allocation(packsize);
    f.allocate_view();
    const auto name = f.name();
    f.get_header().get_tracking().update_time_stamp(t0);
    diag->set_required_field(f.get_const());
//    REQUIRE_THROWS(diag->set_computed_field(f));
    input_fields.emplace(name,f);
  }

  // Initialize the diagnostic
  diag->initialize(t0,RunType::Initial);

  // Run tests
  {
    // Construct random data to use for test
    // Get views of input data and set to random values
    const auto& LW_flux_up_f          = input_fields["LW_flux_up"];
    const auto& LW_flux_up_v          = LW_flux_up_f.get_view<Pack**>();
    const auto& LW_clrsky_flux_up_f          = input_fields["LW_clrsky_flux_up"];
    const auto& LW_clrsky_flux_up_v          = LW_clrsky_flux_up_f.get_view<Pack**>();

    for (int icol=0;icol<ncols;icol++) {
      const auto& LW_flux_up_sub      = ekat::subview(LW_flux_up_v,icol);
      const auto& LW_clrsky_flux_up_sub      = ekat::subview(LW_clrsky_flux_up_v,icol);
//      const auto& dp_sub      = ekat::subview(pseudo_dens_v,icol);
//      ekat::genRandArray(dview_as_real(pseudo_density),  engine, pdf_pseudodens);
//      Kokkos::deep_copy(dp_sub,pseudo_density);

      ekat::genRandArray(dview_as_real(LW_flux_up),              engine, pdf_LW_flux_x);
      ekat::genRandArray(dview_as_real(LW_clrsky_flux_up),              engine, pdf_LW_flux_x);
      Kokkos::deep_copy(LW_flux_up_sub,LW_flux_up);
      Kokkos::deep_copy(LW_clrsky_flux_up_sub,LW_clrsky_flux_up);

    }
   // ekat::genRandArray(phis_v, engine, pdf_surface);

    // Run diagnostic and compare with manual calculation
    diag->compute_diagnostic();
    const auto& diag_out = diag->get_diagnostic();
    Field LWCF_f = diag_out.clone();
    LWCF_f.deep_copy<double,Host>(0.0);
    LWCF_f.sync_to_dev();
    const auto& LWCF_v = LWCF_f.get_view<Real*>();
    const int pack_surf = std::min(num_levs / Pack::n, num_mid_packs-1);
    const int idx_surf  = num_levs % Pack::n;
    Kokkos::parallel_for("", policy, KOKKOS_LAMBDA(const MemberType& team) {
      const int icol = team.league_rank();
      LWCF_v(icol) = LW_clrsky_flux_up_v(icol,0)[0] -  LW_flux_up_v(icol,0)[0] ;
    });
    Kokkos::fence();
    REQUIRE(views_are_equal(diag_out,LWCF_f));
  }
 
  // Finalize the diagnostic
  diag->finalize(); 

} // run()

TEST_CASE("longwave_cloud_forcing_test", "longwave_cloud_forcing_test]"){
  // Run tests for both Real and Pack, and for (potentially) different pack sizes
  using scream::Real;
  using Device = scream::DefaultDevice;

  constexpr int num_runs = 5;

  auto engine = scream::setup_random_test();

  printf(" -> Number of randomized runs: %d\n\n", num_runs);

  printf(" -> Testing Pack<Real,%d> scalar type...",SCREAM_PACK_SIZE);
  for (int irun=0; irun<num_runs; ++irun) {
    run<Device>(engine);
  }
  printf("ok!\n");

  printf("\n");

} // TEST_CASE

} // namespace
