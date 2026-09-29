function report=verify_3d_fields()
%VERIFY_3D_FIELDS Numerical verification on a smaller common receiver grid.
% Refines the modal mesh and both beam fans + integration step. It reports
% actual errors; cross-model agreement alone is not a physical validation.
c=field3d_config(); c.makePlots=false;
c.rangeM=500:250:3000; c.depthM=10:20:190; c.bearingDeg=0:30:330;
tag=['verify_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))];
c.runTag=[tag '_base'];
base=run_all_3d_fields(c);
c.runTag=[tag '_fine']; c.modeMeshPoints=2*c.modeMeshPoints;
c.bellhop.nAlpha=2*(c.bellhop.nAlpha-1)+1;
c.bellhop.nBeta=2*(c.bellhop.nBeta-1)+1;
c.bellhop.stepM=c.bellhop.stepM/2;
fine=run_all_3d_fields(c);
names={'Kraken','Krakenc','Bellhop3D'};
report.description='Combined refinement on exact shared receiver locations; phase is not fitted.';
for j=1:numel(names)
    name=names{j}; a=base.(name); b=fine.(name);
    x=double(a.pressure); y=double(b.pressure);
    m.relativeComplexError=norm(x(:)-y(:))/norm(y(:));
    m.coherence=abs(x(:)'*y(:))^2/(sum(abs(x(:)).^2)*sum(abs(y(:)).^2));
    d=double(a.TLdB)-double(b.TLdB);
    m.medianAbsoluteTLchangeDb=median(abs(d(:)));
    m.rmsTLchangeDb=sqrt(mean(d(:).^2));
    m.azimuthRelativeRms=b.validation.azimuthRelativeRms;
    % Engineering checks for this example, not universal acoustic tolerances.
    if strcmp(name,'Bellhop3D'), tolerance=0.1; else, tolerance=0.01; end
    m.relativeComplexTolerance=tolerance;
    m.passed=m.relativeComplexError<tolerance && m.azimuthRelativeRms<0.02;
    m.baseResult=fullfile(a.outputDir,'field3d.mat');
    m.refinedResult=fullfile(b.outputDir,'field3d.mat');
    report.(name)=m;
end
report.allPassed=all(cellfun(@(name) report.(name).passed,names));
for j=1:numel(names)
    out=fullfile(c.root,names{j},'validation');
    if ~isfolder(out), mkdir(out); end
    save(fullfile(out,[tag '.mat']),'report');
    fid=fopen(fullfile(out,[tag '.json']),'w');
    assert(fid>=0,'Cannot write validation report.');
    fprintf(fid,'%s\n',jsonencode(report,PrettyPrint=true)); fclose(fid);
end
disp(report);
if ~report.allPassed
    warning('Field3D:Refinement','Refinement threshold exceeded. Inspect saved report before quantitative use.');
end
end
