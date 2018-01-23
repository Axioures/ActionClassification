function [] = cvsp_testing(params, db_params)
	params.paths.training_root = params.paths.training;
    params.paths.encodings_root = params.paths.encodings;
	params.paths.testing_root = params.paths.testing;
	splits = db_params.splits;
	for s=1:length(splits)
        test_sub = splits(s).test_subject;
        test_sub_name = db_params.subject_names{test_sub};
		print_dashed(sprintf('Leave-one-out mode (testing): current testing subject is %s', test_sub_name));
		test_ind = splits(s).testing;
		testing_clips = db_params.clips(test_ind);
		params.paths.training = fullfile(params.paths.training_root, sprintf('test_%s', test_sub_name));
		params.paths.testing = fullfile(params.paths.testing_root, sprintf('test_%s', test_sub_name));
        params.paths.encodings = fullfile(params.paths.encodings_root, sprintf('test_%s', test_sub_name));
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
