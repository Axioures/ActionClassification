function [] = HMDB51_training(params, db_params)
	params.paths.training_root = params.paths.training;
    params.paths.encodings_root = params.paths.encodings;
    
	for s=1:db_params.num.splits
		training_clips = db_params.clips(db_params.split(s).training);
		params.paths.training = fullfile(params.paths.training_root, sprintf('split_%d', s));
        params.paths.encodings = fullfile(params.paths.encodings_root, sprintf('split_%d', s));
		checkPaths(params.paths.training, 'create');
        checkPaths(params.paths.encodings, 'create');

		%% Compute the Codebook
		if params.state <1
			compute_codebook_wrapper(params, training_clips, params.global_seed);
		end

		if params.state<2
            for i=1:length(training_clips)
				% extract features
				fprintf('Extracting features: video %d/%d (%s)\n', i, length(training_clips), training_clips(i).name); 
				f = feature_extraction_wrapper(training_clips(i), params);
				
				% encode features
				fprintf('Encoding features: video %d/%d (%s)\n', i, length(training_clips), training_clips(i).name); 
				encoded_features = feature_encoding_wrapper(f, params, training_clips(i).name);
            end
		end

		%% Train SVMs
		if params.state < 3
		   svm_training_wrapper(params, training_clips, db_params.split(s).training_annotation);
		end
	end
end