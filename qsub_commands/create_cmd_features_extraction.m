function [] = create_cmd_features_extraction(configFile, code_path, matlab_exec)

addpath(genpath(code_path));
params = config_parser(configFile);
switch params.dbName
    case 'KTH'
        db_params = configKTH(params.paths);
        create_commands_KTH(params, db_params, code_path, matlab_exec);
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

j=0;
for i=1:length(db_params.clips)
    if params.reuse.features && exist(fullfile(params.paths.features, [db_params.clips(i).name '.mat']), 'file')
        continue;
    end
    j=j+1;
    inner_cmd = sprintf('feature_extraction_wrapper(db_params.clips(%d), params);', i);
    cmd{j} = [matlab_exec, prefix, '"', add_path, main_config, db_config, cd_path, inner_cmd, 'exit', '"'];
end

fid = fopen(sprintf('./fx_%s_%s.txt', params.dbName, params.experiment_string), 'w');
fprintf(fid, '%s\n', cmd{:});
fclose(fid);
end


