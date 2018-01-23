function [] = KTH_testing(params, db_params)
	testing_clips = db_params.clips(db_params.testing);
	d = params.features.descriptors;
	
    if params.classification.combine
		d{end+1} = 'combined';
    end
	classes = init_struct_array(d, length(testing_clips));
	probs = init_struct_array(d, length(testing_clips));
	
	parfor i=1:length(testing_clips)
		fprintf('Testing video %d/%d (%s)\n ', i, length(testing_clips), testing_clips(i).name); 
		
		% extract features
		f = feature_extraction_wrapper(testing_clips(i), params);
		
		% encode features
		encoded_features = feature_encoding_wrapper(f, params, testing_clips(i).name);
		
		% classify
		[classes(i), probs(i)] = svm_testing_wrapper(encoded_features, params);

	end
	accuracy = compute_accuracy(classes, db_params.annotation_testing)
	confusion_matrix = confMatrix_multiclass(classes, db_params.annotation_testing, db_params.num.classes);
    parsave(fullfile(params.paths.testing, 'results.mat'), accuracy, confusion_matrix, classes, probs);
	
end
