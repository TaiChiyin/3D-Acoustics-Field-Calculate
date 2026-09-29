function cfg = field3d_config()
%FIELD3D_CONFIG Shared, ice-free shallow-water benchmark (SI units in MATLAB).
% Reference: ../compare_different_env/shallow_sea_Gaussian/pekerisK.env
cfg.root = fileparts(mfilename('fullpath'));
cfg.frequencyHz = 500;
cfg.waterDepthM = 200;
cfg.waterSpeedMps = 1500;
cfg.waterDensityGcm3 = 1.0;
cfg.bottomSpeedMps = 1600;
cfg.bottomDensityGcm3 = 1.8;
cfg.bottomAttenuationDbPerWavelength = 0.2;
cfg.sourceXYZM = [0 0 25];
cfg.rangeM = 500:5:3000;
cfg.depthM = 5:5:195;
cfg.bearingDeg = 0:10:350;
cfg.modeMeshPoints = 2000;
cfg.modeMaxPhaseSpeedMps = 20000;
cfg.bellhop.nAlpha = 1601;
cfg.bellhop.alphaLimitsDeg = [-80 80];
cfg.bellhop.nBeta = 145; % includes 360; solver removes duplicate endpoint
cfg.bellhop.stepM = 10;
cfg.bellhop.runType = 'CG RR3'; % coherent, geometric hat, point, regular, full 3D
cfg.makePlots = true;
cfg.figureVisible = 'off';
cfg.tlColorLimitsDb = [40 90];
cfg.runTag = ''; % empty: create a new dated directory for every run
end
