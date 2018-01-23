function [] = minimal_encoding(params, clips, splits)

params.paths.training_root = params.paths.training;
params.paths.encodings_root = params.paths.encodings;

for i_split = 1:length(splits)
    params.paths.training = fullfile(params.paths.training_root, sprintf('split_%d', splits(i_split)));
    params.paths.encodings = fullfile(params.paths.encodings_root, sprintf('split_%d', splits(i_split)));
    checkPaths(params.paths.training, 'create');
    checkPaths(params.paths.encodings, 'create');
    for i_video = 1:length(clips)
        fprintf('Encoding %d/%d videos for split %d/%d (%s)...\n',...
            i_video, length(clips), i_split, length(splits), clips(i_video).name);
        % reduce unecessary disk I/O
        if (params.reuse.encodings)
            try 
                parload(fullfile(params.paths.encodings, clips(i_video).name));
                fprintf('Encoding for %s exists and is ok\n', clips(i_video).name); 
                continue;
            catch
                fprintf('Encoding for %s does not exist\n', clips(i_video).name); 
                try
                    f = feature_extraction_wrapper(clips(i_video), params); %encoding does not exist
                catch
                    fprintf('Features for for %s are not ok. Re-computing...\n', clips(i_video).name); 
                    params.reuse.features = false;
                    f = feature_extraction_wrapper(clips(i_video), params); %encoding does not exist
                    params.reuse.features = true;
                end
                params.reuse.encodings = false;
                feature_encoding_wrapper(f, params, clips(i_video).name);
                params.reuse.encodings = true;
            end
        else
            f = feature_extraction_wrapper(clips(i_video), params); %encoding does not exist
            feature_encoding_wrapper(f, params, clips(i_video).name);
        end
    end
end