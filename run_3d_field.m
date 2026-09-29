function result = run_3d_field(model,cfg)
%RUN_3D_FIELD Run one native executable and save pressure(z,range,bearing).
% No toolbox MATLAB path, Python, or extra MATLAB toolbox is required.
if nargin < 2, cfg = field3d_config(); end
model = validatestring(model,{'Kraken','Krakenc','Bellhop3D'});
f3_validate_config(cfg);
modelDir = fullfile(cfg.root,model);
if isempty(cfg.runTag)
    cfg.runTag = ['run_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))];
end
assert(~isempty(regexp(cfg.runTag,'^[A-Za-z0-9_-]+$','once')), ...
    'Field3D:Tag','runTag must be a simple directory name.');
outDir = fullfile(modelDir,'results',cfg.runTag);
assert(~isfolder(outDir),'Field3D:ExistingRun', ...
    'Run directory already exists; choose a new runTag: %s',outDir);
exe = fullfile(modelDir,[lower(model) '.exe']);
assert(isfile(exe),'Field3D:MissingExecutable','Missing executable: %s',exe);
mkdir(outDir);
fprintf('%s: computing %g Hz field -> %s\n',model,cfg.frequencyHz,outDir);
save(fullfile(outDir,'config.mat'),'cfg');
f3_write_inputs(outDir,model,cfg);
started = tic;
f3_execute(exe,outDir,'case',lower(model),'.mod',strcmp(model,'Bellhop3D'));
if ~strcmp(model,'Bellhop3D')
    f3_execute(fullfile(modelDir,'field.exe'),outDir,'case','field','.shd',false);
end
native = f3_read_shd(fullfile(outDir,'case.shd'));
f3_check_axes(native,cfg,model);
% Native layout: bearing x source depth x receiver depth x range. Rebuild the
% shape explicitly so a squeezed singleton dimension cannot silently reorder the
% array: permute() drops dimensions when given more indices than the array has,
% which would move the bearing axis into the range position.
nativePressure = reshape(native.pressure, ...
    [numel(native.bearingDeg) numel(native.sourceDepthM) ...
     numel(native.depthM) numel(native.rangeM)]);
p = permute(nativePressure,[3 4 1 2]);
if ~strcmp(model,'Bellhop3D')
    p = repmat(p,1,1,numel(cfg.bearingDeg));
end
result.model = model;
result.cfg = cfg;
result.outputDir = outDir;
result.frequencyHz = native.frequencyHz;
result.sourceXYZM = cfg.sourceXYZM;
result.rangeM = native.rangeM(:).';
result.depthM = native.depthM(:).';
result.bearingDeg = cfg.bearingDeg(:).';
result.pressure = p;
result.TLdB = -20*log10(max(abs(p),realmin('single')));
result.dimensionOrder = 'depth, horizontal_range, bearing';
result.pressureConvention = 'AT coherent complex pressure; exp(+i*omega*t); point-source 1 m normalization';
result.coordinateConvention = 'z positive down; bearing from +x toward +y; MATLAB lengths in metres';
result.environment = 'Horizontally invariant, flat pressure-release sea surface, fluid absorbing halfspace bottom; no ice';
if strcmp(model,'Bellhop3D')
    result.propagation = 'Full 3D ray/beam tracing, RunType(6)=3';
else
    result.propagation = 'KRAKEN/KRAKENC modes + coherent FIELD, revolved using horizontal invariance; not a general 3D solver';
end
[r,theta] = ndgrid(result.rangeM,result.bearingDeg);
result.XM = cfg.sourceXYZM(1) + r.*cosd(theta);
result.YM = cfg.sourceXYZM(2) + r.*sind(theta);
result.elapsedSeconds = toc(started);
assert(all(isfinite(p(:))) && any(abs(p(:))>0), ...
    'Field3D:InvalidPressure','Pressure must be finite and nonzero.');
result.validation.finite = true;
result.validation.nonzeroFraction = nnz(abs(p)>0)/numel(p);
q = double(p);
axisMean = mean(q,3);
result.validation.azimuthRelativeRms = norm(reshape(q-axisMean,[],1))/norm(q(:));
save(fullfile(outDir,'field3d.mat'),'result','-v7.3');
f3_write_summary(result);
if cfg.makePlots, plot_3d_field(result); end
fid = fopen(fullfile(modelDir,'latest_result.txt'),'w');
assert(fid>=0,'Cannot write result pointer.');
fprintf(fid,'%s\n',fullfile(outDir,'field3d.mat')); fclose(fid);
fprintf('%s complete: [%d %d %d], %.1f s\n',model,size(p,1),size(p,2),size(p,3),result.elapsedSeconds);
end

function f3_check_axes(s,cfg,model)
assert(abs(s.frequencyHz-cfg.frequencyHz)<1e-6,'Field3D:Frequency','Frequency mismatch.');
assert(numel(s.sourceDepthM)==1 && abs(s.sourceDepthM-cfg.sourceXYZM(3))<1e-4, ...
    'Field3D:Source','Source depth mismatch.');
assert(numel(s.rangeM)==numel(cfg.rangeM) && max(abs(s.rangeM(:)-cfg.rangeM(:)))<0.01, ...
    'Field3D:Range','Receiver range mismatch.');
assert(numel(s.depthM)==numel(cfg.depthM) && max(abs(s.depthM(:)-cfg.depthM(:)))<1e-4, ...
    'Field3D:Depth','Receiver depth mismatch.');
if strcmp(model,'Bellhop3D')
    assert(numel(s.bearingDeg)==numel(cfg.bearingDeg) && ...
        max(abs(s.bearingDeg(:)-cfg.bearingDeg(:)))<1e-4,'Field3D:Bearing','Bearing mismatch.');
    assert(abs(s.sourceXM-cfg.sourceXYZM(1))<0.01 && abs(s.sourceYM-cfg.sourceXYZM(2))<0.01, ...
        'Field3D:Source','Horizontal source coordinates mismatch.');
end
end

function f3_write_summary(r)
fid = fopen(fullfile(r.outputDir,'summary.txt'),'w');
assert(fid>=0,'Cannot write summary.');
clean = onCleanup(@() fclose(fid));
fprintf(fid,'%s | %.6g Hz\n%s\n%s\n',r.model,r.frequencyHz,r.environment,r.propagation);
fprintf(fid,'pressure / TLdB dimensions: depth x range x bearing = %d x %d x %d\n',size(r.pressure));
fprintf(fid,'%s\n%s\n',r.coordinateConvention,r.pressureConvention);
fprintf(fid,'Range: %.6g to %.6g m; depth: %.6g to %.6g m\n',r.rangeM([1 end]),r.depthM([1 end]));
fprintf(fid,'Compute + read time: %.3f s\nAzimuth relative RMS: %.8g\nNonzero fraction: %.8g\n', ...
    r.elapsedSeconds,r.validation.azimuthRelativeRms,r.validation.nonzeroFraction);
fprintf(fid,'Samples are exact output locations. Sparse spatial sampling is NOT a phase-resolved continuous field.\n');
fprintf(fid,'Do not interpolate complex pressure on this coarse grid for coherent MFP; recalculate target positions.\n');
end
