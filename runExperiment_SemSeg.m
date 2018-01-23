function [] = runExperiment_SemSeg(configFile)

    %% Configuration
%     keyboard
    params = config_parser(configFile);   
    db_params = configMOBOT6a(params.paths);
	params.paths.training_root = params.paths.training;
    params.paths.encodings_root = params.paths.encodings;
    params.paths.testing_root = params.paths.testing;
	testing_subjects = db_params.testing_subjects;
	training_subjects = db_params.training_subjects;
    
    
	for s=1:length(testing_subjects)
		print_dashed(sprintf('Leave-one-out mode (training): current testing subject is p%d', testing_subjects(s)));
		train_ind = find( ( [db_params.clips.subject]~=testing_subjects(s) ) & ismember([db_params.clips.subject], training_subjects) );
		training_clips = db_params.clips(train_ind);
		params.paths.training = fullfile(params.paths.training_root, sprintf('test_p%d', testing_subjects(s)));
        params.paths.encodings = fullfile(params.paths.encodings_root, sprintf('test_p%d', testing_subjects(s)));
		checkPaths(params.paths.training, 'create');
        checkPaths(params.paths.encodings, 'create');

		%% Compute the Codebook
		if params.state <1
			compute_codebook_wrapper_SemSeg(params, training_clips, params.global_seed);
		end

		if params.state<2			
            for i=1:length(training_clips)
				% extract features
				msg_size = fprintf('Extracting features: video %d/%d', i, length(training_clips)); 
				[f,f_clean] = feature_extraction_wrapper_SemSeg(training_clips(i), params);
				erase_msg(msg_size);
				
				% encode features
				msg_size = fprintf('Encoding features: video %d/%d\n', i, length(training_clips)); 
				encoded_features = feature_encoding_wrapper_SemSeg(f, f_clean, params, training_clips(i).name);
            end
		end

		%% Train SVMs
		if params.state < 3
		   svm_training_wrapper(params, training_clips, db_params.annotation(train_ind));
		end
    end
    
    %% Testing
    for s=1:length(testing_subjects)
		print_dashed(sprintf('Leave-one-out mode (testing): current testing subject is p%d', testing_subjects(s)));
		test_ind = find(ismember([db_params.clips.subject], testing_subjects(s)));
		testing_clips = db_params.clips(test_ind);
		params.paths.training = fullfile(params.paths.training_root, sprintf('test_p%d', testing_subjects(s)));
		params.paths.testing = fullfile(params.paths.testing_root, sprintf('test_p%d', testing_subjects(s)));
        params.paths.encodings = fullfile(params.paths.encodings_root, sprintf('test_p%d', testing_subjects(s)));
		checkPaths(params.paths.testing, 'create');
		
		d = params.features.descriptors;
		if params.classification.combine
			d{end+1} = 'combined';
		end
		classes = init_struct_array(d, length(testing_clips));
		probs = init_struct_array(d, length(testing_clips));
		
		for i=1:length(testing_clips)
			msg_size = fprintf('Testing video %d/%d\n', i, length(testing_clips)); 
			
			% extract features
			[f,f_clean] = feature_extraction_wrapper_SemSeg(testing_clips(i), params);
			
			% encode features
			encoded_features = feature_encoding_wrapper_SemSeg(f, f_clean, params, testing_clips(i).name);
			
			% classify
			[classes(i), probs(i)] = svm_testing_wrapper(encoded_features, params);
		end
		accuracy = compute_accuracy(classes, db_params.annotation(test_ind));
		confusion_matrix = confMatrix_multiclass(classes, db_params.annotation(test_ind), db_params.num.classes);
		parsave(fullfile(params.paths.testing, 'results_long.mat'), accuracy, confusion_matrix, classes, probs);
    end
    
end
