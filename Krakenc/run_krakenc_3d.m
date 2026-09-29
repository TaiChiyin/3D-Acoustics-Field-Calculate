function result=run_krakenc_3d(cfg)
%RUN_KRAKENC_3D Standalone entry point; outputs remain in this model directory.
root=fileparts(fileparts(mfilename('fullpath')));
old=path; clean=onCleanup(@() path(old));
addpath(root);
if nargin==0, cfg=field3d_config(); end
result=run_3d_field('Krakenc',cfg);
end
