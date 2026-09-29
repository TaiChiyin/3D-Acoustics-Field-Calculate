function f3_write_inputs(folder,model,c)
fid=fopen(fullfile(folder,'case.env'),'w');
assert(fid>=0,'Cannot write environment file.');
clean=onCleanup(@() fclose(fid));
fprintf(fid,'''%s shallow Pekeris, %.6g Hz''\n%.10g\n1\n''CVW''\n',model,c.frequencyHz,c.frequencyHz);
fprintf(fid,'%d 0 %.10g\n',c.modeMeshPoints,c.waterDepthM);
fprintf(fid,'0 %.10g 0 %.10g 0 0 /\n',c.waterSpeedMps,c.waterDensityGcm3);
fprintf(fid,'%.10g %.10g /\n''A'' 0\n',c.waterDepthM,c.waterSpeedMps);
fprintf(fid,'%.10g %.10g 0 %.10g %.10g 0 /\n',c.waterDepthM,c.bottomSpeedMps, ...
    c.bottomDensityGcm3,c.bottomAttenuationDbPerWavelength);
if strcmp(model,'Bellhop3D')
    vec(fid,c.sourceXYZM(1)/1000,'source x, km');
    vec(fid,c.sourceXYZM(2)/1000,'source y, km');
    vec(fid,c.sourceXYZM(3),'source depth, m');
    vec(fid,c.depthM,'receiver depths, m');
    vec(fid,c.rangeM/1000,'receiver horizontal ranges, km');
    vec(fid,c.bearingDeg,'receiver bearings, deg');
    fprintf(fid,'''%s'' ! coherent FULL 3D, not Nx2D\n',c.bellhop.runType);
    fprintf(fid,'%d\n%.10g %.10g /\n',c.bellhop.nAlpha,c.bellhop.alphaLimitsDeg);
    fprintf(fid,'%d\n0 360 /\n',c.bellhop.nBeta);
    boxM=max(abs(c.sourceXYZM(1:2)))+1.1*c.rangeM(end);
    fprintf(fid,'%.10g %.10g %.10g %.10g\n',c.bellhop.stepM,boxM/1000,boxM/1000,c.waterDepthM+1);
else
    fprintf(fid,'0 %.10g\n%.10g\n',c.modeMaxPhaseSpeedMps,c.rangeM(end)/1000);
    vec(fid,c.sourceXYZM(3),'source depth, m');
    % Include the exact source and receiver depths; no modal-depth interpolation error.
    vec(fid,unique([0 c.sourceXYZM(3) c.depthM(:).' c.waterDepthM]),'mode sample depths, m');
end
clear clean;
if strcmp(model,'Bellhop3D'), return; end
fid=fopen(fullfile(folder,'case.flp'),'w');
assert(fid>=0,'Cannot write FIELD parameters.');
clean=onCleanup(@() fclose(fid));
fprintf(fid,'''Coherent point-source FIELD''\n''RA C''\n9999\n');
vec(fid,0,'profile range, km');
vec(fid,c.rangeM/1000,'receiver ranges, km');
vec(fid,c.sourceXYZM(3),'source depth, m');
vec(fid,c.depthM,'receiver depths, m');
vec(fid,zeros(size(c.depthM)),'receiver range offsets, m');
end

function vec(fid,v,label)
fprintf(fid,'%d ! %s\n',numel(v),label);
fprintf(fid,'%.10g ',v);
fprintf(fid,'/\n');
end
