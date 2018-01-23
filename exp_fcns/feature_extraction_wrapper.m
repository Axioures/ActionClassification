function f = feature_extraction_wrapper(clip, params)
    if (params.reuse.features) && exist(fullfile(params.paths.features, sprintf('%s.mat', clip.name)), 'file')
        try
            f = parload(fullfile(params.paths.features, clip.name));
        catch
            params.reuse.features = false;
            f = feature_extraction_wrapper(clip, params);
        end
    else
        f = extractFeatures(clip, params.features);
        %if params.features.segm
        %    f = reject_trajectories(f, clip, params);
        %end        
        if params.features.save2disk
            parsave(fullfile(params.paths.features, clip.name), f);
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%
    d = params.features.descriptors;
    if ~isempty(find(isnan(f.(d{1})), 1))
        params.reuse.features = false;
        f = feature_extraction_wrapper(clip, params);
    end
end

function f_clean = reject_trajectories(f, clip, params)
show = 0;
masks = sort(extractfield(dir(fullfile(params.paths.segmentation_path, clip.subject_name, 'rgb*')), 'name'))';
clip_masks = masks(clip.startFrame:clip.endFrame);
% masks_t = linspace(0,1,length(clip_masks));
masks_index = 1:length(clip_masks);
rejected = [];

% keyboard
se = strel('disk',50);
for i=1:length(f.info)
    mask = imread(fullfile(params.paths.segmentation_path, clip.subject_name, masks{f.info(i,1)}));
    afterClosing = imclose(mask,se);
    bb = regionprops(afterClosing>0,'BoundingBox');
    b = 1;
    bb(b).BoundingBox = [bb(b).BoundingBox(1)*0.8 bb(b).BoundingBox(2)*0.8 bb(b).BoundingBox(3)*2 bb(b).BoundingBox(4)*1.5];
%     if show
%         subplot(1,3,1); imshow(mask,[]);
%         figure; imshow(mask,[]); hold on;
%         subplot(1,3,2); imshow(afterOpening,[]);
%         afterMedian = medfilt2(afterOpening, [5 5]);
%         subplot(1,3,3); imshow(afterMedian,[]);
%         subplot(1,3,1); hold on;
%         rectangle('Position', bb(b).BoundingBox, 'EdgeColor','r', 'LineWidth', 3)
%         hold off
%         pause(0.01)
%         i
%     end   
    
    if f.info(i,3)<bb(b).BoundingBox(1) || f.info(i,3)>bb(b).BoundingBox(1)+bb(b).BoundingBox(2) || ...
            f.info(i,2)<bb(b).BoundingBox(3) || f.info(i,2)>bb(b).BoundingBox(3)+bb(b).BoundingBox(4)
        rejected = [rejected, i];
    end  
end

f_clean = f;
d = params.features.descriptors;
f_clean.info(rejected, :) = [];
for id = 1:length(d)
    f_clean.(d{id})(rejected, :) = [];
end
fprintf('%d/%d trajectories were rejected from clip %s\n.', length(rejected), length(f.info) ,clip.name);

% keyboard



end

% get_bb