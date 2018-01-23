function [] = thumos14_testing(params_train, params_test, test_db_params, train_db_params)
	
    params = params_test;
    params.paths.testing_root = params.paths.testing;
	params.paths.training_root = params_train.paths.training;
    params.paths.encodings_root = params.paths.encodings;
	
    for s=1:test_db_params.num.splits
		testing_clips = test_db_params.clips(test_db_params.split(s).testing);
		params.paths.testing = fullfile(params.paths.testing_root, sprintf('split_%d', s));
		params.paths.training = fullfile(params.paths.training_root, sprintf('split_%d', s));
        params.paths.encodings = fullfile(params.paths.encodings_root, sprintf('split_%d', s));
		checkPaths(params.paths.testing, 'create');
        checkPaths(params.paths.encodings, 'create');

		
		d = params.features.descriptors;
		if params.classification.combine && ~any(ismember(d,  'combined'))
			d{end+1} = 'combined';
		end
		classes = init_struct_array(d, length(testing_clips));
		probs = init_struct_array(d, length(testing_clips));
		
		for i=1:length(testing_clips)
            fprintf('Testing video %d/%d (%s)\n ', i, length(testing_clips), testing_clips(i).name); 
			
			% extract features
			f = feature_extraction_wrapper(testing_clips(i), params);
			
			% encode features
			encoded_features = feature_encoding_wrapper(f, params, testing_clips(i).name);
			
			% classify
			[classes(i), probs(i)] = svm_testing_wrapper(encoded_features, params);			
		end
		accuracy = compute_accuracy(classes, test_db_params.split(s).testing_annotation')
		confusion_matrix = confMatrix_multiclass(classes, test_db_params.split(s).testing_annotation, test_db_params.num.classes);
		parsave(fullfile(params.paths.testing, 'results.mat'), accuracy, confusion_matrix, classes, probs, test_db_params.split(s).testing_annotation);
	end
end
