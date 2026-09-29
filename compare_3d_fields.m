function metrics=compare_3d_fields(results)
%COMPARE_3D_FIELDS Compare without fitting scale, phase, or complex conjugation.
names={'Kraken','Krakenc','Bellhop3D'};
pairs=[1 2;2 3];
metrics=struct();
for j=1:size(pairs,1)
    a=results.(names{pairs(j,1)}); b=results.(names{pairs(j,2)});
    assert(isequal(a.rangeM,b.rangeM) && isequal(a.depthM,b.depthM) && ...
        isequal(a.bearingDeg,b.bearingDeg) && a.frequencyHz==b.frequencyHz, ...
        'Cannot compare different physical grids or frequencies.');
    % A single vertical plane avoids counting repeated azimuthal information.
    x=double(a.pressure(:,:,1)); y=double(b.pressure(:,:,1));
    key=[a.model '_vs_' b.model];
    m.relativeComplexError=norm(x(:)-y(:))/norm(x(:));
    m.coherence=abs(x(:)'*y(:))^2/(sum(abs(x(:)).^2)*sum(abs(y(:)).^2));
    % Diagnostic only: do not alter saved pressures or raw comparison errors.
    phaseOffset=angle(x(:)'*y(:));
    m.globalPhaseOffsetDeg=phaseOffset*180/pi;
    m.phaseAlignedRelativeError=norm(x(:)-y(:)*exp(-1i*phaseOffset))/norm(x(:));
    delta=double(b.TLdB(:,:,1))-double(a.TLdB(:,:,1));
    m.medianAbsoluteTLdifferenceDb=median(abs(delta(:)));
    m.rmsTLdifferenceDb=sqrt(mean(delta(:).^2));
    m.note=['Raw pressure is unchanged. Phase-aligned error is diagnostic only; ' ...
        'a nearly 180-degree global offset can dominate raw complex error while TL agrees.'];
    metrics.(key)=m;
end
for j=1:numel(names)
    out=results.(names{j}).outputDir;
    save(fullfile(out,'comparison.mat'),'metrics');
    fid=fopen(fullfile(out,'comparison.json'),'w');
    assert(fid>=0,'Cannot write comparison.');
    fprintf(fid,'%s\n',jsonencode(metrics,PrettyPrint=true)); fclose(fid);
end
if ~results.Kraken.cfg.makePlots, return; end
c=results.Kraken.cfg;
f=figure('Visible',c.figureVisible,'Color','w','Position',[100 100 1500 550]);
clean=onCleanup(@() close(f));
tiledlayout(1,3,'TileSpacing','compact');
for j=1:3
    r=results.(names{j}); nexttile;
    imagesc(r.rangeM/1000,r.depthM,r.TLdB(:,:,1));
    set(gca,'YDir','reverse'); clim(c.tlColorLimitsDb); colorbar;
    xlabel('Range (km)'); ylabel('Depth (m)'); title(r.model);
end
colormap(f,turbo); sgtitle(sprintf('Same shallow-water environment | %.0f Hz | coherent TL (dB)',c.frequencyHz));
for j=1:3
    exportgraphics(f,fullfile(results.(names{j}).outputDir,'model_comparison.png'),'Resolution',170);
end
end
