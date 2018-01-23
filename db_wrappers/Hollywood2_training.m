function [] = Hollywood2_training(params, db_params)
	training_clips = db_params.clips(db_params.training);

	%% Compute the Codebook
	if params.state <1
		compute_codebook_wrapper(params, training_clips, params.global_seed);
	end

	if params.state<2
        for i=1:length(training_clips)
			% extract features
			msg_size = fprintf('Extracting features: video %d/%d\n', i, length(training_clips)); 
			f = feature_extraction_wrapper(training_clips(i), params);
			erase_msg(msg_size);
			
			% encode features
			msg_size = fprintf('Encoding features: video %d/%d\n', i, length(training_clips)); 
			encoded_features = feature_encoding_wrapper(f, params, training_clips(i).name);
        end
	end

	%% Train SVMs
	if params.state < 3
	   svm_training_wrapper(params, training_clips, db_params.annotation_training)
	end
end
