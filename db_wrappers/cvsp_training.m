function [] = cvsp_training(params, db_params)
	params.paths.training_root = params.paths.training;
    params.paths.encodings_root = params.paths.encodings;
    splits = db_params.splits;
	for s=length(splits)-1:length(splits)
        test_sub = splits(s).test_subject;
        test_sub_name = db_params.subject_names{test_sub};
		print_dashed(sprintf('Leave-one-out mode (training): current testing subject is %s', test_sub_name));
		train_ind = splits(s).training;
		training_clips = db_params.clips(train_ind);
		params.paths.training = fullfile(params.paths.training_root, sprintf('test_%s', test_sub_name));
        params.paths.encodings = fullfile(params.paths.encodings_root, sprintf('test_%s', test_sub_name));
		checkPaths(params.paths.training, 'create');
        checkPaths(params.paths.encodings, 'create');

		%% Compute the Codebook
		if params.state <1
			compute_codebook_wrapper(params, training_clips, params.global_seed);
		end

		if params.state<2			
            for i=1:length(training_clips)
				% extract features
				msg_size = fprintf('Extracting features: video %d/%d', i, length(training_clips)); 
				f = feature_extraction_wrapper(training_clips(i), params);
				erase_msg(msg_size);
				
				% encode features
				msg_size = fprintf('Encoding features: video %d/%d\n', i, length(training_clips)); 
				encoded_features = feature_encoding_wrapper(f, params, training_clips(i).name);
            end
		end

		%% Train SVMs
		if params.state < 3
		   svm_training_wrapper(params, training_clips, db_params.annotation(train_ind));
		end
	end
end