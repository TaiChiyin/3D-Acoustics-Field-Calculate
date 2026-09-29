function plot_3d_field(result)
%PLOT_3D_FIELD Plot native cylindrical samples, without complex interpolation.
if ischar(result) || isstring(result)
    s=load(result,'result'); result=s.result;
end
r=result; c=r.cfg;
[~,iz]=min(abs(r.depthM-c.sourceXYZM(3)));
f=figure('Visible',c.figureVisible,'Color','w','Position',[100 100 1450 620]);
clean=onCleanup(@() close(f));
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
nexttile;
imagesc(r.rangeM/1000,r.depthM,r.TLdB(:,:,1));
set(gca,'YDir','reverse'); clim(c.tlColorLimitsDb); colorbar;
xlabel('Horizontal range (km)'); ylabel('Depth (m)');
title(sprintf('%s | %.0f Hz | bearing %.0f deg',r.model,r.frequencyHz,r.bearingDeg(1)));
nexttile;
[x,y,v]=closedPlane(r,iz);
surf(x/1000,y/1000,zeros(size(x)),v,'EdgeColor','none'); view(2); axis equal tight;
clim(c.tlColorLimitsDb); colorbar; xlabel('x (km)'); ylabel('y (km)');
title(sprintf('Horizontal slice | depth %.1f m | TL (dB)',r.depthM(iz)));
colormap(f,turbo);
exportgraphics(f,fullfile(r.outputDir,'field_slices.png'),'Resolution',170);
savefig(f,fullfile(r.outputDir,'field_slices.fig'));
clear clean;

f=figure('Visible',c.figureVisible,'Color','w','Position',[100 100 1100 850]);
clean=onCleanup(@() close(f));
hold on;
[x,y,v]=closedPlane(r,numel(r.depthM));
surf(x/1000,y/1000,repmat(r.depthM(end),size(x)),v,'EdgeColor','none');
for theta=[0 90 180 270]
    [~,it]=min(abs(r.bearingDeg-theta));
    [rr,zz]=meshgrid(r.rangeM,r.depthM);
    xx=c.sourceXYZM(1)+rr*cosd(r.bearingDeg(it));
    yy=c.sourceXYZM(2)+rr*sind(r.bearingDeg(it));
    surf(xx/1000,yy/1000,zz,r.TLdB(:,:,it),'EdgeColor','none');
end
plot3(c.sourceXYZM(1)/1000,c.sourceXYZM(2)/1000,c.sourceXYZM(3), ...
    'p','MarkerSize',13,'MarkerFaceColor','w','MarkerEdgeColor','k');
set(gca,'ZDir','reverse'); view(42,28); axis tight; grid on;
xlabel('x (km)'); ylabel('y (km)'); zlabel('Depth (m)');
clim(c.tlColorLimitsDb); cb=colorbar; cb.Label.String='Transmission loss (dB)';
colormap(f,turbo);
title({sprintf('%s | 3D sampled pressure field | %.0f Hz',r.model,r.frequencyHz), ...
    'Flat, horizontally invariant 200 m shallow-water environment'});
exportgraphics(f,fullfile(r.outputDir,'field_3d.png'),'Resolution',180);
savefig(f,fullfile(r.outputDir,'field_3d.fig'));
end

function [x,y,v]=closedPlane(r,iz)
x=r.XM; y=r.YM;
v=reshape(r.TLdB(iz,:,:),numel(r.rangeM),numel(r.bearingDeg));
% Close only a full circular grid; never fabricate missing-sector data.
if abs(r.bearingDeg(end)-r.bearingDeg(1)+diff(r.bearingDeg(1:2))-360)<1e-6
    x=[x x(:,1)]; y=[y y(:,1)]; v=[v v(:,1)];
end
end
