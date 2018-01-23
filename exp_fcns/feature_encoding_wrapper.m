function encoded_features = feature_encoding_wrapper(features, params, clip_name)
    if (params.reuse.encodings) && exist('clip_name', 'var')
        try
            encoded_features = parload(fullfile(params.paths.encodings, clip_name));
        catch
            params.reuse.encodings = false;
            encoded_features = feature_encoding_wrapper(features, params, clip_name);
        end            
    else
        %d = fieldnames(features);
        if isempty(features)
            encoded_features = features;
            parsave(fullfile(params.paths.encodings, clip_name), encoded_features);
            return;
        end
        switch params.encoding.type
            case 'BoVW'
                encoded_features = encode_multichannel_bof(features, params);
            case 'fisher'
                encoded_features = encode_multichannel_fisher(features, params);
            case 'vlad'
                encoded_features = encode_multichannel_vlad(features, params);
        end
        parsave(fullfile(params.paths.encodings, clip_name), encoded_features);
    end
end

function encoded_features = encode_multichannel_bof(features, params)
	c = params.channels;
    encoded_features = cell2struct(cell(size(c)), {c.name}, 1);
    for i=1:length(c)
        codebook = parload(fullfile(params.paths.training, sprintf('codebook_%s.mat', c(i).descriptor)))';
        if params.pyramids
			encoded_features.(c(i).name) = BagOfFeaturesPyramid(features.(c(i).descriptor), codebook, c(i).grid, features.info);
        else
			encoded_features.(c(i).name) = BagOfFeatures(codebook, features.(c(i).descriptor));
        end
    end
end

function encoded_features = encode_multichannel_vlad(features, params)
	c = params.channels;
	encoded_features = cell2struct(cell(length(c),1), {c.name}, 1);
	for i=1:length(c)
		codebook = parload(fullfile(params.paths.training, sprintf('codebook_%s.mat', c(i).descriptor)))';
		encoded_features.(c(i).name) = encode_vlad(features.(c(i).name), codebook);
	end
end

function encoded_features = encode_multichannel_fisher(features, params)
	c = params.channels;
	encoded_features = cell2struct(cell(length(c),1), {c.name}, 1);
	for i=1:length(c)
		gmm = parload(fullfile(params.paths.training, sprintf('codebook_%s.mat', c(i).name)));
		encoded_features.(c(i).name) = encode_fisher(features.(c(i).name), gmm);
	end
end
        

function fv = encode_fisher(features, gmm)
	features_normalized = zscore(features);
	features_reduced = gmm.princomp' * features_normalized';
	fv = yael_fisher(single(features_reduced),gmm.w,gmm.mu, gmm.sigma, 'sigma')';
end

function vlad = encode_vlad(features, codebook)
% 	features_normalized = zscore(features);
% 	features_reduced = codebook.princomp' * features_normalized';
    features_reduced = features';
    codebook = codebook';
    kdtree = vl_kdtreebuild(codebook);
    nn = vl_kdtreequery(kdtree, double(codebook), double(features_reduced));
    assignments = zeros(size(codebook,2),size(features_reduced,2));
    assignments(sub2ind(size(assignments), double(nn), 1:length(nn))) = 1;
    vlad  = vl_vlad(double(features_reduced),double(codebook),assignments,'NormalizeComponents')';
end

function bof = BagOfFeaturesPyramid(features, codebook, grid, info)
	K = size(codebook, 1);
	bof = zeros(1, K*grid.num_cells);
	partialSum = zeros(size(features, 1),1);
	for c = 1:grid.num_cells
		ind = ...
			(info(:,8)>grid.cells(c).xStart) & (info(:,8)<=grid.cells(c).xEnd)...
			& (info(:,9)>grid.cells(c).yStart) & (info(:,9)<=grid.cells(c).yEnd) ...
			& (info(:,10)>grid.cells(c).tStart) & (info(:,10)<=grid.cells(c).tEnd);
		partialSum=xor(partialSum, ind);
		[~, bof((c-1)*K+1:c*K)] = BagOfFeatures(codebook, features(ind,:));
	end
	bof = bof/(sqrt(bof*bof')+eps);
	if ~all(partialSum) % just a test ...
		error('s.t. pyramids error!\n')
	end
end
