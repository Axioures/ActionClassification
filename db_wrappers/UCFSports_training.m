function [] = UCFSports_training(params, db_params)
	training_clips = db_params.clips(db_params.training);

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
	   svm_training_wrapper(params, training_clips, db_params.annotation_training)
	end
end
