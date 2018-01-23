function [f,f_arm1,f_arm2,f_human] = feature_extraction_wrapper_SemSeg(clip, params)
    if (params.reuse.features)
        try
            f = parload(fullfile(params.paths.features, clip.name));
        catch
            params.reuse.features = false;
            [f] = feature_extraction_wrapper_SemSeg(clip, params);
        end
        try
            f_arm1 = parload(fullfile(params.paths.features_arm_1, [clip.name '.mat']));
        catch
            f_arm1 = features_arms(f, clip, params, 'right');
            if params.features.save2disk
                parsave(fullfile(params.paths.features_arm_1, clip.name), f_arm1);
            end           
        end
        try
            f_arm2 = parload(fullfile(params.paths.features_arm_2, [clip.name '.mat']));
        catch
            f_arm2 = features_arms(f, clip, params, 'left');
            if params.features.save2disk
                parsave(fullfile(params.paths.features_arm_2, clip.name), f_arm2);
            end           
        end
        try
            f_human = parload(fullfile(params.paths.features_human, [clip.name '.mat']));
        catch
            f_human = features_human(f, clip, params);
            if params.features.save2disk
                parsave(fullfile(params.paths.features_human, clip.name), f_human);
            end           
        end                    
    else
        f = extractFeatures(clip, params.features);
        f_arm1 = features_arms(f, clip, params, 'right');
        f_arm2 = features_arms(f, clip, params, 'left');
        f_human = features_human(f, clip, params);
        if params.features.save2disk
            parsave(fullfile(params.paths.features, clip.name), f);
            parsave(fullfile(params.paths.features_arm1, clip.name), f_arm1);
            parsave(fullfile(params.paths.features_arm2, clip.name), f_arm2);
            parsave(fullfile(params.paths.features_human, clip.name), f_human);
        end
    end
    
    d = params.features.descriptors;
    if ~isempty(find(isnan(f.(d{1})), 1))
        params.reuse.features = false;
        f = feature_extraction_wrapper_SemSeg(clip, params);
    end
end

function [f_arm] = features_arms(f, clip, params, arm_id)
show = 1;
masks = sort(extractfield(dir(fullfile(params.paths.segmentation_path, clip.subject_name, 'rgb*')), 'name'))';
clip_masks = masks(clip.startFrame:clip.endFrame);
% masks_t = linspace(0,1,length(clip_masks));
masks_index = 1:length(clip_masks);
rejected = [];
not_rejected = [];

% keyboard
se = strel('disk',50);
previous_bb = [];
for i=1:length(f.info)
    mask = imread(fullfile(params.paths.segmentation_path, clip.subject_name, masks{round(f.info(i,1)-params.features.L/2)}));
%         afterClosing = imclose(mask,se);
%         bb = regionprops(afterClosing>0,'BoundingBox');
%         b = 1;
%         bb(b).BoundingBox = [bb(b).BoundingBox(1)*0.8 bb(b).BoundingBox(2)*0.8 bb(b).BoundingBox(3)*2 bb(b).BoundingBox(4)*1.5];
% %         if show
% %             subplot(1,3,1); imshow(mask,[]);
% %             figure; imshow(mask,[]); hold on;
% %             subplot(1,3,2); imshow(afterOpening,[]);
% %             afterMedian = medfilt2(afterOpening, [5 5]);
% %             subplot(1,3,3); imshow(afterMedian,[]);
% %             subplot(1,3,1); hold on;
% %             rectangle('Position', bb(b).BoundingBox, 'EdgeColor','r', 'LineWidth', 3)
% %             hold off
% %             pause(0.01)
% %             i
% %         end
    if strcmp(arm_id,'right')
        arm_mask = mask==5;
    elseif strcmp(arm_id,'left')
        arm_mask = mask==6;
    else
        error('unknown arm');
    end
    afterMedian = medfilt2(arm_mask, [5 5]);
    CC = bwconncomp(arm_mask);
    numPixels = cellfun(@numel,CC.PixelIdxList);
    [biggest,idx] = max(numPixels);
    arm_mask_clean = uint8(arm_mask);
    arm_mask_clean(CC.PixelIdxList{idx}) = 2;
    arm_mask_clean(arm_mask_clean~=2) = 0;
    arm_mask_clean(arm_mask_clean==2) = 1;

    bb = regionprops(arm_mask_clean>0,'BoundingBox');
    b = 1;
    if isempty(bb)
        if isempty(previous_bb)
%             bb = get_human_bb; %% TODO
            bb(b).BoundingBox = [1 1 fliplr(size(I))];
        else
            bb = previous_bb;
        end
    else
        bb(b).BoundingBox = [.9*bb(b).BoundingBox(1) .9*bb(b).BoundingBox(2)...
            bb(b).BoundingBox(3)+.2*bb(b).BoundingBox(1) bb(b).BoundingBox(4)+.2*bb(b).BoundingBox(2)];
        previous_bb = bb;
    end

    if show
        subplot(1,3,1); imshow(mask,[]); hold on;
        rectangle('Position', bb(b).BoundingBox, 'EdgeColor','r', 'LineWidth', 3)
        hold off;
        subplot(1,3,2); imshow(arm_mask,[]);
        subplot(1,3,3); imshow(arm_mask_clean,[]);
        pause(0.1)
    end
%     keyboard;

    if f.info(i,2)<bb(b).BoundingBox(1) || f.info(i,2)>bb(b).BoundingBox(1)+bb(b).BoundingBox(3) || ...
            f.info(i,3)<bb(b).BoundingBox(2) || f.info(i,3)>bb(b).BoundingBox(2)+bb(b).BoundingBox(4)
        rejected = [rejected, i];
    else
        if show
            not_rejected = [not_rejected, i];
        end
    end

    if show
        subplot(1,3,1); hold on;
        plot(f.info(rejected,2), f.info(rejected,3), 'm.');
        plot(f.info(not_rejected,2), f.info(not_rejected,3), 'g.');
        hold off
        pause(0.1)
    end    
end

f_arm = f;
d = params.features.descriptors;
f_clean.info(rejected, :) = [];
for id = 1:length(d)
    f_clean.(d{id})(rejected, :) = [];
end
fprintf('%d/%d trajectories were rejected from clip %s\n.', length(rejected), length(f.info) ,clip.name);

% keyboard



end

function [f_human] = features_human(f, clip, params)
show = 1;
masks = sort(extractfield(dir(fullfile(params.paths.segmentation_path, clip.subject_name, 'rgb*')), 'name'))';
clip_masks = masks(clip.startFrame:clip.endFrame);
% masks_t = linspace(0,1,length(clip_masks));
masks_index = 1:length(clip_masks);
rejected = [];
not_rejected = [];

% keyboard
se = strel('disk',50);
previous_bb = [];
for i=1:length(f.info)
    mask = imread(fullfile(params.paths.segmentation_path, clip.subject_name, masks{round(f.info(i,1)-params.features.L/2)}));
        afterClosing = imclose(mask,se);
        bb = regionprops(afterClosing>0,'BoundingBox');
        b = 1;
        bb(b).BoundingBox = [bb(b).BoundingBox(1)*0.8 bb(b).BoundingBox(2)*0.8 bb(b).BoundingBox(3)*2 bb(b).BoundingBox(4)*1.5];


    if show
        subplot(1,3,1); imshow(mask,[]); hold on;
        rectangle('Position', bb(b).BoundingBox, 'EdgeColor','r', 'LineWidth', 3)
        hold off;
        subplot(1,3,2); imshow(afterMedian,[]);
        subplot(1,3,3); imshow(right_arm_mask_clean,[]);
        pause(0.1)
    end
%     keyboard;

    if f.info(i,2)<bb(b).BoundingBox(1) || f.info(i,2)>bb(b).BoundingBox(1)+bb(b).BoundingBox(3) || ...
            f.info(i,3)<bb(b).BoundingBox(2) || f.info(i,3)>bb(b).BoundingBox(2)+bb(b).BoundingBox(4)
        rejected = [rejected, i];
    else
        if show
            not_rejected = [not_rejected, i];
        end
    end

    if show
        subplot(1,3,1); hold on;
        plot(f.info(rejected,2), f.info(rejected,3), 'm.');
        plot(f.info(not_rejected,2), f.info(not_rejected,3), 'g.');
        hold off
        pause(0.1)
    end    
end


f_human = f;
d = params.features.descriptors;
f_clean.info(rejected, :) = [];
for id = 1:length(d)
    f_clean.(d{id})(rejected, :) = [];
end
fprintf('%d/%d trajectories were rejected from clip %s\n.', length(rejected), length(f.info) ,clip.name);

% keyboard



end

