function f3_execute(exe,folder,base,logName,extension,isBellhop)
assert(isfile(exe),'Field3D:MissingExecutable','Missing executable: %s',exe);
if isBellhop, extension='.shd'; end
original=pwd;
clean=onCleanup(@() cd(original));
cd(folder);
% base is an internal constant, never a user-supplied shell expression.
[status,output]=system(sprintf('"%s" %s',exe,base));
fid=fopen([logName '_console.txt'],'w');
assert(fid>=0,'Cannot write solver log.');
fprintf(fid,'%s\nExit status: %d\n',output,status); fclose(fid);
assert(status==0,'Field3D:SolverFailed','%s failed (%d): %s',logName,status,output);
prt=[base '.prt'];
if strcmp(logName,'field'), prt='field.prt'; end
assert(isfile(prt),'Field3D:NoPrintFile','Missing solver print file.');
report=fileread(prt);
assert(isempty(regexpi(report,'fatal|error in|error:','once')), ...
    'Field3D:SolverReport','Solver reported an error; inspect %s',fullfile(folder,prt));
assert(isfile([base extension]),'Field3D:MissingOutput','No fresh %s output.',extension);
if isBellhop
    assert(contains(report,'3D calculation') && ~contains(report,'N x 2D calculation'), ...
        'Field3D:Not3D','BELLHOP must report full 3D calculation.');
end
end
