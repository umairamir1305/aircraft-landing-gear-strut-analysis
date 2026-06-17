%% Landing Gear Strut Pre-FEA Checks + Parametric Study
% Purpose 1: Buckling check
% Purpose 2: Analytical stress FEA validation baseline
% Purpose 3: Wall thickness parametric sweep
clc; clear; close all;

%% INPUTS
MTOW = 1100; g = 9.81; n = 2.5; SF = 1.5; gear_frac = 0.60;
OD = 80e-3; t = 5e-3; L = 400e-3;
E = 71.7e9; sigma_y = 503e6; sigma_ult = 572e6;

%% LOADS
F_static  = MTOW * gear_frac * g;
F_limit   = n * F_static;
F_ult     = SF * F_limit;
fprintf('F_static  = %.1f N\n', F_static);
fprintf('F_limit   = %.1f N  (yield check load)\n', F_limit);
fprintf('F_ult     = %.1f N  (ultimate check load)\n\n', F_ult);

%% SECTION PROPERTIES
ID = OD - 2*t;
I  = pi/64 * (OD^4 - ID^4);
A  = pi/4  * (OD^2 - ID^2);
c  = OD/2;
fprintf('Inner diameter = %.1f mm\n', ID*1000);
fprintf('I = %.4e m^4\n', I);
fprintf('A = %.4e m^2\n\n', A);

%% PURPOSE 1 EULER BUCKLING CHECK
P_cr = (pi^2 * E * I) / (1.0 * L)^2;
fprintf('=== BUCKLING CHECK ===\n');
fprintf('P_cr     = %.0f N  (%.0f kN)\n', P_cr, P_cr/1000);
fprintf('F_ult    = %.0f N  (%.0f kN)\n', F_ult, F_ult/1000);
fprintf('Margin   = %.1fx above ultimate load\n\n', P_cr/F_ult);
if P_cr > 3*F_ult
    fprintf('RESULT: Buckling NOT governing. Proceed with stress FEA.\n\n');
else
    fprintf('WARNING: Low buckling margin. Review geometry.\n\n');
end

%% PURPOSE 2 ANALYTICAL STRESS (FEA VALIDATION TARGET)
M           = F_limit * L;
sigma_b     = (M * c) / I;
sigma_a     = F_limit / A;
sigma_comb  = sigma_b + sigma_a;
Kt          = 1.4;
sigma_corrected = sigma_comb / Kt;
FOS_yield   = sigma_y / sigma_comb;

fprintf('=== ANALYTICAL STRESS AT BARREL ROOT ===\n');
fprintf('Bending stress           = %.2f MPa\n', sigma_b/1e6);
fprintf('Axial stress             = %.2f MPa\n', sigma_a/1e6);
fprintf('Combined stress (nominal)= %.2f MPa\n', sigma_comb/1e6);
fprintf('Stress concentration Kt  = %.1f (fillet correction)\n', Kt);
fprintf('Corrected stress         = %.2f MPa  <-- compare to FEA\n', sigma_corrected/1e6);
fprintf('FOS vs yield (nominal)   = %.2f\n\n', FOS_yield);
if FOS_yield >= 1.0
    fprintf('RESULT: PASS at limit load.\n\n');
else
    fprintf('RESULT: FAIL — wall too thin. Increase t.\n\n');
end

%% PURPOSE 3 PARAMETRIC WALL THICKNESS SWEEP
t_vec = linspace(3e-3, 10e-3, 60);
FOS_vec = []; mass_vec = [];
for k = 1:length(t_vec)
    t_k = t_vec(k);
    ID_k = OD - 2*t_k;
    if ID_k <= 0, continue; end
    I_k = pi/64 * (OD^4 - ID_k^4);
    A_k = pi/4  * (OD^2 - ID_k^2);
    s_k = (F_limit * L * (OD/2) / I_k) + (F_limit / A_k);
    FOS_vec(end+1) = sigma_y / s_k;
    mass_vec(end+1) = 2810 * A_k * L * 1000;
end
t_mm = t_vec(1:length(FOS_vec)) * 1000;

figure('Color','white','Position',[100 100 900 400]);
subplot(1,2,1);
plot(t_mm, FOS_vec, 'b-', 'LineWidth', 2); hold on;
yline(1.0, 'r--', 'LineWidth', 1.5, 'Label', 'Yield limit (FOS=1)');
yline(1.5, 'k--', 'LineWidth', 1.5, 'Label', 'SF = 1.5 target');
xline(t*1000, 'g-', 'LineWidth', 2, 'Label', 'Chosen t = 5mm');
xlabel('Wall thickness (mm)'); ylabel('FOS vs yield (limit load)');
title('FOS vs wall thickness'); grid on; grid minor;
xlim([3 10]); ylim([0 max(FOS_vec)*1.1]);

subplot(1,2,2);
plot(FOS_vec, mass_vec, 'm-', 'LineWidth', 2); hold on;
[~,idx] = min(abs(t_vec(1:length(FOS_vec)) - t));
plot(FOS_vec(idx), mass_vec(idx), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
xline(1.5, 'k--', 'LineWidth', 1.5, 'Label', 'SF = 1.5');
xlabel('FOS vs yield'); ylabel('Barrel mass (g)');
title('LG Strut - parametric wall thickness study'); grid on;
