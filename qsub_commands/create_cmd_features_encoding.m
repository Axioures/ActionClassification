function [] = create_cmd_features_encoding(configFile, code_path, matlab_exec, clips_per_cmd, splits_per_cmd)

if ~exist('clips_per_cmd', 'var')
    clips_per_cmd = 1;
end


addpath(genpath(code_path));
params = config_parser(configFile);
switch params.dbName
    case 'KTH'
        db_params = configKTH(params.paths);
    case 'UCFSports'
        db_params = configUCFSports(params.paths);
    case 'Hollywood2'
        db_params = configHollywood2(params.paths);
    case 'HMDB51'
        db_params = configHMDB51(params.paths);
    case 'UCF101'
        db_params = configUCF101(params.paths);
    case 'MOBOT6a'
        db_params = configMOBOT6a(params.paths);
    otherwise
        error('Unrecognized database: %s', params.dbName)
end

prefix = ' -nodesktop -nosplash -r ';
add_path = sprintf('addpath(genpath(''%s''));', fullfile(code_path));
cd_path = sprintf('cd(''%s'');', params.paths.features);
main_config = sprintf('params = config_parser(''%s'');',configFile);
db_config = 'db_params = configUCF101(params.paths);';

clip_sind = [1:clips_per_cmd:length(db_params.clips)]+1; clip_sind(1) = 1; clip_sind(end) = [];
clip_eind = [1:clips_per_cmd:length(db_params.clips)]; clip_eind(1) = []; clip_eind(end) = length(db_params.clips);
clip_sets = [clip_sind', clip_eind'];
cmd = cell(size(clip_sets,1),1);

params.paths.training_root = params.paths.training;
params.paths.encodings_root = params.paths.encodings;
for s = 1:length(db_params.split);
    params.paths.training = fullfile(params.paths.training_root, sprintf('split_%d', s));
    params.paths.encodings = fullfile(params.paths.encodings_root, sprintf('split_%d', s));
    checkPaths(params.paths.training, 'create');
    checkPaths(params.paths.encodings, 'create');
    for clip_set_i=1:size(clip_sets,1)
        inner_cmd = sprintf('minimal_encoding(params, db_params.clips([%d:%d]), %d);', clip_sets(clip_set_i,1), clip_sets(clip_set_i,2), s);
        cmd{(s-1)*size(clip_sets,1)+clip_set_i} = ...
            [matlab_exec, prefix, '"', add_path, main_config, db_config, cd_path, inner_cmd, 'exit', '"'];
    end
end

fid = fopen(sprintf('./fn_%s_%s.txt', params.dbName, params.experiment_string), 'w');
fprintf(fid, '%s\n', cmd{:});
fclose(fid);
end


%     j=0;
%     for i=1:length(db_params.clips)
%         if params.reuse.encodings && exist(fullfile(params.paths.encodings, [db_params.clips(i).name '.mat']), 'file')
%             continue;
%         end
%         j=j+1;
%         disp(j)
%         inner_cmd = sprintf('minimal_encoding(params, db_params.clips(%d), %d);', i, s);
%         cmd{(s-1)*length(db_params.clips)+j} = [matlab_exec, prefix, '"', add_path, main_config, db_config, cd_path, inner_cmd, 'exit', '"'];
%     end
