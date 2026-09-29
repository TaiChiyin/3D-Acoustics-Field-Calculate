function results = run_all_3d_fields(cfg)
%RUN_ALL_3D_FIELDS Compute all models; each result stays in its own folder.
if nargin == 0, cfg = field3d_config(); end
if isempty(cfg.runTag)
    cfg.runTag = ['run_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))];
end
models = {'Kraken','Krakenc','Bellhop3D'};
results = struct();
for j = 1:numel(models)
    model = models{j};
    results.(model) = run_3d_field(model,cfg);
end
compare_3d_fields(results);
end
