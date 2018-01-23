function [] = Hollywood2_testing(params, db_params)
	testing_clips = db_params.clips(db_params.testing);
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
    mAP = computeMAP_multichannel(probs, db_params.annotation_testing)
    parsave(fullfile(params.paths.testing, 'results.mat'), mAP, classes, probs);
	
end
