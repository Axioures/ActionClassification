function [] = MOBOT6a_testing(params, db_params)
	params.paths.training_root = params.paths.training;
    params.paths.encodings_root = params.paths.encodings;
	params.paths.testing_root = params.paths.testing;
	testing_subjects = db_params.testing_subjects;
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
			f = feature_extraction_wrapper(testing_clips(i), params);
			
			% encode features
			encoded_features = feature_encoding_wrapper(f, params, testing_clips(i).name);
			
			% classify
			[classes(i), probs(i)] = svm_testing_wrapper(encoded_features, params);
		end
		accuracy = compute_accuracy(classes, db_params.annotation(test_ind));
		confusion_matrix = confMatrix_multiclass(classes, db_params.annotation(test_ind), db_params.num.classes);
		parsave(fullfile(params.paths.testing, 'results_long.mat'), accuracy, confusion_matrix, classes, probs);
	end
end
