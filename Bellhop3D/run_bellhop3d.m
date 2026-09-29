function result=run_bellhop3d(cfg)
%RUN_BELLHOP3D Standalone entry point; explicitly runs full 3D, not Nx2D.
root=fileparts(fileparts(mfilename('fullpath')));
old=path; clean=onCleanup(@() path(old));
addpath(root);
if nargin==0, cfg=field3d_config(); end
result=run_3d_field('Bellhop3D',cfg);
end
