function [] = check_encodings(config_file)
addpath(genpath('../'));
log = '/home/nick/log_enc_test.txt';
fid = fopen(log, 'w');
params = config_parser(config_file);
db_params = configUCF101(params.paths);
clips = db_params.clips;
splits = 1:3;

params.paths.training_root = params.paths.training;
params.paths.encodings_root = params.paths.encodings;

for i_split = 1:length(splits)
    params.paths.training = fullfile(params.paths.training_root, sprintf('split_%d', splits(i_split)));
    params.paths.encodings = fullfile(params.paths.encodings_root, sprintf('split_%d', splits(i_split)));
    checkPaths(params.paths.training, 'create');
    checkPaths(params.paths.encodings, 'create');
    for i_video = 1:length(clips)
        fprintf(fid, 'Checking encoding %d/%d for split %d/%d (%s)...\n',...
            i_video, length(clips), i_split, length(splits), clips(i_video).name);
        fprintf('Checking encoding %d/%d for split %d/%d (%s)...\n',...
            i_video, length(clips), i_split, length(splits), clips(i_video).name);
        % reduce unecessary disk I/O
        if (params.reuse.encodings)
            try 
                e=parload(fullfile(params.paths.encodings, clips(i_video).name));
                fprintf(fid, 'Encoding for %s exists.\n', clips(i_video).name); 
                fprintf('Encoding for %s exists.\n', clips(i_video).name); 
                if ~isstruct(e)
                    fprintf(fid,'Encoding for %s is NOT a struct.\n', clips(i_video).name); 
                    fprintf('Encoding for %s is NOT a struct.\n', clips(i_video).name); 
                    params.reuse.features = false;
                    params.reuse.encodings = false;
                    f = feature_extraction_wrapper(clips(i_video), params); %encoding does not exist
                    feature_encoding_wrapper(f, params, clips(i_video).name);                    
                    params.reuse.features = true;
                    params.reuse.encodings = true;
                    keyboard;
                end
                continue;
            catch
                fprintf('Encoding %s does not exist\n', fullfile(params.paths.encodings, clips(i_video).name)); 
                fprintf(fid,'Encoding for %s does not exist\n', clips(i_video).name); 
                f = feature_extraction_wrapper(clips(i_video), params); %encoding does not exist
                feature_encoding_wrapper(f, params, clips(i_video).name);                
            end
        else
            f = feature_extraction_wrapper(clips(i_video), params); %encoding does not exist
            feature_encoding_wrapper(f, params, clips(i_video).name);
        end
    end
end