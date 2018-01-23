function [] = create_cmd_testing(configFile, code_path, matlab_exec)

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

num_splits = length(db_params.split);

prefix = ' -nodesktop -nosplash -r ';
add_path = sprintf('addpath(genpath(''%s''));', fullfile(code_path));
main_config = sprintf('params = config_parser(''%s'');',configFile);
db_config = 'db_params = configUCF101(params.paths);';

for s = 1:num_splits
    inner_cmd = sprintf('minimal_testing(params, db_params, %d);', s);
    cmd{s} = [matlab_exec, prefix, '"', add_path, main_config, db_config, inner_cmd, 'exit', '"'];
end

fid = fopen(sprintf('./test_%s_%s.txt', params.dbName, params.experiment_string), 'w');
fprintf(fid, '%s\n', cmd{:});
fclose(fid);
end


