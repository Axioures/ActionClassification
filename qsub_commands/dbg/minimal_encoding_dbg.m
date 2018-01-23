function [] = minimal_encoding_dbg(params, clips, splits)

params.paths.training_root = params.paths.training;
params.paths.encodings_root = params.paths.encodings;

for i_split = 1:length(splits)
    params.paths.training = fullfile(params.paths.training, sprintf('split_%d', i_split));
    params.paths.encodings = fullfile(params.paths.encodings, sprintf('split_%d', i_split));
    checkPaths(params.paths.training, 'create');
    checkPaths(params.paths.encodings, 'create');
    for i_video = 1:length(clips)
        fprintf('Encoding %d/%d videos for split %d/%d (%s)...\n',...
            i_video, length(clips), i_split, length(splits), clips(i_video).name);
        % reduce unecessary disk I/O
        if ~(params.reuse.encodings) || ~exist(fullfile(params.paths.encodings, sprintf('%s.mat', clips(i_video).name)), 'file')
	    fprintf('Loading features\n')
	    tic
            f = feature_extraction_wrapper(clips(i_video), params);
	    toc
        else
            f = [];
        end
        feature_encoding_wrapper_dbg(f, params, clips(i_video).name);
    end
end
