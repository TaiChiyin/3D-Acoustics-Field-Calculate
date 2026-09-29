function s=f3_read_shd(file)
%F3_READ_SHD Strict AT 2020 binary reader: one frequency/source, regular grid.
% Record layout checked against bundled AT Matlab/ReadWrite/read_shd_bin.m.
% Pressure is read in whole-record blocks; per-record fseek on a large
% bearing x depth grid would dominate the run time.
fid=fopen(file,'rb','ieee-le');
assert(fid>=0,'Cannot read %s',file);
clean=onCleanup(@() fclose(fid));
recl=4*fread(fid,1,'int32');
assert(~isempty(recl) && recl>=84 && recl<1e9,'Invalid SHD record length.');
s.title=strtrim(char(fread(fid,80,'*char').'));
at(1); plotType=char(fread(fid,10,'*char').');
% FIELD 2020 leaves PlotType blank for a regular grid; BELLHOP writes rectilin.
assert(isempty(strtrim(plotType)) || strcmp(strtrim(plotType),'rectilin'), ...
    'Only regular SHD supported.');
at(2); n=fread(fid,7,'int32').';
assert(numel(n)==7 && all(n>0) && n(1)==1 && all(n(3:5)==1), ...
    'Expected exactly one frequency, one source x/y/depth.');
nf=n(1); nt=n(2); ns=n(5); nz=n(6); nr=n(7);
assert(recl>=8*nr,'SHD record is too short.');
at(3); s.frequencyHz=fread(fid,nf,'double');
at(4); s.bearingDeg=fread(fid,nt,'single');
at(5); s.sourceXM=fread(fid,1,'single');
at(6); s.sourceYM=fread(fid,1,'single');
at(7); s.sourceDepthM=fread(fid,ns,'single');
at(8); s.depthM=fread(fid,nz,'single');
at(9); s.rangeM=fread(fid,nr,'single');
s.pressure=complex(zeros(nt,ns,nz,nr,'single'));
% Records are contiguous and record 10 holds the first pressure record.
at(10);
raw=fread(fid,[2 nr*nt*nz],'*single');
assert(numel(raw)==2*nr*nt*nz,'Truncated SHD pressure data.');
blk=reshape(raw,2,nr,nt,nz); % [real/imag, range, bearing, depth]
s.pressure(:,:,:,:)=permute(complex(blk(1,:,:,:),blk(2,:,:,:)),[3 4 2 1]);
    function at(record)
        assert(fseek(fid,record*recl,'bof')==0,'Invalid SHD offset.');
    end
end
