function [] = svm_training_wrapper(params, training_clips, annotation)
    [~, empty] = aggregate_encodings(params.paths.encodings, params.paths.training, training_clips);
    annotation(empty) = [];
	switch params.classification.kernel
		case 'Linear'
            if params.classification.combine
                combine_by_concatenation(params.classification.combine_descriptors, params.paths.training);
            end
			multichannel_svm_linear_train(params, annotation);
        otherwise
            if params.state < 2.5
                compute_dist(params.classification.kernel, params.paths.training, params.channels);
            end
            compute_kernels(params.features.descriptors, params.channels, params.classification.combine_descriptors, params.paths.training);
			multichannel_svm_precomputed_train(params, annotation);		
	end
end


%% Precomputed kernel
function compute_dist(type, path, channels)
	c = channels;
	for i=1:length(c)
		msg_size = fprintf('Computing distances: channel %d/%d (%s)\n', i, length(c), c(i).name);
		encoded_features = parload(fullfile(path, sprintf('encoded_features_%s.mat', c(i).name)));
		switch type
			case 'ChiSquared'
				dist = distChiSq(encoded_features, encoded_features);
			otherwise
				error('Unsupported kernel type: %s', type);
		end
		parsave(fullfile(path, sprintf('dist_%s', c(i).name)), dist);
% 		erase_msg(msg_size, i==length(c));
	end
end

function compute_kernels(descriptors, channels, combine_descriptors, path)
	c = channels;
	d = descriptors;
	cd = combine_descriptors;
	tmp = parload(fullfile(path, sprintf('dist_%s.mat', c(1).name)));
	sz = size(tmp, 1);
	
	c_kernel = zeros(sz);
	for id = 1:length(d)
		msg_size = fprintf('Computing kernels: descriptor %d/%d (%s)\n', id, length(d), d{id});
		d_kernel = zeros(sz);
		cc = c(strcmp({c.descriptor}, d{id}));
		parfor icc = 1:length(cc)
			dist = parload(fullfile(path, sprintf('dist_%s.mat', cc(icc).name)));
			n = mean(dist(:)) + eps;
            k = exp( - dist / n ); % n = mean(k(:));
			d_kernel = d_kernel + k;
			
            if any(strcmp(cc(icc).descriptor, cd))
				c_kernel = c_kernel + k;
            end
            
            parsave(fullfile(path, sprintf('norm_%s.mat', cc(icc).name)), n);
		end
		kernel = d_kernel;
		parsave(fullfile(path, sprintf('kernel_%s.mat', d{id})), kernel);
% 		erase_msg(msg_size, id==length(d));
	end
	kernel = c_kernel;
	parsave(fullfile(path, sprintf('kernel_combined.mat')), kernel);
end

function multichannel_svm_precomputed_train(params, annotation)
	if exist('svm_savemodel') % is a MEX file
		fprintf('Note: "svm_savemodel" is available. SVMs will be saved in the libsvm format in $TRAINING_PATH$/models_libsvm_format/.\n');
		libsvm_format = true;
	else
		fprintf('Note: "svm_savemodel" is *not* available. SVMs will be saved in MATLAB format only.\n');
		libsvm_format = false;
	end
	d = params.features.descriptors;
	if params.classification.combine
		d{end+1} = 'combined';
	end
	for id = 1:length(d)
        msg_size = fprintf('Training SVMs: descriptor %d/%d (%s)\n', id, length(d), d{id});
		kernel = parload(fullfile(params.paths.training, sprintf('kernel_%s.mat', d{id})));
		models = multiclasss_svm_precomputed_train(kernel, annotation, params.classification.svm_cost);
		parsave(fullfile(params.paths.training, sprintf('models_%s.mat', d{id})), models);
        if libsvm_format
			output_path = fullfile(params.paths.training, 'models_libsvm_format', d{id});
			checkPaths(output_path, 'create', 'mute');
            for i=1:length(models)
				model_file = fullfile(output_path, sprintf('model%d', i));
				svm_savemodel(models{i}, model_file);
            end
        end
%         erase_msg(msg_size, id==length(d));
	end
end

function models = multiclasss_svm_precomputed_train(kernel, annotation, cost)
    if iscell(annotation) % more than one class per video
        classes = unique([annotation{:}]);
    else
        classes = unique(annotation);
    end
	K = [ (1:size(kernel,1))' , kernel ];
	models = cell(length(classes), 1); 
	for c = 1:length(classes)
        if iscell(annotation)
            oneVSall = cellfun(@(x, i) any(x==i), annotation, num2cell(ones(size(annotation))*classes(c)));
        else
            oneVSall = annotation==classes(c);
        end
        w_pos = length(annotation)/(2*sum(oneVSall));
        w_neg = length(annotation)/(2*sum(~oneVSall));
        parameters = sprintf('-t 4 -b 1 -q -c %d -w1 %f -w0 %f', cost, w_pos, w_neg);
%         parameters = sprintf('-t 4 -b 1 -q -c %d', num2str(cost));
		models{c} = svmtrain(double(oneVSall), K, parameters);
	end
end

%% Linear kernel
function combine_by_concatenation(comb_channels, path)
    if isstruct(comb_channels)
        c = {comb_channels.name};
    else
        c = comb_channels;
    end
    combined = [];
    for ic = 1:length(c)
        encoded_features = parload(fullfile(path, sprintf('encoded_features_%s.mat', c{ic})));
        combined = horzcat(combined, encoded_features);
    end
    parsave(fullfile(path, sprintf('encoded_features_combined.mat')), combined);
end

function multichannel_svm_linear_train(params, annotation)
	if exist('svm_savemodel') % is a MEX file
		fprintf('Note: "svm_savemodel" is available. SVMs will be saved in the libsvm format in $TRAINING_PATH$/models_libsvm_format/.\n');
		libsvm_format = true;
	else
		fprintf('Note: "svm_savemodel" is *not* available. SVMs will be saved in MATLAB format only.\n');
		libsvm_format = false;
	end
	d = params.features.descriptors;
	if params.classification.combine
		d{end+1} = 'combined';
	end
	for id = 1:length(d)
        msg_size = fprintf('Training SVMs: descriptor %d/%d (%s)\n', id, length(d), d{id});
		encoded_features = parload(fullfile(params.paths.training, sprintf('encoded_features_%s.mat', d{id})));
		models = multiclasss_svm_linear_train(encoded_features, annotation, params.classification.svm_cost);
		parsave(fullfile(params.paths.training, sprintf('models_%s.mat', d{id})), models);
        if libsvm_format
			output_path = fullfile(params.paths.training, 'models_libsvm_format', d{id});
			checkPaths(output_path, 'create', 'mute');
            for i=1:length(models)
				model_file = fullfile(output_path, sprintf('model%d', i));
				svm_savemodel(models{i}, model_file);
            end
        end
%         erase_msg(msg_size, id==length(d));
	end
end

function models = multiclasss_svm_linear_train(features, annotation, cost)
	classes = unique(annotation);
	models = cell(length(classes), 1); 
    for c = 1:length(classes)
		oneVSall = annotation==classes(c);
        w_pos = length(annotation)/(2*sum(oneVSall));
        w_neg = length(annotation)/(2*sum(~oneVSall));
        parameters = sprintf('-t 0 -b 1 -q -c %d -w1 %f -w0 %f', cost, w_pos, w_neg);
%         parameters = sprintf('-t 0 -b 1 -q -c %d', num2str(cost));
		models{c} = svmtrain(double(oneVSall), double(features), parameters);
    end
end