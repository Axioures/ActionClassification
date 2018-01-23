% clc, clear;

%% Setting the main params.paths. Change manually.
if isunix,
    params.paths.root = fullfile('/home/nick/Desktop/Experiments_ActionClassif');
    params.paths.db = fullfile('/home/nick/Videos/KTH');
    params.paths.db_data = fullfile('/home/nick/Dropbox/Gesture/data');
    params.paths.code = fullfile('/home/nick/Dropbox/Gesture/Code_final');
else
    error('Please switch to unix...');
end
addpath(genpath(params.paths.code));
params.DEBUG = 0;
params.dbName = 'KTH';

%% Setting the parameters
params.global_seed = 25;
% feature parameters
params.features.type = 'harris3d';
params.features.executable = fullfile('/home/nick/ExternalPackages/stip-2.0-linux/bin/stipdet');
params.features.libs = '/home/nick/ExternalPackages/opencv/lib';
params.features.descriptors = {'HOG', 'HOF', 'HOGHOF'};
params.features.nplev = 3; % number of scales
params.features.plev0 = 0; % first scale
params.features.szf = 18; % patch size's spatial factor
params.features.tzf = 4; % patch size's temporal factor
params.features.save2disk = true;
% encoding parameters
params.encoding.type = 'BoVW'; % possible options are 'BoVW', 'vlad' or 'fisher'
params.encoding.K = 4000; % number of visual words for either kmeans or gmm
params.encoding.data_usage = 100000; % data used for vodebook generation as percentage of TrainData
params.encoding.pca_factor= 1;
params.encoding.num_seeds = 1; % number of k-means repetitions with different (random) initializations (seeds)
% grids(1).h = 1; grids(1).v = 1; grids(1).t = 1; % spatio-temporal grid parameters
% grids(2).h = 3; grids(2).v = 1; grids(2).t = 1;
% grids(3).h = 2; grids(3).v = 2; grids(3).t = 1;
% grids(4).h = 1; grids(4).v = 1; grids(4).t = 2;
% grids(5).h = 3; grids(5).v = 1; grids(5).t = 2;
% grids(6).h = 2; grids(6).v = 2; grids(6).t = 2;
% params.grids = grids;
% classification parameters
params.classification.svm_cost = 100;
params.classification.kernel = 'ChiSquared';
params.classification.combine = false;
params.classification.combine_descriptors = {''};
% possible reusage of elements
params.reuse.features = false;
params.reuse.features_path = '';

%% Configure Channels + Spatio-Temporal Pyramids
if isfield(params, 'grids')
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

%% states
% 0: nothing has been done
% 1: codebook has been generated
% 2: encodings have been computed
% 2.5: kernels have been computed (does not apply to Linear kernel)
% 3: SVMs have been trained
% 4: testinghas been done
params.state = 3;


%% Check parameters' consistency
if strcmp(params.encoding.type, 'fisher')&&(params.encoding.K>512)
    error('really? So many gaussians?');
elseif strcmp(params.encoding.type, 'BoVW')&&(params.encoding.K<4000)
    error('really? So few k-means centres?');
end
if (strcmp(params.encoding.type, 'fisher')||strcmp(params.encoding.type, 'vlad'))&&(~strcmp(params.classification.kernel,'Linear'))
    error('Fisher or VLAD with kernel other than Linear is not supported')
elseif strcmp(params.encoding.type, 'BoVW')&&strcmp(params.classification.kernel,'Linear')
    error('BoVW with Linear kernel is not supported')
end
if strcmp(params.encoding.type, 'BoVW')&&(params.encoding.pca_factor<1)
    error('PCA with BoVW is not supported');
end
if strcmp(params.encoding.type, 'fisher')&&(params.pyramids)
    warning('Fisher vector with spatio-tenporal pyramids is not supported. Ignoring s.t. pyramids');
end

%% Form experiment's codename
if strcmp(params.features.type,'DT')
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
msg = sprintf('              Experiment Codename is "%s"              \n', experiment_string);
msg_size = length(msg);
fprintf(repmat('-', 1, msg_size)); fprintf('\n');
fprintf(msg);
fprintf(repmat('-', 1, msg_size)); fprintf('\n\n');


%% Setting other paths automatically
params.paths.expRoot = fullfile(params.paths.root, experiment_string);
params.paths.training = fullfile(params.paths.expRoot, params.dbName, 'training');
params.paths.testing = fullfile(params.paths.expRoot, params.dbName, 'testing');
params.paths.logs = fullfile(params.paths.root, 'logs');
params.paths.yael = fullfile('/home/nick/ExternalPackages/yael_v438/matlab');
params.paths.LibSvm = fullfile('/home/nick/ExternalPackages/libsvm-3.17_with_conversion_tool/matlab/');
if (params.reuse.features)&&isfield(params.reuse, 'features_path')&&exist(params.reuse.features_path, 'file')
    params.paths.features = params.reuse.features_path;
else
    params.paths.features = fullfile(params.paths.expRoot, params.dbName, 'features');
end
checkPaths(params.paths, 'create');


logfile = fullfile(params.paths.logs, sprintf('%s_%s.log', params.dbName, experiment_string));
diary(logfile)
diary on

addpath(params.paths.yael);
addpath(genpath(params.paths.LibSvm));
clear grids_str experiment_string experimentsRoot i grids
return