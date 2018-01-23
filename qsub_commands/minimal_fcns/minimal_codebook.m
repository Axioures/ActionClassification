function [] = minimal_codebook(params, db_params, i_split)


training_clips = db_params.clips(db_params.split(i_split).training);
params.paths.training = fullfile(params.paths.training, sprintf('split_%d', i_split));
params.paths.encodings = fullfile(params.paths.encodings, sprintf('split_%d', i_split));
checkPaths(params.paths.training, 'create');
checkPaths(params.paths.encodings, 'create');

compute_codebook_wrapper(params, training_clips, params.global_seed);

end
