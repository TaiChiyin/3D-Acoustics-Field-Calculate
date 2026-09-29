function f3_validate_config(c)
validateattributes(c.frequencyHz,{'numeric'},{'scalar','positive','finite'});
validateattributes(c.waterDepthM,{'numeric'},{'scalar','positive','finite'});
for name={'waterSpeedMps','waterDensityGcm3','bottomSpeedMps','bottomDensityGcm3','modeMaxPhaseSpeedMps'}
    validateattributes(c.(name{1}),{'numeric'},{'scalar','positive','finite'});
end
validateattributes(c.bottomAttenuationDbPerWavelength,{'numeric'},{'scalar','nonnegative','finite'});
assert(c.modeMaxPhaseSpeedMps>c.waterSpeedMps,'Mode phase-speed limit must exceed water speed.');
validateattributes(c.sourceXYZM,{'numeric'},{'vector','numel',3,'finite'});
assert(c.sourceXYZM(3)>0 && c.sourceXYZM(3)<c.waterDepthM,'Source must be in water.');
axes = {'rangeM','depthM','bearingDeg'};
for j=1:numel(axes)
    v=c.(axes{j});
    validateattributes(v,{'numeric'},{'vector','finite','nonempty'});
    assert(numel(v)>=2 && all(diff(v)>0),'Axes must have at least two increasing samples.');
    assert(max(abs(diff(v)-mean(diff(v))))<1e-7, ...
        'Use equally spaced axes: required by this BELLHOP3D workflow.');
end
assert(c.rangeM(1)>0,'Exclude the point-source singularity at r=0.');
assert(c.depthM(1)>0 && c.depthM(end)<c.waterDepthM,'Receivers must be strictly in water.');
assert(c.bearingDeg(1)>=0 && c.bearingDeg(end)<360,'Use bearings in [0,360), without duplicate endpoint.');
validateattributes(c.modeMeshPoints,{'numeric'},{'scalar','integer','positive'});
validateattributes(c.bellhop.nAlpha,{'numeric'},{'scalar','integer','>=',3});
validateattributes(c.bellhop.nBeta,{'numeric'},{'scalar','integer','>=',3});
validateattributes(c.bellhop.stepM,{'numeric'},{'scalar','positive','finite'});
assert(strcmp(c.bellhop.runType,'CG RR3') || strcmp(c.bellhop.runType,'CB RR3'), ...
    'Use coherent FULL 3D geometric hat or Gaussian beams.');
validateattributes(c.bellhop.alphaLimitsDeg,{'numeric'},{'vector','numel',2,'finite'});
assert(c.bellhop.alphaLimitsDeg(1)>-90 && c.bellhop.alphaLimitsDeg(2)<90 && ...
    diff(c.bellhop.alphaLimitsDeg)>0,'Exclude exactly vertical rays.');
end
