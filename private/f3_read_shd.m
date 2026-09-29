function s=f3_read_shd(file)
%F3_READ_SHD Strict AT 2020 binary reader: one frequency/source, regular grid.
% Byte layout of the files written by the bundled executables, verified against
% real solver output:
%   byte 0                 32-bit record-length word, recl
%   byte 4                 title, 80 chars
%   byte j*recl, j=1..9    PlotType, dimensions, frequency, bearings, source x,
%                          source y, source depths, receiver depths, ranges
%   byte 10*recl           pressure: one record of nr complex values per
%                          (bearing, source depth) pair, depth varying fastest,
%                          each value stored as its real then imaginary part
% The record stride is exactly recl, and the four bytes following an offset
% belong to that field's first value rather than to padding.
% Verified for the 2501-range Bellhop3D case: the axes decode to 500 Hz, depths
% 5..195 m, ranges 500..3000 m and bearings 0..350 deg, and the pressure
% reproduces the stored run_20260928_080907_979 arrays for all three models.
% Only the regular (rectilin) one-frequency, one-source-x/y/depth case is
% accepted; anything else is rejected rather than silently misread.
fid=fopen(file,'rb','ieee-le');
assert(fid>=0,'Cannot read %s',file);
clean=onCleanup(@() fclose(fid));
recl=4*fread(fid,1,'int32');
assert(~isempty(recl) && recl>=84 && recl<1e9,'Invalid SHD record length.');

assert(fseek(fid,4,'bof')==0,'Invalid SHD title offset.');
s.title=strtrim(char(fread(fid,80,'char').'));
plotType=strtrim(char(getField(1,10,'char').'));
assert(isempty(plotType) || strcmp(plotType,'rectilin'), ...
    'Only regular SHD supported; found PlotType "%s".',plotType);
n=getField(2,7,'int32').';
assert(numel(n)==7 && all(n>0),'Invalid SHD dimension record.');
assert(n(1)==1,'Only a single frequency SHD is supported.');
assert(all(n(3:5)==1),'Only one source x/y/depth is supported.');
nf=n(1); nt=n(2); ns=n(5); nz=n(6); nr=n(7);
s.frequencyHz=getField(3,nf,'double');
s.bearingDeg=getField(4,nt,'single');
s.sourceXM=getField(5,1,'single');
s.sourceYM=getField(6,1,'single');
s.sourceDepthM=getField(7,ns,'single');
s.depthM=getField(8,nz,'single');
s.rangeM=getField(9,nr,'single');

% One contiguous read of the whole pressure stream keeps a large grid
% affordable. Complex values are interleaved, so a [2 N] read places the real
% part of value j in row 1 and its imaginary part in row 2 of column j.
assert(fseek(fid,10*recl,'bof')==0,'Invalid SHD pressure offset.');
raw=fread(fid,[2 nr*nt*nz],'*single');
assert(numel(raw)==2*nr*nt*nz,'Truncated SHD pressure data.');
cplx=complex(raw(1,:),raw(2,:));
% Native order expected by the wrapper: [bearing, source depth, receiver depth,
% range]. The file varies range fastest, then receiver depth, then bearing, so
% reshape in that order and permute the first three axes.
blk=reshape(cplx,nr,nz,nt);                 % [range, receiver depth, bearing]
s.pressure=permute(blk,[3 2 1]);            % [bearing, receiver depth, range]
s.pressure=reshape(s.pressure,[nt ns nz nr]);

    function v=getField(record,count,precision)
        assert(fseek(fid,record*recl,'bof')==0,'Invalid SHD offset.');
        v=fread(fid,count,precision);
        assert(numel(v)==count,'Truncated SHD field in record %d.',record);
    end
end
