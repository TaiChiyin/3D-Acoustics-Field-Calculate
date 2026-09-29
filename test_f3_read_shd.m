function test_f3_read_shd()
%TEST_F3_READ_SHD Verify f3_read_shd against the stored pipeline results.
% The wrapper's saved field3d.mat arrays were produced by reading these same
% .shd files, so a correct reader must reproduce them exactly. This pins the
% byte offsets, the interleaved [real imag] storage and the record order (one
% range sweep per (bearing, source depth) pair, source depth varying fastest).
%
% Native layout returned by the reader is [depth, bearing, range] with the
% source-depth dimension squeezed out; the wrapper's stored arrays are
% [depth, range, bearing].
root = fileparts(mfilename('fullpath'));
clear functions
rehash
cases = { ...
    'Kraken',    fullfile('Kraken','results','run_20260928_080907_979'); ...
    'Krakenc',   fullfile('Krakenc','results','run_20260928_080907_979'); ...
    'Bellhop3D', fullfile('Bellhop3D','results','run_20260928_080907_979')};
for k = 1:size(cases,1)
    model = cases{k,1};
    dir_ = fullfile(root,cases{k,2});
    shdFile = fullfile(dir_,'case.shd');
    S = load(fullfile(dir_,'field3d.mat'),'result'); R = S.result;
    assert(isfile(shdFile),'Missing fixture %s',shdFile);

    t = tic; s = f3_read_shd(shdFile); seconds = toc(t);
    assert(abs(s.frequencyHz-R.frequencyHz)<1e-9,'%s: frequency differs.',model);
    assert(max(abs(double(s.depthM(:))-R.depthM(:)))<1e-4,'%s: depths differ.',model);
    assert(max(abs(double(s.rangeM(:))-R.rangeM(:)))<1e-3,'%s: ranges differ.',model);
    assert(all(diff(s.depthM)>0) && all(diff(s.rangeM)>0), ...
        '%s: axes are not strictly increasing.',model);

    nt = numel(s.bearingDeg); nz = numel(s.depthM); nr = numel(s.rangeM);
    assert(numel(s.pressure)==nz*nt*nr, ...
        '%s: native pressure has %d elements, expected %d.', ...
        model,numel(s.pressure),nz*nt*nr);
    % The reader's native contract is [bearing, source depth, depth, range];
    % normalise it and apply the wrapper's permutation.
    native = reshape(s.pressure,[nt 1 nz nr]);
    wrapped = squeeze(permute(native,[3 4 1 2]));

    if nt>1
        assert(max(abs(double(s.bearingDeg(:))-R.bearingDeg(:)))<1e-4, ...
            '%s: bearings differ.',model);
        assert(isequal(wrapped,R.pressure), ...
            '%s: pressure array differs from the stored result.',model);
        % Horizontally invariant environment: the file must be axisymmetric.
        ref = wrapped(:,:,1);
        rel = norm(double(wrapped)-double(repmat(ref,[1 1 nt])),'fro')/ ...
            norm(double(wrapped(:)));
        assert(rel<1e-5,'%s: azimuthal variation %.3g is too large for this environment.', ...
            model,rel);
    else
        % The file holds one azimuth; the wrapper replicated it per bearing.
        assert(isequal(wrapped,R.pressure(:,:,1)), ...
            '%s: single-bearing plane differs from the stored result.',model);
        assert(isequal(wrapped,repmat(wrapped,1,1,nt)), ...
            '%s: stored result is not an azimuthal replication.',model);
    end
    assert(all(isfinite(s.pressure(:))) && any(abs(s.pressure(:))>0), ...
        '%s: pressure is not finite and nonzero.',model);
    fprintf('test_f3_read_shd: PASS %-9s native [%d %d %d] | %d bearing(s) | %.3f s\n', ...
        model,nz,nt,nr,nt,seconds);
end
end
