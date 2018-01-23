function params = config_parser(config_file)

%% Some essensial "addpath"s
addpath(genpath('./configs/YAMLMatlab'));
params = ReadYaml(config_file);
if ~isunix
    error('Please switch to unix...');
end
if isfield(params.paths, 'vlfeat')
    warning('off','all');
    addpath(genpath(params.paths.vlfeat));
    warning('on','all');
end
if ~isfield(params.paths, 'code')
    params.paths.code = './';
end
addpath(genpath(params.paths.code));
addpath(params.paths.yael);
addpath(genpath(params.paths.LibSvm));

%% Configure descriptors' combination
if isfield(params.classification, 'combine')
    if ~params.classification.combine
        params.classification.combine_descriptors = {};
    end
else
    params.classification.combine_descriptors = false;
    params.classification.combine_descriptors = {};
end

%% Configure Channels + Spatio-Temporal Pyramids
if isfield(params, 'grids')
    params.grids = cell2mat(params.grids);
    params.pyramids = true;
    grids = params.grids;
    params.encoding.num_grids = length(grids);
    grids = configure_st_pyramids(grids); 
    channels = repmat(struct('name', '', 'grid', -1, 'grid_name', '', 'descriptor', ''), length(grids)*length(params.features.descriptors), 1);
    for g = 1:length(grids)
        for d = 1:length(params.features.descriptors)
            iCh = (g-1)*length(params.features.descriptors)+d;
            channels(iCh).grid = grids(g);
            channels(iCh).grid_name = sprintf('h%dv%dt%d', grids(g).h, grids(g).v, grids(g).t);
            channels(iCh).descriptor = params.features.descriptors{d};
            channels(iCh).name = sprintf('%s_%s', channels(iCh).grid_name, params.features.descriptors{d});
        end
    end
    grids_str = '';
    for i=1:params.encoding.num_grids
        grids_str = sprintf('%s%s%s%s', grids_str, num2str(grids(i).h), num2str(grids(i).v), num2str(grids(i).t));
    end
else
    channels = repmat(struct('name', '', 'descriptor', ''), length(params.features.descriptors), 1);
    for d = 1:length(params.features.descriptors)
        channels(d).descriptor = params.features.descriptors{d};
        channels(d).name = params.features.descriptors{d};
    end
    params.pyramids = false; 
    grids_str = '0';
end
params.channels = channels;


%% Check parameters' consistency
if strcmp(params.encoding.type, 'fisher')&&(params.encoding.K>512)
    warning('Really? So many gaussians?');
    pause;
elseif strcmp(params.encoding.type, 'BoVW')&&(params.encoding.K<4000)
    warning('Really? So few k-means centres?');
    pause;
end
if strcmp(params.encoding.type, 'vlad')&&(~isfield(params.paths, 'vlfeat'))
    error('VLAD: You should specify the VLFeat package path as in ''paths:vlfeat'' path')
end
if (strcmp(params.encoding.type, 'fisher')||strcmp(params.encoding.type, 'vlad'))&&(~strcmp(params.classification.kernel,'Linear'))
    error('Fisher or VLAD: only Linear is supported')
elseif strcmp(params.encoding.type, 'BoVW')&&strcmp(params.classification.kernel,'Linear')
    error('BoVW: Linear kernel is not supported')
end
if (strcmp(params.encoding.type, 'BoVW')||strcmp(params.encoding.type, 'vlad'))&&(params.encoding.pca_factor<1)
    error('BoVW or VLAD: PCA is not supported');
end
if (strcmp(params.encoding.type, 'fisher')||strcmp(params.encoding.type, 'vlad'))&&(params.pyramids)
    warning('Fisher Vector or VLAD: spatio-tenporal pyramids are not supported. Ignoring s.t. pyramids');
end
if isfield(params, 'use_disk') && params.use_disk
    warning('You used the "params.features.use_disk" flag. Make sure you have WRITE permissions to the db path.\n')
end
if isfield(params, 'reuse')
    if ~isfield(params.reuse, 'features')
        params.reuse.features = 0;
    end
    if ~isfield(params.reuse, 'encodings')
        params.reuse.encodings = 0;
    end
    if ~isfield(params.reuse, 'codebooks')
        params.reuse.codebooks = 0;
    end    
else
    params.reuse.features = 0;
    params.reuse.encodings = 0;
    params.reuse.codebooks = 0;
end

%% Form experiment's codename
if isfield(params, 'basename')
    experiment_string = params.basename;
else
    if strcmp(params.features.type,'DT')||strcmp(params.features.type,'iDT')
        experiment_string = sprintf('%s_L%d_N%d_s%d_t%d_%s_g%s_K%d_data%d_pca%.2f_s%d',...
            params.features.type, params.features.L, params.features.N, params.features.s,params.features.t,...
            params.encoding.type, grids_str, params.encoding.K, params.encoding.data_usage,...
            params.encoding.pca_factor, params.global_seed);
    else
        experiment_string = sprintf('%s_nplev%d_plev0%d_szf%d_tzf%d_%s_g%s_K%d_data%d_pca%.2f_s%d',...
            params.features.type, params.features.nplev, params.features.plev0, params.features.szf ,params.features.tzf,...
            params.encoding.type, grids_str, params.encoding.K, params.encoding.data_usage,...
            params.encoding.pca_factor, params.global_seed);    
    end
    if params.DEBUG
        experiment_string = ['DEBUG' experiment_string];
    end
end
msg = sprintf('              Experiment Codename is "%s"              \n', experiment_string);
msg_size = length(msg);
fprintf(repmat('-', 1, msg_size)); fprintf('\n');
fprintf(msg);
fprintf(repmat('-', 1, msg_size)); fprintf('\n\n');


%% Setting other paths automatically
params.paths.expRoot = fullfile(params.paths.root, experiment_string);
if (~isfield(params.paths, 'training'))
    params.paths.training = fullfile(params.paths.expRoot, params.dbName, 'training');
end
if (~isfield(params.paths, 'encodings'))
    params.paths.encodings = fullfile(params.paths.expRoot, params.dbName, 'encodings');
end
if (~isfield(params.paths, 'testing'))
    params.paths.testing = fullfile(params.paths.expRoot, params.dbName, 'testing');
end
if ~isfield(params.paths, 'features')
    params.paths.features = fullfile(params.paths.expRoot, params.dbName, 'features');
end
if (~isfield(params.paths, 'logs'))
    params.paths.logs = fullfile(params.paths.root, 'logs');
end
checkPaths(params.paths, 'create');
params.features.path = params.paths.features;


copyfile(config_file, fullfile(params.paths.expRoot, params.dbName));
save(fullfile(params.paths.expRoot, params.dbName, 'parameters.mat'));
logfile = fullfile(params.paths.logs, sprintf('%s_%s.log', experiment_string, params.dbName));
% if exist(logfile, 'file')
% 	delete(logfile);
% end
% diary(logfile)
% diary on


end