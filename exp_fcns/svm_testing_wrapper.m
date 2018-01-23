function [class, probs, dist, kernels] = svm_testing_wrapper(encoded_features, params)
    if isempty(encoded_features)
        d = params.features.descriptors;
        if params.classification.combine && ~any(ismember(d,  'combined'))
                d{end+1} = 'combined';
        end
        n_classes = length(parload(fullfile(params.paths.training, sprintf('models_%s.mat', d{1}))));
        for i=1:length(d)
            class.(d{i}) = round(rand(1,1)*n_classes+1);
            probs.(d{i}) = rand(1,n_classes);
        end
        return
    end

	switch params.classification.kernel
		case 'Linear'
            if params.classification.combine
                encoded_features.combined = combine_by_concatenation(encoded_features, params.classification.combine_descriptors);
            end
			[class, probs] = multichannel_svm_linear_test(encoded_features, params);
		otherwise
			dist = compute_dist(encoded_features, params.classification.kernel, params.paths.training, params.channels);
			kernels = compute_kernels(dist, params.features.descriptors, params.channels, params.classification.combine_descriptors, params.paths.training);
			[class, probs] = multichannel_svm_precomputed_test(kernels, params);
	end
end

%% Precomputed kernel
function dist = compute_dist(encoded_features, kernel_type, path, channels)
	c = channels;
	dist = cell2struct(cell(size(c)), {c.name}, 1);
	for i=1:length(c)
		encoded_features_training = parload(fullfile(path, sprintf('encoded_features_%s.mat', c(i).name)));
		switch kernel_type
			case 'ChiSquared'
				dist.(c(i).name) = distChiSq(encoded_features.(c(i).name), encoded_features_training);
			otherwise
				error('Unsupported kernel type: %s', type);
		end
	end
end

function kernel = compute_kernels(dist, descriptors, channels, combine_descriptors, path)
	c = channels;
	d = descriptors;
	cd = combine_descriptors;
	sz = size(dist.(c(1).name));
	
	kernel = init_struct_array(d, 1);
	c_kernel = zeros(sz);
	for id = 1:length(d)
		d_kernel = zeros(sz);
		cc = c(strcmp({c.descriptor}, d{id}));
		for icc = 1:length(cc)
			n = parload(fullfile(path, sprintf('norm_%s.mat', cc(icc).name)));
%             n = parload(fullfile('/home/nick/Desktop/Gesture_OUTPUT/DT_k-means_hardVoting_grids_1_visWords_4000_data_100000_PCA_0.50/KTH/intermediate', sprintf('normalization_kernel_h1v1t1%s.mat', cc(icc).name)));
			d_kernel = d_kernel + exp( - dist.(cc(icc).name) /n );
			
			if any(strcmp(cc(icc).descriptor, cd))
				c_kernel = c_kernel + exp( - dist.(cc(icc).name) / n );
			end
		end
		kernel.(d{id}) = d_kernel;
	end
	kernel.combined = c_kernel;
end

function [class, probs] = multichannel_svm_precomputed_test(kernel, params)
	d = params.features.descriptors;
	if params.classification.combine
		d{end+1} = 'combined';
	end
	
	class = init_struct_array(d, 1);
	probs = init_struct_array(d, 1);
	for id = 1:length(d)
		models = parload(fullfile(params.paths.training, sprintf('models_%s.mat', d{id})));
		[class.(d{id}), probs.(d{id})] = multiclasss_svm_precomputed_test(kernel.(d{id}), models);
	end

end

function [class,probs] = multiclasss_svm_precomputed_test(kernel, models)
    probs = zeros(1, length(models));
    kernel = [1 kernel];
	for m=1:length(models)
		[~,~,p] = svmpredict(0, kernel, models{m} ,'-b 1 -q');
		probs(m) = p(models{m}.Label==1);
	end
	[~,class] = max(probs);
end

%% Linear kernel
function combined = combine_by_concatenation(encoded_features, comb_channels)
    if isstruct(comb_channels)
        c = {comb_channels.name};
    else
        c = comb_channels;
    end
    combined = [];
    for ic = 1:length(c)
        combined = horzcat(combined, encoded_features.(c{ic}));
    end
end

function [class,probs] = multichannel_svm_linear_test(encoded_features, params)
	d = params.features.descriptors;
	if params.classification.combine
		d{end+1} = 'combined';
	end
	
	class = init_struct_array(d, 1);
	probs = init_struct_array(d, 1);
	for id = 1:length(d)
		models = parload(fullfile(params.paths.training, sprintf('models_%s.mat', d{id})));
		[class.(d{id}), probs.(d{id})] = multiclasss_svm_linear_test(encoded_features.(d{id}), models);
	end
end

function [class,probs] = multiclasss_svm_linear_test(encoded_features, models)
    probs = zeros(1, length(models));
	for m=1:length(models)
		[~,~,p] = svmpredict(0, double(encoded_features), models{m} ,'-b 1 -q');
		probs(m) = p(models{m}.Label==1);
	end
	[~,class] = max(probs);
end
