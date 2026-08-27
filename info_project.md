# Project understanding: diffusion of Rayleigh--Taylor instability

Last updated: 2026-08-27 (made `draft/` the Git repository root, moved generated manuscript figures into `draft/figures/`, updated the MATLAB/LaTeX figure paths, pruned unused figure assets, removed the obsolete Boussinesq TKE/scalar budget grids, temporarily omitted the three variable-density colormaps after page 20, made the TikZ cache directory survive GitHub/Overleaf imports, and reduced generated curve sampling to fit Overleaf's editable-text limit)

This is the living memory for the manuscript in `draft/main.tex`. Update it whenever the scientific argument, notation, manuscript structure, numerical evidence, or open tasks change. It records both the intended project and the actual state of the current draft; unfinished text is not treated as an established result.

Manuscript metadata: title "On the diffusion of Rayleigh--Taylor Instability"; authors Marildo Kola (Mechanical Engineering, University of Michigan), Daniel Israel (LANL / Michigan SPARC), Aaron Towne (Aerospace Engineering, University of Michigan). The variable-density base-state derivation is attributed to a companion paper, `\citet{kola-israel-towne-2026}`, cited rather than re-derived in §2.2.

Note on tooling: `draft/` is the Git repository root for the manuscript, including `draft/figures/`. Its parent folder, `2_DGG_draft/`, is intentionally local-only and contains the MATLAB codes, data, and presentation material. The figure directory is intentionally limited to the active `main.tex` dependency closure (currently 68 TeX fragments and 3 PNG companions). Use Git commands from inside `draft/`; keep this file current and re-verify it (page count, undefined refs, section headers) at the start of a session rather than trusting the prose blindly.

## Project in one paragraph

The paper studies miscible Rayleigh--Taylor instability (RTI) when molecular diffusion makes the base density profile evolve on the same time scale as the perturbations. This makes the linearized problem non-autonomous and weakens the usefulness of frozen-time eigenvalue analysis, while the physical response also depends strongly on an initial perturbation that is generally random rather than known exactly. The manuscript therefore replaces a single optimal or prescribed disturbance with an ensemble described by its covariance. It connects that covariance to a physically realizable random displacement of the diffuse interface, derives the resulting mean perturbation-energy growth, and introduces a matrix-free stochastic stepping trace estimator (SSTE) for computing that growth without forming the time-dependent propagator. The theory is developed first for the Boussinesq model and then extended to the incompressible variable-density model.

## Central scientific questions

1. How should the growth of a non-autonomous diffusive RTI be characterized when the initial perturbation is uncertain?
2. How can abstract initial covariance statistics be tied to a perturbation that can actually be imposed or measured in a DNS or experiment?
3. How can the covariance-weighted mean energy be computed when the propagator is available only through forward and adjoint time stepping?
4. What controls the early-time decay, delayed onset, selected wavenumber, and later growth of the Boussinesq instability?
5. How do finite density contrast, viscosity contrast, and Schmidt number modify those conclusions in the variable-density problem?

## Intended contribution

The paper's main conceptual chain is

```text
random interface displacement eta(x,y)
        -> separable initial density covariance
        -> vertical covariance C_00^z and horizontal spectrum E_eta(k)
        -> per-wavenumber mean energy growth g(k,t)
        -> three-dimensional mean growth G^mean(t)
        -> growth rates and transition-delay measures
```

The main computational chain is

```text
non-autonomous direct stepper
        + weighted adjoint stepper
        -> matrix-free action of T = Phi* W Phi
        -> covariance-weighted operator K = L* T L
        -> Hutch++ trace estimate
        -> g(k,t) without explicitly forming Phi or T
```

The physical contribution and the numerical contribution are meant to reinforce each other: the initial statistics have a direct interface-displacement interpretation, and SSTE makes their propagation computationally practical.

## Physical models

### Shared setting and nondimensionalization

The flow consists of two miscible fluids with densities `rho_1`, `rho_2` and dynamic viscosities `mu_1`, `mu_2`. The reference density and viscosity are arithmetic means. Density and viscosity contrast are measured with

- `\Atw = A_t`, the density Atwood number;
- `\Amu = A_mu`, the viscosity Atwood number;
- `\Sch = Sc`, the Schmidt number.

The manuscript uses the viscous--gravitational scales of Chandrasekhar so that the Reynolds and Froude numbers in the main governing-equation scaling reduce to unity.

### Boussinesq model

The Boussinesq equations retain density variation only in buoyancy. The mixture velocity is divergence-free, viscosity is constant, and a scalar concentration `c` diffuses with diffusivity `Sc^{-1}`. The base state is quiescent and has the error-function profile

```text
c_0(z,t) = 1/2 erf(z/delta),    delta(t) = sqrt(4t/Sc).
```

After pressure elimination and horizontal Fourier transformation, the reduced state at horizontal wavenumber `k` is

```text
q_hat_k = [w_hat, c_hat]^T.
```

Vertical discretization produces the generalized, time-dependent system

```text
B_k(t) dq_hat_k/dt = A_k(t) q_hat_k,
q_hat_k(t) = Phi_{t,k} q_hat_{0,k}.
```

The time dependence enters through the diffusing base profile, so this is a non-autonomous initial-value problem even though the horizontal directions are homogeneous.

### Incompressible variable-density model

The IVD model suppresses acoustic waves but is not divergence-free as a mixture. It evolves density, momentum, and the diffusion-induced velocity divergence

```text
div(u) = -Sc^{-1} Laplacian(log rho).
```

The viscous stress permits a spatially varying dynamic viscosity. The base state is

```text
rho_0(z,t) = 1 + A_t erf(z/delta),
w_0(z,t)   = [2 A_t/(sqrt(pi) delta)] exp(-z^2/delta^2)/rho_0,
mu_0(z,t)  = 1 + A_mu erf(z/delta).
```

The nonzero `w_0` is the diffusion-induced base velocity. The reduced perturbation state is

```text
q_hat_k = [w_hat, rho_hat]^T.
```

The continuous block operators are collected in Appendix A and become the same generalized semi-discrete form `B_k(t) qdot = A_k(t) q` after vertical discretization. The parameter study shown in the results currently spans

- `Sc = 1, 5, 40`;
- `A_t = 0.05, 0.40, 0.75`;
- `A_mu = -0.90, 0, 0.90`.

## Energy measure

For a horizontal Fourier mode, the reduced state contains only vertical velocity plus concentration or density, whereas kinetic energy involves all three velocity components. The horizontal velocities are recovered through a minimum-energy constraint using the divergence relation. In Boussinesq flow this uses `div(u)=0`; in IVD flow it uses the linearized density-dependent divergence operator `L_rho`.

The manuscript then augments kinetic energy with a positive quadratic scalar/density amplitude. It explicitly notes that for unstable stratification there is no unique positive-definite quadratic disturbance energy with all the usual properties, so this is a chosen norm rather than a conserved physical total energy.

After vertical discretization the intended energy is encoded by a Hermitian positive-definite matrix `W_k`,

```text
E_k(t) = q_hat_k(t)^* W_k q_hat_k(t).
```

Statistical ensemble brackets and the weighted state-space inner product are distinct: `\mean{...}` is an ensemble mean, while a subscripted `W_k` bracket or the explicit quadratic form denotes the energy inner product.

## Initial-condition statistics

The key physical construction starts with a small random displacement `eta(x,y)` of the diffuse interface. Linearizing the displaced base profile gives

```text
rho'(x,y,z,0) = -rho_{0,z}(z,0) eta(x,y).
```

Therefore the initial density covariance separates naturally rather than by an arbitrary modeling assumption,

```text
C_00^{rho rho}(r_h,z,z')
  = [rho_{0,z}(z,0) rho_{0,z}(z',0)]
    <eta(x_h) eta(x_h+r_h)>
  = C_00^z(z,z') C_00^{xy}(r_h).
```

The deterministic vertical factor localizes disturbances in the diffuse layer. The random horizontal factor describes interface roughness. With horizontal homogeneity and isotropy, it depends only on `r = |r_h|` and is equivalent through a Hankel transform to the two-dimensional isotropic interface spectrum `E_eta(k)`.

The current transform convention is

```text
E_eta(k) = pi k Phi_00^{xy}(k),
<eta_0^2> = 2 integral_0^infinity E_eta(k) dk.
```

The manuscript introduces a family indexed by `n`,

```text
E_{eta,n}(k) proportional to (k/k_0)^(2n-1) exp[-2(k/k_0)^2].
```

Its real-space correlations are a Gaussian envelope times a Laguerre polynomial. The `n=1` member is a Gaussian correlation with reference scale

```text
lambda_0 = 2 sqrt(2)/k_0.
```

The initial-spectrum section defines only the family and its Gaussian reference scale `lambda_0`; it deliberately does not introduce an order-dependent `lambda_n`. The integral correlation length is introduced later, in the Boussinesq subsection on three-dimensional perturbation growth. The manuscript now fixes `n=1` there because higher spectral orders gave the same qualitative trends, so the active relation is

```text
lambda = [integral E_eta,1(k)/k dk]/[integral E_eta,1(k) dk]
       = sqrt(pi)/2 lambda_0,
k_0 = sqrt(2 pi)/lambda.
```

The initial variance `<eta_0^2>` is held fixed while `lambda` is varied. The more general order-dependent `k_0(n)` convention remains available in the numerical utilities and in the initial-spectrum family, but the Boussinesq and variable-density three-dimensional results now both use only `n=1`.

## Mean energy growth

At each horizontal wavenumber, the central quantity is

```text
g(k,t) = <E_k(t)>/<E_k(0)>.
```

Using the propagator and the discrete vertical covariance, the current manuscript writes

```text
g(k,t)
  = tr(Phi_{t,k} C_00^z Phi_{t,k}^* W_k) / tr(C_00^z W_k).
```

The full three-dimensional mean growth is the spectrum-weighted average

```text
G^mean(t)
  = integral g(k,t) E_eta(k) dk / integral E_eta(k) dk.
```

The corresponding logarithmic energy growth rates are

```text
sigma_bar_1D(k,t) = (1/2) d[log g(k,t)]/dt,
sigma_bar_3D(t)   = (1/2) d[log G^mean(t)]/dt.
```

The overbar marks a rate derived from an ensemble-mean energy. The `1D` quantity is a field over one horizontal-wavenumber shell and time; the `3D` quantity is the spectrum-weighted history of the full perturbation field. The selected quantities are defined once in the Boussinesq results and reused unchanged in VD:

```text
k_*(t)         in arg max_k sigma_bar_1D(k,t),
sigma_bar_*(t) = sigma_bar_1D(k_*(t),t) = max_k sigma_bar_1D(k,t).
```

Use `sigma_bar_*(t)`, never the redundant `sigma_bar_*(k_*,t)` and never `sigma_bar_max(t)`. This separation is fundamental: `g(k,t)` describes how a vertical covariance evolves at one wavenumber, while `E_eta(k)` states how much initial interface variance is assigned to each horizontal scale.

## SSTE algorithm

The required trace can be written using

```text
T = Phi_{t,k}^* W Phi_{t,k}.
```

The propagator is never formed. A loop-direct-adjoint (LDA) operation applies `T` to a vector by

1. integrating the generalized direct system forward from `0` to `T`;
2. projecting the terminal state into the adjoint terminal condition;
3. integrating the weighted, time-dependent adjoint backward;
4. returning the initial-time adjoint quantity.

If `C_00^z = L L^*`, SSTE applies Hutch++ to the effective positive operator

```text
K = L^* T L.
```

Random probes obtain a range sketch, QR isolates a dominant low-rank contribution, and independent projected probes estimate the residual trace. The appendix explains why truncating only the leading eigenvectors of `C_00^z` can fail: small-covariance directions may align with large transient amplification and contribute substantially after propagation.

## Verification strategy

The estimator is checked against three problems in the manuscript appendix (`sec:appendix_verification`, §C.2 in the rendered PDF).

1. Complex Ginzburg--Landau: autonomous, non-normal canonical model; exact reference from a matrix exponential; comparison of SSTE with covariance-eigenvector truncation for slowly and rapidly decaying covariance spectra.
2. Plane Poiseuille flow: autonomous Orr--Sommerfeld/Squire system at `Re = 1000`, `(k_x,k_z)=(0,2)`, with a Gaussian wall-normal covariance; exact exponential-propagator trace is the reference.
3. Non-autonomous scalar advection--diffusion--reaction problem: time-dependent coefficients with a closed-form mean-growth expression; this isolates the non-autonomous stepping and adjoint machinery.

The intended conclusion is that SSTE reproduces the reference trace with relatively few stepper calls and is robust when deterministic covariance truncation converges slowly or misses amplified low-energy directions.

A fourth, more end-to-end check exists only in `codes/verification/4_IVP/` (full RTI initial-value-problem integration, e.g. `V1_gmean.m`, `V2_kc_vs_k0.m`, `V3_sigma_map.m`, `V6a_ksigma_scaling.m`, `V6b_smax_scaling.m`) but is **not yet described in the manuscript text**; it is closer to a sanity check that the IVP integration reproduces the same `g(k,t)`/`G^mean(t)` curves as the SSTE/trace route. Decide whether this belongs in the verification appendix or stays as an internal cross-check before the next results pass.

## Current results and interpretation

### Boussinesq results — now a complete, written subsection

- The full Section 7 prose and the captions of figures 3 and 4 were polished on 2026-06-24 for grammar, clarity, and notation consistency. The revision also makes the plot-supported contrasts explicit: the QSSA misses the early non-autonomous stabilisation and the non-monotonic selected-wavenumber evolution, while the three-dimensional results exhibit an intermediate-correlation-length optimum in both the minimum energy and recovery time. No equations or intended scaling claims were changed in this prose pass.
- The `n=1`/Gaussian initial spectrum is compared with four ensembles of ten three-dimensional PsDNS simulations at `A_t=0.5`, `Sc=Re=1`, and `delta_0=1`. The four cases use `k_0={0.4,0.8,1.2,1.6}`, corresponding to `lambda_0={7.0711,3.5355,2.3570,1.7678}`. The computational grid is selected to represent all modes over `2 k_min <= k <= k_max`, with `k_min=0.025` and `k_max=2`, and each realization is normalized to `<eta_0^2>=10^-2`. Figure `compare_dns`(a) reports good agreement between these DNS ensembles and SSTE.
- Per-wavenumber mean growth rates are initially negative, cross neutrality near `t ~ 0.5`, attain a maximum, then decline as the diffusive layer broadens (figure `BQ_P1_sigma_map`, panel (a)).
- Figure `BQ_P1_sigma_map` is now a two-panel comparison: (a) the non-autonomous field `\overline{\sigma}_{1D}(k,t)` (full time-dependent propagator, as before) and (b) a QSSA companion `\sigma_{\mathrm{QSSA}}(k,t_0)`, obtained by freezing the base state at `\delta_0=\delta(t_0)` (i.e. `idot=0`) and taking the leading eigenvalue of the resulting frozen generalized eigenproblem at each `t_0`, with no time-stepping. The key qualitative contrast motivating the comparison: the QSSA field is positive from the earliest times sampled and shows no early-time stabilisation, unlike the real non-autonomous field. Both panels share one color scale/colorbar, set by panel (a)'s data and drawn only on panel (b) (clim and colorbar ticks fixed at `{-0.3,-0.15,0,0.15,0.3}`); the `k`-axis label is shown only on panel (a). Generated entirely by `codes/3_BQ/BQ_P1_sigma_map.m` (same script as the original map — see the `codes/3_BQ/` paragraph below for the generator details and a pgfplots gotcha worth knowing before touching this exporter again).
- The former 3x3 Boussinesq `Sc` and `delta_0` map was split into two 1x3 figures generated by `codes/3_BQ/P1_colormap.m`. The first fixes `delta_0=1` and varies `Sc={0.25,1,10}`. The second fixes `Sc=1` and varies `delta_0={1,2,5}`. Every panel and inset now uses `0 <= k <= 3`, and `P0_preprocess.m` retains modes through `k=3` for every case on both available grids so the raster fills the complete axis without white space. Both figures use the shared `sigma_map_BQ_effects_colorbar.tex`. Increasing `Sc` shortens the diffusion-induced delay before positive growth. At fixed `Sc`, increasing `delta_0` lowers the peak selected wavenumber but raises the peak growth rate, strengthening the initial non-autonomous transient contrary to the QSSA expectation.
- The proposed Boussinesq scaling discussion for `k_*(t)` and `sigma_bar_*(t)` was removed from the manuscript after the compensated diagnostics failed to support a robust scaling law. The associated two-panel manuscript figure and the exploratory `codes/3_BQ/P4_scaling.m` script were also removed. The definitions of `k_*(t)` and `sigma_bar_*(t)` remain because they are still used to describe the growth-rate map.
- The Boussinesq map generator now restricts the `k_*` maximization to the displayed interval `0 < k <= 1` and interpolates only finite samples with `makima`. This removed artificial jumps to the old full-data upper boundary `k=5` without changing the plotted growth-rate field.
- The three-dimensional `G^mean(t)` initially decays to `G^mean_min(lambda)` and later grows; the critical time `t_c` is the nonzero time for which `G^mean(t_c)=1`. Figure `BQ_P3_Gmean_analysis` now fixes `n=1`: panel (a), `BQ_P3_Gmean_lambda.tex`, shows 20 logarithmically spaced `G^mean(t)` histories for `0.5 <= lambda <= 20` over `0 <= t <= 8`, progressing from light gray to black, with ticks at `t=0,2,4,6,8`; one small red marker identifies the minimum of each history, so the markers directly reveal the non-monotonic `G^mean_min(lambda)` locus. Panel (b), `BQ_P3_tc_Gmin.tex`, shows `t_c(lambda)` with `G^mean_min(lambda)` in an inset and retains the longer `t <= 15` record needed to find return crossings. The former separate `n=1,2,3` files `BQ_P3_Gmin.tex` and `BQ_P3_tc.tex` are obsolete.
- Dependence on `lambda` is non-monotonic because the Gaussian spectral kernel acts as a low-pass filter: increasing `lambda` first removes high-wavenumber stable contributions, but sufficiently large `lambda` also suppresses unstable contributions.
- The previously-noted "rough, typo-heavy" weighted-spectrum (`g(k,t) E_eta(k)`) discussion and its red placeholder reference are **no longer present in `main.tex`** — it appears to have been cut during the consolidation into a monolithic file rather than fixed. If that physical point (how the initial spectrum controls the delay/rate of energy concentrating near QSSA-selected unstable scales) is still wanted, it needs to be re-written from scratch, not just edited.

### Variable-density results — low/moderate interpretation begun; high-Atwood interpretation remains incomplete

- For the current Overleaf upload, the three full variable-density raster colormaps formerly appearing as figures 5--7 on PDF pages 23--25 are temporarily omitted from both `sections/06_variable_density.tex` and `figures/`. This removes their complete 111-file dependency set (39 TeX fragments and 72 PNG companions); restore them from the previous Git revision if they are needed again.
- The section now opens with a short, written framing paragraph: fix `Sc=1`, vary `A_t` and `A_mu`; group the weakly/moderately stratified cases `A_t=0.05,0.4` (compared across `A_mu=-0.9,0,0.9`) and treat the strongly stratified case `A_t=0.75` separately.
- Two figures now support the weak/moderate-Atwood comparison. `VD_P1_Sc1_At005_At040_sigma_grid.tex` is the 2x3 grid of `\overline{\sigma}_{1D}(k,t)` for `A_t \in {0.05,0.4}` x `A_mu \in {-0.9,0,0.9}`. The two separately exported files `VD_P2_Sc1_At005_scaling.tex` and `VD_P2_Sc1_At040_scaling.tex` form a 1x2 figure containing only `k_*(t)t^{(1-A_t)/2}`: panels (a) and (b) correspond to `A_t=0.05` and `0.4`, and each overlays the three `A_mu` cases. The redundant raw-`k_*` panels were removed because those curves already appear as dashed loci in the 2x3 map.
- The manuscript now introduces the proposed scaling `k_*(t) \sim t^{-(1-A_t)/2}` as a hypothesis to test over a finite interval. The full record is shown through `t=25`; no collapse is claimed outside the approximately flat portion.
- The scaling-grid generator is `codes/VD_Atlt0p5/VD_P2_scaling_grid.m`. It loads `VD_postprocess_Tmax25.mat`, recomputes `k_*` from the stored growth-rate field using a fine `k` grid and finite-sample `makima` interpolation, and creates each panel independently with `TikzFigure('semilogx','1x2')` (changed from `loglog`). The two `.tex` outputs are assembled in `main.tex` using `[t]`-aligned 0.48-width minipages. Both panels use the same colors, line widths, axes, and limits; only the Atwood-dependent compensation exponent differs. **Each panel now also carries a small inset** (built with `TikzFigure`'s new `inset()` method — see the `TikzFigure.m` note under "shared numerical infrastructure") showing the corresponding raw, unscaled `k_*(t)` in the northeast corner, so the compensated main curve and its raw counterpart are both visible without a separate figure. Inset axis conventions settled this session: the inset's x-axis reuses the main panel's own `XLim`/`XTick` directly (`ax_inset.XLim = tf.ax.XLim; ax_inset.XTick = tf.ax.XTick`) so it shows the same round powers of ten (`10^{-1},10^0,10^1`) instead of computing its own ticks from `logspace(...)`, which produced ugly fractional exponents (`10^{0.2}`); the inset's y-axis is fixed to `ax_inset.YLim=[0 0.6]; ax_inset.YTick=[0 0.2 0.4 0.6]` for visual consistency across panels rather than autoscaled per-panel. The inset's `k_*` label is set via `ylabel(ax_inset,...)`, not `title(...)` (a title floats above the axis rather than aligning with it).
- The low-to-moderate subsection now also summarizes the three-dimensional mean-energy growth through the critical time `t_c(lambda)` at fixed `Sc=1` and spectral order `n=1`. The two panels `VD_P3_Sc1_At0p05_tc.tex` and `VD_P3_Sc1_At0p40_tc.tex` correspond to `A_t=0.05` and `0.4`; each overlays `A_mu=-0.9,0,0.9`, with the legend in the northeast of panel (a). Fixing `n=1` avoids expanding the parameter space when the spectral order does not change the qualitative behaviour. The generator is `codes/4_VD/VD_P3_Gmean.m`, using the common-integral-length convention `k_0(n)=sqrt(2) Gamma(n-1/2)/[lambda Gamma(n)]` and `TikzFigure(...,'1x2')` exports for these panels.
- The VD section is now divided into `Low-to-moderate stratification` (`A_t=0.05,0.4`) and `High stratification` (`A_t=0.75`). The high-stratification figure is a 2x3 map at `Sc=1`: columns are `A_mu=-0.9,0,0.9`, the first row zooms the rapid initial interval `0 <= t <= 0.5`, and the second row shows `0.5 <= t <= 15`. Each row has a shared, independently chosen color scale. It is generated by `codes/VD_Atgt0p5/VD_P1_sigma_map.m` from `VD_postprocess_Tmax15_Tmin0.5.mat`; the active outputs use `early`/`late` tags and `p` rather than decimal points in parameter filenames.
- The high-stratification `k_*`/`sigma_*` figure (`fig:VD_high_kstar_scaling`, figure 10) was **restructured this session**, no longer a raw-vs-compensated `k_*` side-by-side. Panel (a) now shows only the compensated `k_*(t)t^{(1-A_t)/2}=k_*(t)t^{1/8}` at `A_t=0.75`, `Sc=1` (all three `A_mu`), with the raw unscaled `k_*(t)` moved into an inset (same `TikzFigure.inset()` treatment and tick conventions as figure 7, above). Panel (b) is new: the evolution of the associated growth rate `\overline{\sigma}_\ast(t)` (also all three `A_mu`), plotted `loglog` (not `semilogx`, because the curves span about three decades and a log-y axis was needed to keep the smallest/largest values both legible), with the `A_mu` legend in the southeast. Both panels generated by `codes/VD_Atgt0p5/VD_P2_scaling.m` into `VD_P2_Sc1_At0p75_kstar_scaled.tex` and the new `VD_P2_Sc1_At0p75_sigmastar.tex`; the now-stale `VD_P2_Sc1_At0p75_kstar.tex` was deleted. **Diagnostic note for future reference**: an early check of `\sigma_\ast(t)` for `A_mu=-0.9` using the *precomputed* `cases.sigmamax` field (which keeps `k` up to the postprocessing's `k_plot_max=3.0`) showed an unphysical sustained blow-up to `O(10^2)` for `t \gtrsim 3.85`; this turned out to be an artifact of including high-`k` modes beyond the `kmax=0.9` cutoff used everywhere else for `k_\ast`/`\sigma_\ast` extraction (likely SSTE sampling noise at high `k`, where the modes should be viscously damped, not amplified). Recomputing `\sigma_\ast(t)` with the same `kmax=0.9` restriction (i.e. via the script's own `peak_curves(...)`, not the raw `cases.sigmamax` field) removes the blow-up entirely and gives smooth, sensible curves for all three `A_mu`. **Always use the `kmax=0.9`-restricted recomputation, never the raw `cases.sigmamax`/`cases.kstar` fields directly, when extracting `k_\ast`/`\sigma_\ast` from any `VD_postprocess_*.mat` file.**
- The high-stratification `t_c(lambda)` panel was removed because some parameter combinations have no `G^mean=1` return crossing in the available record. It is replaced by a 1x3 plot of the full `G^mean(t)` histories at `A_t=0.75`, `Sc=1`, and `n=1`: panels (a)--(c) are `A_mu=-0.9,0,0.9`, and 20 integral correlation lengths `lambda=2,...,20` progress from light gray to black with a colorbar on panel (c). All panels share the same logarithmic `G^mean` range and show `t <= 5`. The generator is `codes/VD_Atgt0p5/VD_P3_Gmean_lambda.m`; outputs are the three `VD_P4_Sc1_At0p75_Amu*_Gmean.tex` files. The obsolete `VD_P3_Sc1_At0p75_tc.tex` asset was deleted, and `codes/4_VD/VD_P3_Gmean.m` again generates only the low/moderate `t_c(lambda)` panels.
- The prose following figure 6 now interprets the low-to-moderate-Atwood viscosity trends. All six cases retain the Boussinesq sequence of initial stabilisation, neutral crossing, positive growth, and later weakening. At fixed `A_t`, increasing `A_mu` shifts `k_*(t)` and the neutral contour to larger wavenumbers and raises the post-neutral growth rate. Since `A_t>0` makes fluid 2 heavier, `A_mu<0` makes the lighter fluid more viscous; the resulting stronger small-scale damping lowers the peak `k_*` and selects a larger horizontal scale. The ordering reverses for `A_mu>0`, consistently for `A_t=0.05` and `0.4`. The strongly stratified `A_t=0.75` figures still need substantive interpretation and comparison with the Boussinesq limit.
- Underlying numerics exist and are more complete than the text: `codes/VD/` (At in {0.05,0.40,0.50,0.75}, Amu in {-0.90,0,0.90}, Sc in {1,5,40}, 29 precomputed `.mat` files in `codes/output_VD/`) plus narrower exploratory splits in `codes/VD_Atlt0p5/` and `codes/VD_Atgt0p5/`. Writing the VD results section is a matter of mining this existing output, not generating new runs.

## Appendix content

- Appendix A (`app:operators`, "Continuous linearized operators") lists the continuous variable-density operator blocks, including density--viscosity coupling and the linearized divergence operator.
- Appendix B (`app:small_atwood_limit`, "Small-Atwood-number limit") recovers the Boussinesq scalar and momentum equations as `A_t -> 0`, introduces the rescaled scalar `chi_0 = 2c_0 - 1` (NOT the same `c_0`/`chi_0` swap discussed below), and argues that an Atwood-scaled Froude number `Fr_g` is required to keep buoyancy finite as `A_t -> 0`. The title typo flagged previously is fixed; the section title is now spelled correctly.
- Appendix C (`sec:appendix_main`) contains, in order: the necessity of SSTE (`sec:appendix_necessity_sste`), the three verification cases (`sec:appendix_verification`: GL, Poiseuille, non-autonomous OU/heat), and the full weighted loop-adjoint derivation (`sec:appendix_loop_adjoint`).
- There is still no conclusion section anywhere in the manuscript (confirmed by grepping for "conclusion" — the only hit is an unrelated use of the word "conclusions" in body prose).

## Manuscript structure and active files

The active paper is split between `draft/main.tex` and the section files under `draft/sections/`; the older standalone fragments under `draft/old_tex_do_not_erase/` are archival. Figure inputs load generated files from `draft/figures/` using paths such as `\input{figures/BQ_P3_sigma_map.tex}`.

Important files are

- `main.tex`: sole active manuscript source;
- `references.bib`: bibliography database;
- `main.pdf`: local-only compiled paper (42 pages as of 2026-08-27 after removing the obsolete budget grids and temporarily omitting the post-page-20 variable-density colormaps); it is ignored and is not pushed;
- `info_project.md`: this living memory;
- `old_tex_do_not_erase/`: archived section sources, not active;
- `999_useful_stuff.tex`: inactive scratch/reference material;
- `main_template_original.tex`: original template, not active;
- `figures_pdf/`: 93 active externalized figures are tracked as `.pdf`/`.md5`/`.dpth` triples, together with `README.txt`; logs and obsolete cached figures are not tracked;
- `tikz-cache/`: local cached figure compilation products, ignored and never pushed;
- `initial_condition.tex`, `bq_section.tex` (if present): **orphaned**, no longer `\input`-ed by `main.tex` — see above.

The `codes/` and `presentation/` directories are siblings of `draft/` and remain outside the manuscript repository. The tracked manuscript figures live at `draft/figures/`, and the paper should be compiled from inside `draft/`.

### `codes/` directory map (surveyed in full this session)

Theory/eigenvalue generation (most actively maintained):
- `codes/3_BQ/`: active Boussinesq postprocessing pipeline. Raw production cases use `data/delta<delta>/Sc<Sc>/`, and `P0_preprocess.m` mirrors them into `output/delta<delta>/Sc<Sc>/`. These trees contain only the converged `Lz=600`, `Nz=256`, `bfrac=0.25` calculations, so production scripts no longer encode grid tags in their paths or output metadata. `P1_colormap.m` generates the two 1x3 Schmidt-number and initial-thickness maps, `P2_dns_compare.m` generates the DNS comparison, `P3_colormap_IVP_vs_QSSA.m` generates the IVP and QSSA maps, `P5_delta_effect.m` and `P6_sigma_colormap.m` are exploratory diagnostics, and `P7_growth_3D.m` computes the spectrum-integrated growth using `E2D.m`. The unsupported `P4_scaling.m` remains removed.
  - `codes/3_BQ/convergence/` is a self-contained sandbox. Its grid-tagged raw trees live only under `convergence/data/`, and `C0_k0_convergence.m` reads only that local directory. It currently compares `Lz_150_Nz_128_bfrac0.25` with `Lz_600_Nz_256_bfrac0.25`. Nothing in the production pipeline reads convergence data.
  - The reorganized pipeline was verified on 2026-08-11 by running `P0`, `P1`, `P2`, `P3`, `P5`, `P6`, `P7`, and the convergence script sequentially. All nine production cases were regenerated under `output/`, and `E2D.m` was exercised through `P7`. The old grid-tagged processed tree was archived recoverably at `/tmp/3_BQ_postdata_legacy_20260811` during the migration.
  - `P3_colormap_IVP_vs_QSSA.m` builds the QSSA companion map by looping over frozen times, setting `delta_0=sqrt(d0_data^2+4t0/Sc)`, rebuilding `alpha` through `lib_solver_BQ.find_sinh_alpha`, and taking the leading generalized eigenvalue from `lib_solver_BQ.build_operator_BQ(...,idot=0)`.
  - **pgfplots gotcha worth remembering**: a `\node` manually placed inside `\begin{axis}...\end{axis}` at a position outside the data range (e.g. the `(a)`/`(b)` panel-label node at `rel axis cs:-0.15,1.1`) is invisible by default, even with the `overlay` key — pgfplots' default `clip mode=path` applies one clip path to *everything* drawn inside the axis, and `overlay` only exempts a path from the bounding-box calculation, not from an active clip. The fix used here is `clip=true, clip mode=individual` in the axis options, which clips only `\addplot` paths individually and leaves bare `\node`s unclipped. `matlab2tikz`/`TikzFigure` output already sets this by default (which is why `jfm_labels` panel tags "just work" there); hand-rolled pgfplots wrappers like this one's `export_sigma_colormap` do not get it for free.
  - Side-by-side two-panel figures built from two independently-generated `.tex` files inside `0.48\textwidth` minipages need `\begin{minipage}[t]{...}` (top-aligned) on **both** minipages in `main.tex`, or the panels can end up vertically misaligned/differently sized on the page even though each pgfplots axis specifies identical `width`/`height` — three other multi-panel figures in `main.tex` already use `[t]` for this reason; `fig:BQ_P1_sigma_map` was missing it and has since been fixed.
  - The `schmidt_towne_white_map(m)` local helper (the PuOr-style diverging colormap used by the PNG rasterizer) was found dropped from `BQ_P1_sigma_map.m` mid-session (likely an external edit) and was restored; if `Unrecognized function or variable 'schmidt_towne_white_map'` reappears, it needs re-adding at the end of the script, not debugged as something else.
- `codes/4_VD/`: variable-density counterpart, **reorganized on 2026-08-11** onto the same convention as `3_BQ` and no longer matching the older description in this file. Scripts are now `P0_preprocess.m`, `P1_colormap.m`, `P2_Atwood_effect.m`, `P3_Atwood_effect_kstar.m`, `P4_delta_effect.m`, `P5_sigma_colormap.m`, `P6_growth_3D.m`, plus `E2D.m`.
  - **No grid tags anywhere in the production pipeline.** Domain height and resolution were converged once in `3_BQ`, so `4_VD` is treated purely as a post-processing folder. `Lz`/`Nz`/`bfrac` and the `grid_tag`/`postdata` machinery were removed from all six P-scripts, including from the saved `.mat` metadata and the figure titles. Raw cases live in `data/delta<d>/` (flat, 45 cases each for `delta1.00`, `delta2.00`, `delta5.00`; At in {0.01,0.10,0.20,0.50,0.75} x Amu in {-0.90,0,0.90} x Sc in {0.25,1,10}), and `P0_preprocess.m` mirrors the input folder layout into `output/delta<d>/`. Rename or re-nest `data/` and `P0` follows without edits.
  - Consumers no longer navigate `d%.2f/Sc%g` folders. `P1`--`P5` do one recursive glob over `output/` and select cases from the At/Amu/Sc/d tokens already present in each filename, so the folder layout underneath is free to change. `P6_growth_3D.m` deliberately still reads raw `data/` because the quadrature needs the untruncated `k` grid and its `wr_k` weights, which `P0` clips at `k_plot_max`.
  - `convergence/` was left grid-tagged on purpose: comparing grids is that sandbox's whole function.
  - Superseded material was quarantined, not deleted, at `codes/4_VD/_old_2026-08-08/` (9 raw duplicate cases + 18 stale preprocessed files from the two old grid trees). It sits outside `data/`, so `P0`'s recursive glob does not see it.
- `codes/VD_Atlt0p5/`, `codes/VD_Atgt0p5/`: narrower At-regime splits of the VD postprocessing. `VD_Atlt0p5/` is now the active source for the two weak/moderate-Atwood figures in the manuscript; `VD_Atgt0p5/` remains exploratory.
- **Exploratory, not yet settled**: `codes/VD_Atgt0p5/debug_sigmastar_fit.m` and `codes/3_BQ/debug_sigmastar_fit.m` are scratch scripts (not manuscript sources) trying to fit a proposed closed-form law `\sigma_\ast(t) = \sigma_0 + 0.5 L - (\alpha/4) L^2` with `L=\log(1+2t)` (VD version additionally divides `\alpha` by `(1+A_\mu)`) to the numerical `\sigma_\ast(t)` curves. Because the model is linear in `[1, L^2]` once `0.5L` is subtracted, both scripts fit `\sigma_0`/`\alpha` by ordinary least squares (`X\z`, no optimizer needed) rather than `fminsearch`/`lsqcurvefit`. Findings so far, not yet resolved: the fit tracks the rise and the peak location reasonably well, but the data plateaus at late time while the model's `-\alpha/4 L^2` term keeps decreasing it, so any full-range fit undershoots for `t` past the peak; for the VD case, the fitted `\alpha` did not come out cleanly proportional to `(1+A_\mu)` as the proposed law assumes (and division by `1+A_\mu` for `A_\mu=-0.9` strongly amplifies that estimate's sensitivity). The BQ version is being actively edited (currently single-`At=0.50`, no loop, adjustable `Tmin`/`Tmax` window, experimenting with `L=\log(1+20t)`) — check its current parameters directly before assuming any specific result from it.
- `codes/2_Initial_spectrum/`: `spectrum_2D.m` generates the active `n=1,2,3` correlation/spectrum family figure and labels the physical-space coordinate with `lambda_0`. The previously recorded `spectrum_3D.m` source is not currently present in the reorganized tree.

DNS-vs-theory comparison studies, all now collected under **`codes/0_DNS_STAT_LST_compare/`** (moved there from directly under `codes/` in this session; every script's internal relative path to `figures/`, `output_BQ/`, `output_VD/`, and `presentation/figures/` was updated for the extra nesting level and re-verified by running the key scripts and recompiling `main.tex`):
- `compare_1` (Sc sweep), `compare_2` (k0 sweep), `compare_3` (E0 sweep, 22 subdirs), `compare_4` (kmax sweep), `compare_5` (kmin sweep), `compare_BQVD` (small early BQ-vs-VD check): all early/exploratory parameter sweeps (mid-May), each with its own `compare_Gmean.m` and case directories of `ensemble/seed_*/data/*_std.dat`.
- `compare_autonomous/`: autonomous-vs-non-autonomous comparison (k0 sweep, At=0.5, Sc=1); superseded by `compare_finale` for the manuscript figure. References its sibling `compare_finale/` directly (`fullfile(root,'..','compare_finale')`) — this sibling relationship is preserved by the group move, so it needed no path change beyond the shared `output_BQ`/`presentation` references.
- `compare_pdf/`: ensemble energy-PDF analysis (built with this assistant) — `build_energy_ensemble.m` + `plot_pdf_snapshots.m`, plus a small `report/main.tex` bundling the figures for a PI update on whether DNS variance/PDF tails justify the statistical framing (motivated by an email thread with Aaron Towne). From that report, `\figdir` points to `../../../../draft/figures`.
- `compare_finale/`: **the current, most up-to-date comparison study** (`compare_finale_Gmean.m` last touched 2026-06-22, the same day as this update). The manuscript comparison uses `k_0={0.4,0.8,1.2,1.6}` at `A_t=0.5`, `Sc=Re=1`, with ten statistically independent seeds per case and 40 simulations in total. Its output `compare_finale_dns_predictions.tex` is the DNS-vs-SSTE panel used in the manuscript's figure `fig:compare_dns`(a).

Path-fixing note for future moves: most scripts build `figures`/`output_BQ`/`output_VD` paths via a literal `fullfile(root, '..', '..', X)`-style relative chain from the script's own folder, which breaks by exactly one missing `..` whenever the script gains/loses a directory level — always re-grep for `fullfile(root`/`fullfile(script_dir`/`fileparts(root)` patterns after restructuring. The exception is `compare_2`/`compare_3`/`compare_4`'s `find_gmean_dir()` helper, which walks up the directory tree looking for a `codes/output_BQ` subfolder and is depth-independent (self-healing) — it does not need fixing after a move.

Verification suite (`codes/verification/`): four numbered problems, `0_Unit_Test/` (algorithm-level checks: adjoint symmetry, quadrature resolution, kmin/kmax tail tolerance, Hutch++ sample-count sensitivity), `1_giz_landau/` (GL trace/diag), `2_poiseuille/` (Poiseuille trace/diag), `3_nonautonomous/` (OU scalar + non-autonomous heat equation, trace only) — these three (GL, Poiseuille, non-autonomous scalar) are the ones described in the manuscript appendix. `4_IVP/` is a fourth, full-RTI end-to-end IVP check not yet mentioned in the manuscript text (see Verification strategy above).

Misc: `codes/debug/` (scratch diagnostics, low priority), `codes/utils/` (`dmsuite/` differentiation matrices, `get_fig_folder.m`, `GL_operator.m` — shared helpers).

The shared numerical infrastructure is in `/home/yobh/core_codes`. In particular, `lib_solver_BQ.m` builds the Boussinesq generalized eigenproblem and energy weights, `TikzFigure.m` is the standard MATLAB-to-pgfplots figure exporter used by essentially every plotting script above (palettes: `matlab`, `jfm`, `bright`, `gray`, `puor`, and now `prgn`), and `stepping_trace.m`/`stepping_diag.m` provide matrix-free time-stepping estimators.

**`TikzFigure.m` gained a working `inset(pos)` feature this session** (used by figure 7 and figure `VD_high_kstar_scaling`/10, see "Variable-density results"). `inset([x y w h])` creates a second MATLAB axes (return value is the axes handle, so plot into it directly, e.g. `semilogx(ax_inset, ...)`) sized as a fraction of the figure given by `[x y w h]`, with `(x,y)` only used to pick which corner of the main panel to dock against (>=0.5 in either coordinate picks the far corner) — it does not set the literal inset position once exported. This had been dead code before (present but unexercised); making it actually work required several fixes inside `export(obj,name,folder)`, all are general `matlab2tikz` gotchas worth remembering for any future inset use:
- `matlab2tikz`'s `extraAxisOptions` argument is applied identically to **every** axes in the figure, so the inset was inheriting the main panel's `width`/`height`/font-size overrides verbatim. Fixed by stripping those from the inset's emitted block and substituting an explicitly computed smaller size (`mainWfrac/Hfrac .* insetPos(3:4)`) and a shrunk `\fontsize{}{}`.
- `matlab2tikz` emits axes in MATLAB's most-recently-created-first order, so the inset (created after the main axes via `inset()`) becomes the **first** `\begin{axis}...\end{axis}` block, main panel second — but pgfplots can only resolve `at={(ax_main.<corner>)}, anchor=<corner>` if `ax_main` (defined via `name=ax_main` in the main axis's own options) was already emitted **earlier** in the picture. `export()` therefore swaps the two blocks before writing the file: main axis (with `name=ax_main`) first, inset (referencing it) second.
- A blank line left inside an `\begin{axis}[...]` options list is read by TeX as `\par`, producing "Paragraph ended before \pgfplots@@environment@axis was complete." — easy to reintroduce when splicing text with regex; collapse stray blank lines defensively after any text surgery on the options block.
- `name=ax_main,` written directly after `\begin{axis}[%` (no intervening newline) gets silently swallowed by the `%` end-of-line comment — always prepend a newline.

A practical consequence for any panel using `inset()`: matching the inset's tick *count* to the main panel is straightforward (`numel(tf.ax.XTick)`), but matching tick *values* needs the main panel's actual `XTick`/`XLim` copied onto the inset (`ax_inset.XLim = tf.ax.XLim; ax_inset.XTick = tf.ax.XTick`) rather than recomputed from the inset's own autoscaled range, or the inset ends up with ugly non-integer log-exponent labels (`10^{0.2}`) instead of round powers of ten. The related `/home/yobh/Desktop/1_LST_draft` project contains verified frozen-base/QSSA growth-rate workflows and a Boussinesq comparison with Chandrasekhar's sharp-interface dispersion relation. The project-root `tmp.m` is a disposable diagnostic that builds the leading Boussinesq QSSA growth rate directly from `lib_solver_BQ` (currently a minimal omega(k) computation + plain plot, no LaTeX/figure export); it is not an active manuscript source and gets rewritten/deleted between sessions.

## Notation to preserve

- `\Atw` for density Atwood number `A_t`.
- `\Amu` for viscosity Atwood number `A_mu`.
- `\Sch` for Schmidt number `Sc`.
- `\Gm` for `G^mean`.
- `\overline{\sigma}_{1D}(k,t)` for the per-wavenumber mean growth-rate field and `\overline{\sigma}_{3D}(t)` for the spectrum-integrated mean growth rate.
- `k_\ast(t)` for the wavenumber maximizing `\overline{\sigma}_{1D}` at fixed time, and `\overline{\sigma}_\ast(t)=\overline{\sigma}_{1D}(k_\ast(t),t)` for the corresponding maximum value. Never write `\overline{\sigma}_\ast(k_\ast,t)` or `\overline{\sigma}_{\max}(t)` for this quantity.
- `\mean{...}` for ensemble averages.
- `\tr` for trace.
- `C_{00}^z` for the vertical covariance factor.
- `C_{00}^{xy}` for the horizontal interface-displacement correlation.
- `E_\eta(k)` for the circularly integrated two-dimensional interface spectrum.
- `\lambda_0=2\sqrt{2}/k_0` for the Gaussian-envelope/reference scale of the canonical family.
- `\lambda` for the integral correlation length. The active three-dimensional results fix `n=1`, for which `\lambda=(\sqrt{\pi}/2)\lambda_0` and `k_0=\sqrt{2\pi}/\lambda`; the general numerical utility still uses `k_0(n)=\sqrt{2}\,\Gamma(n-1/2)/[\lambda\Gamma(n)]`. Do not introduce an order-dependent `\lambda_n`. The three-dimensional Boussinesq results no longer repeat this definition and instead refer directly to the previously defined `n=1` spectrum.
- `\boldsymbol{\Phi}_{t,k}` for the propagator from the initial time to `t` at wavenumber `k`.
- `\mathsfbi{W}_k` for the discrete energy weight.
- `\LDA` for the matrix-free loop-direct-adjoint action.

Do not blur ensemble averages with weighted inner products. Keep Boussinesq concentration `c` distinct from variable-density perturbation `rho`; a generic discussion should say explicitly which model is meant.

The two-dimensional canonical-family figure (correlation `C_{00,n}^{xy}(r)` and spectrum `E_{eta,n}^{2D}(k)`, n=1,2,3) lives at `\label{fig:eta_2d_family}` in the "Statistics of the initial perturbations" section, generated by `codes/2_Initial_spectrum/spectrum_2D.m` into `figures/corr2D_plot.tex` and `figures/spectra2D_plot.tex`. Its correlation panel is normalized by `r/lambda_0`.

## Current draft status as of 2026-06-24 (re-verified this session)

The manuscript compiles successfully, but **a plain `latexmk -pdf main.tex` is not the right invocation for this project** — the VSCode LaTeX Workshop setup used to edit this manuscript keeps `main.pdf`/`main.synctex.gz` at the top level but redirects all `.aux`/`.bbl`/`.fls`/`.log` into a separate `.auxiliary/` subdirectory (`latex-workshop.latex.auxDir` in the user's VSCode settings). Running plain `latexmk main.tex` from the command line creates a second, stray, empty set of top-level `.aux`/`.bbl`/`.blg` files that have no citations in them yet, which makes latexmk try to run `bibtex` prematurely and fail ("I found no \citation commands"). The correct command-line invocation, matching the IDE's own recipe, is

```bash
cd /home/yobh/Desktop/2_DGG_draft/draft
latexmk -synctex=1 -interaction=nonstopmode -file-line-error -pdf -bibtex main.tex
```

Keep the auxiliary files at the project root. TikZ externalization writes its cache metadata relative to the output directory, so a separate `.auxiliary/` output directory causes fresh-cache builds to fail with `I can't write on file figures_pdf/...md5`. This root-level layout also matches the verified Overleaf-style build.

The verified output is **42 pages** as of 2026-08-27. `showkeys` is enabled for drafting, so labels appear in the margins. The manuscript now has functioning Git history rooted at `draft/`; commit coherent edits there so accidental reversions can be recovered.

### Clearly unfinished writing

- The abstract is still the literal placeholder `abstract`.
- The introduction still ends with `the present work develops ...` and has no completed contribution/road-map paragraph.
- There is still no conclusion section.
- The Boussinesq weighted-spectrum discussion (`g(k,t) E_eta(k)`) is **gone, not fixed** — it was apparently removed during the flattening into a monolithic `main.tex` rather than rewritten. Re-add deliberately if the physical point is still wanted.
- The variable-density section now has low-to-moderate and high-stratification subsections, the original 2x3 growth-rate maps, low/moderate compensated-`k_*` scaling tests, a low/moderate `t_c(lambda)` comparison at fixed `n=1`, a separate early/late 2x3 figure for `A_t=0.75`, a raw/compensated high-Atwood `k_*` comparison, and three full high-Atwood `G^mean(t)` panels. It still lacks the full scientific interpretation of the viscosity trends and comparison with the Boussinesq limit.
- Appendix B's title is no longer misspelled (fixed since the last note). Its derivation prose is still draft-style but functionally complete (small-Atwood-limit reduction is fully worked through to the reduced Boussinesq vertical-momentum equation).

### Annotated-PDF corrections applied to the theory sections (2026-06-24)

The corrections from the marked-up `main.pdf` were applied in `draft/main.tex` and the manuscript was recompiled successfully to **39 pages** with the standard command above.

Settled changes:

- The Boussinesq equations in the main text are now coefficient-normalized: the explicit `2 A_t` prefactor was removed from the nonlinear buoyancy term and from the reduced Boussinesq linear operators.
- `eq:bq_base_state` now uses the mixture-fraction profile `c_0(z,t) = (1/2)(1 - erf(z/delta(t)))`.
- The explanatory paragraph saying that `A_t` remains in the Boussinesq buoyancy force was removed.
- State vectors in the governing-equation sections now use tuple/column-vector notation, e.g. `(w,c)^\top`, rather than square-bracket shorthand.
- The variable-density base state is no longer described as a “quiescent horizontal flow”; it is a one-dimensional flow `(0,0,w_0)` with density `rho_0`.
- The energy section now explicitly applies to both Boussinesq and IVD models.
- The reduced kinetic-energy expressions and the IVD disturbance-energy norm now use the positive `+ k^{-2}|...|^2` contribution, consistent with positive-definite energy weights.
- The mean-growth normalization now uses the initial energy denominator `tr{C_00^z W_k}` in both `eq:modal_energy_growth` and `eq:T_operator_definition`.
- The trace operator in the main randomized-trace section is now written as `T_{t,k} = Phi_{t,k}^* W_k Phi_{t,k}`.
- `per-mode` wording was changed to `per-wavenumber`, and the RNLA sentence now says Frobenius norm/trace are related “equivalently.”
- The initial-displacement notation now defines and uses `x_h=(x,y)` consistently, with `k_h=(k_x,k_y)` for the corresponding horizontal wavevector.

Open review flag: Appendix B still contains the small-Atwood-limit derivation with its own `chi_0=2c_0-1` notation and Froude/Atwood scaling. It compiled, but it has not yet been re-derived after removing the explicit `2 A_t` coefficient from the main Boussinesq equations. Re-read this appendix before treating the asymptotic reduction as final.

### Current unresolved build items (re-confirmed against `main.log` this session)

- No real LaTeX errors, undefined references, or undefined citations were found by grepping `draft/.auxiliary/main.log` after the compile.
- BibTeX still reports only metadata warnings in existing entries (`chandrasekhar-1961`, `reynolds-1883`, `schmid-henningson-2001`); these do not block the build.
- The generated variable-density figure wrappers still produce the known `Missing character ... nullfont` warnings and some overfull boxes. These appear to come from generated tikz/figure files and were already present before this correction pass.

### Mathematical and notation checks before treating formulas as final

These are review flags, not corrections already authorized:

1. **Still open.** The main nondimensionalization sets the Froude number to unity (eq. `chandrasekhar_scaling`), whereas Appendix B introduces `Fr_g^2 = A_t * Fr_{A_t}^2` (with `Fr_{A_t}^2=1` chosen) to obtain a nontrivial small-Atwood limit. This scaling and its relationship to the coefficient-normalized main-text Boussinesq equations should be reconciled explicitly.
2. Checked this session: there is no `\mathcal{A}` left anywhere in `main.tex` (only `\mathscr{A}`, used consistently) and `\Rey` (not bare `Re`) is used consistently for the Reynolds number. Do not re-attempt the old `chi_0 -> c_0` rename unless explicitly asked; that change was attempted and deliberately reverted earlier.
3. The Gaussian-correlation references now point consistently to `eq:eta_correlation_family_examples`.
4. **VD `k_*` scaling is only locally supported and should not yet be presented as asymptotic.** A direct log--log fit for `A_t=0.05`, `Sc=1`, `A_mu=0` gives `k_* ~ t^{-0.496}` over `10 <= t <= 15`, so the proposed Boussinesq-like exponent is recovered in that window and `k_* t^{0.475}` is nearly flat (residual slope `-0.021`). Earlier windows remain transient (`-0.79` over `2 <= t <= 10`), while after `t=15` the maximum becomes too broad to locate robustly: for example, at `t=20` all `k` from approximately `0.043` to `0.073` lie within 1% of the peak growth rate. The `A_mu=+-0.9` cases are not Boussinesq-like despite small `A_t`, because their viscosity contrast remains order one. `VD_P2_scaling_grid.m` now consistently loads `VD_postprocess_Tmax25.mat` and plots the full range through `T=25`; its caption explicitly describes a finite scaling interval rather than a collapse over the entire record. The existing BQ numerical `k_*` curve itself does not sustain a `-1/2` fitted slope over the sampled late-time windows, so the manuscript's `t^{-1/2}` line should be described as a scaling guide unless a more appropriate asymptotic diagnostic is established.

## Session log 2026-08-11: VD pipeline, section split, figure caching

### `codes/4_VD` post-processing changes

- `P0_preprocess.m`: `k_plot_max` raised from `2.0` to `3.0` (the raw `k_wave_vec` runs to exactly 3.0 with 130 nodes, so this now uses the full available range). The `G_noise_floor = 1e-14` clamp was **removed** in favour of the masking that `3_BQ/P0_preprocess.m` already uses (`pos = G > 0; logG = nan(...); logG(pos) = log(G(pos))`). Clamping flattened `log(G)` over the decayed tail, which turned the centred difference into exactly zero and painted a band of fake neutral growth across the map, drew spurious black contours along the edge of the clamped region, and let those `sigma = 0` points win the max over `k` while the flow was still stable everywhere. `convergence/C0_preprocess.m` was changed to match. `P6_growth_3D.m` still clamps `G3D` at `1e-12`, which is **not** a VD/BQ inconsistency: `3_BQ/P7_growth_3D.m` does the same.
- **`k = 0` is excluded** in `P0_preprocess.m` (`k_keep = (k_vec <= k_plot_max) & (k_vec > 0)`), matching `3_BQ`, the comment above that line, and `convergence/README.md`: the energy norm at `k = 0` drops the `1/k^2` horizontal-velocity term and so is a different functional. It was briefly retained on 2026-08-11 and then reverted after seeing the consequences, which are worth recording because they are the signature of this bug reappearing: `kstar` pins to exactly `0` for every case and every panel opens with a vertical jump off zero, and `sigmastar` is dominated by the zeroth mode (peak ~13 at `At = 0.75` against ~0.35 once `k = 0` is dropped). `sigmamax` was verified to equal `max_k sigma` exactly after the fix.
- `P1_colormap.m`: now emits one **3x3** figure per Schmidt number, rows over `At_list`, columns over `Amu_list`, both explicit lists at the top rather than "whatever is present". Each panel carries its own title `$\mathrm{A_t}=..,\; \mathrm{A}_{\mu}=..$`. `d_fix = 2.00`. Sampling was reduced from the BQ values to `nk_smooth = 300`, `field_pix = [450 350]`, `max_pts = 200` so the panel count stays cheap to compile.
- `P1_colormap.m` gained a **per-Sc override map**, because the three Schmidt numbers genuinely do not share a colour scale or a time window. Measured at `delta_0 = 1` over the At/Amu sweep: positive `sigma_max` is 0.177 / 0.287 / 0.366 for `Sc = 0.25 / 1 / 10`, onset spans `t = 2.4-6.2 / 0.9-2.0 / 0.14-0.40`, and the peak of `sigmamax` sits at `t = 9.6-14.4 / 2.8-6.4 / 1.6-2.2`. The negative side reaches `-15` to `-20` at every `Sc` and always saturates. Current settings are `Sc=0.25 -> clim +-0.2, t_max 30, T_zoom 8, k_max 2`; `Sc=1 -> clim +-0.5, t_max 15, T_zoom 2, k_max 3`; `Sc=10 -> defaults (clim +-0.5, t_max 15, T_zoom 2, k_max 2)`. Because the colour range now varies, the shared colorbar was replaced by one per Schmidt number (`sigma_map_VD_colorbar_Sc_<tag>.tex`).

### Manuscript structure

`main.tex` is **no longer monolithic** — the "sole active manuscript source" description elsewhere in this file is out of date. Text now lives in `draft/sections/`: `01_introduction`, `02_governing_equations`, `03_statistics_initial_perturbations`, `04_perturbation_energy`, `05_results_boussinesq`, `06_variable_density`, and the `09`--`11` appendices. Numbering has shifted at least once (`07_results_boussinesq` -> `05_...`, `08_results_variable_density` -> `06_variable_density`), so always check the actual filenames before editing.

`06_variable_density.tex` was **stripped of all prose** on 2026-08-11 because its write-up described the earlier `At = 0.05 / 0.40` sweep and was judged obsolete and mostly wrong. It now contains only the section heading and the three 3x3 sigma-map figures. The previous content, including the old `VD_P1`--`VD_P4` floats, is preserved verbatim at `sections/06_variable_density.OLD.tex` — nothing was lost, and that file is the place to look before rewriting the variable-density discussion.

### Figure compilation: tikz externalization

Recompiling 27 pgfplots panels from source cost 24-26 s per build. Figures are now **externalized**, which took the steady-state build to about 0.1 s. Three lines in `main.tex`:

```latex
\usetikzlibrary{external}
\tikzexternalize[prefix=figures_pdf/]
\newcommand{\tikzfig}[1]{\tikzsetnextfilename{#1}\input{figures/#1.tex}}
```

Figures are drawn with `\tikzfig{name}` instead of `\input{figures/name.tex}`. The first compile writes `draft/figures_pdf/<name>.pdf`; later compiles include that PDF. Points worth remembering:

- **`-shell-escape` is required.** `draft/.latexmkrc` sets it, so `latexmk` and the editor's build both pick it up with no further configuration.
- **The cache must live inside `draft/`.** Externalization writes its `.md5` files relative to the output directory. Pointing the prefix at `figures/figures_pdf/` complicates auxiliary-directory builds, so the prefix is `figures_pdf/`. Git and ZIP imports do not preserve empty directories, and Overleaf refuses to write externalized files unless the target folder already contains a file. The tracked `figures_pdf/README.txt` is therefore required. Exactly 93 active cache triples are force-added: each contains the PDF plus the small `.md5` and `.dpth` files TikZ needs to reuse it. The 41 automatic local names `main-figure0`--`main-figure40` are stored as `output-figure0`--`output-figure40`, matching Overleaf's forced job name. `.gitignore` continues to exclude every cache log, local `main-figure*`, auxiliary file, and obsolete cache entry.
- **Keep generated TikZ within Overleaf's editable-text allowance.** The 36 `sigma3D_VD_*.tex` panels once used 250 samples per curve and occupied about 4.91 MB by themselves. `codes/4_VD/P3_growth_3D.m` now uses `max_pts = 100`, which preserves smooth quarter-page-width curves while reducing those panels to about 2.05 MB and the complete tracked editable payload to about 3.67 MB (3.50 MiB). Do not raise that sampling cap without rechecking the total against Overleaf's 7 MB project limit.
- **VS Code / LaTeX Workshop needed `latex-workshop.latex.auxDir` changed from `%DIR%/.auxiliary` to `%DIR%`.** With a separate aux directory, externalization looks for `.auxiliary/figures_pdf/`, which does not exist, and the build dies with ``I can't write on file `figures_pdf/....md5'``. This is the single setting that made ctrl+alt+B work.
- **Staleness is handled in `draft/.latexmkrc`.** The library decides freshness from an md5 of the picture body, which covers `figures/<name>.tex` but *not* the PNGs that body references, so a figure regenerated by MATLAB could leave a stale cached PDF behind. The rc file therefore scans `main.tex` and `sections/*.tex` for `\tikzfig{...}`, and for each one deletes the cached PDF (and its `.md5`) when it is missing, older than its `.tex`, or older than any `figures/<name>-*.png`. Two traps found while building this: latexmk does not track the cached PDFs, so deleting one is not by itself a reason to rerun and the sweep must also remove `main.pdf` to force the pass; and the sweep has to be driven from the `\tikzfig` calls rather than from `figures_pdf/*.pdf`, since globbing the cache cannot notice a PDF that is absent. Verified against five cases: missing PDF, no change, PNG touched, source touched, and return to steady state.
- Externalization also captures the small `\solidlegend`/`\dashlegend` snippets in captions, so the cache holds more PDFs than there are figures (69 for 30 figures at the time of writing).
- A clean build with no `\cite` anywhere fails under `-bibtex` ("I found no \citation commands"). Resolved by keeping at least one citation in the active text.

### Known figure defects, not yet fixed

- The `Sc = 0.25`, `At = 0.1`, `Amu = 0` panel shows vertical dash-dot spikes across the full height: before onset the field is nearly flat in `k`, so `argmax` jumps erratically between timesteps. `kstar` needs masking where `sigmamax <= 0`.
- The bottom-left `Sc = 0.25` panel loses its last x tick label ("3" instead of "30") to the crop.
- Raising `k_max` to 3 at `Sc = 1` did not achieve what it was meant to: the inset still overlaps the unstable region for `At = 0.75`, and roughly 80 per cent of each panel is now empty. Moving `inset_pos` (currently `[0.56 0.60 0.36 0.32]`) is more likely to help than extending the axis.

## Sensible next drafting priorities

1. Reconcile Appendix B's small-Atwood-limit scaling with the coefficient-normalized Boussinesq equations in the main text.
2. Write the scientific interpretation of the strongly stratified variable-density figures, especially the viscosity-contrast trends in the `A_t=0.75` early/late maps and their relationship to the Boussinesq and low/moderate-Atwood results.
3. Decide whether to re-add a (rewritten, not rough) version of the Boussinesq weighted-spectrum (`g(k,t)E_eta(k)`) discussion that was dropped during consolidation, or treat its removal as final.
4. Complete the introduction's contribution paragraph and write an abstract only after the final claims are stable.
5. Add a conclusion, then perform the final style/figure pass (missing-character and overfull-box warnings in the VD figure wrappers).

## Maintenance rule for this file

After each meaningful work session, update the date and only the sections affected by the work. Record settled decisions as settled, preserve unresolved scientific issues as explicit review flags, and remove stale statements immediately when `main.tex` changes. `main.tex` remains the source of truth when this file and the manuscript disagree.
