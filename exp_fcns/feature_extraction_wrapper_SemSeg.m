function [f,f_clean] = feature_extraction_wrapper_SemSeg(clip, params)
    if (params.reuse.features)
        try
            f = parload(fullfile(params.paths.features, clip.name));
        catch
            params.reuse.features = false;
            [f,f_clean] = feature_extraction_wrapper_SemSeg(clip, params);
        end
        if params.features.segm
            try
                f_clean = parload(fullfile(params.paths.features_clean, [clip.name '.mat']));
            catch
                f_clean = features_arms(f, clip, params);
                if params.features.save2disk
                    parsave(fullfile(params.paths.features_clean, clip.name), f_clean);
                end           
            end
        else
            f_clean = [];
        end        
    else
        f = extractFeatures(clip, params.features);
        if params.features.segm
            f_clean = features_arms(f, clip, params);
        else
            f_clean = [];
        end        
        if params.features.save2disk
            parsave(fullfile(params.paths.features, clip.name), f);
            if params.features.segm
                parsave(fullfile(params.paths.features_clean, clip.name), f_clean);
            end
        end
    end
    
    d = params.features.descriptors;
    if ~isempty(find(isnan(f.(d{1})), 1))
        params.reuse.features = false;
        f = feature_extraction_wrapper_SemSeg(clip, params);
    end
end

function f_clean = features_arms(f, clip, params)
show = 0;
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
mask = imread(fullfile(params.paths.segmentation_path, clip.subject_name, masks{clip.startFrame+round(f.info(i,1)-params.features.L/2)}));
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
    right_arm_mask = mask==5;
%     afterMedian = medfilt2(right_arm_mask, [5 5]);
    CC = bwconncomp(right_arm_mask);
    numPixels = cellfun(@numel,CC.PixelIdxList);
    [biggest,idx] = max(numPixels);
    right_arm_mask_clean = uint8(right_arm_mask);
    right_arm_mask_clean(CC.PixelIdxList{idx}) = 2;
    right_arm_mask_clean(right_arm_mask_clean~=2) = 0;
    right_arm_mask_clean(right_arm_mask_clean==2) = 1;

    bb = regionprops(right_arm_mask_clean>0,'BoundingBox');
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
        subplot(1,3,2); imshow(right_arm_mask,[]);
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
        
%         good = f.info(:,2)>bb(b).BoundingBox(1) & f.info(:,2)<bb(b).BoundingBox(1)+bb(b).BoundingBox(3) & ...
%             f.info(:,3)>bb(b).BoundingBox(2) & f.info(:,3)<bb(b).BoundingBox(2)+bb(b).BoundingBox(4);
%         rej = f.info(:,3)<bb(b).BoundingBox(1) | f.info(:,3)>bb(b).BoundingBox(1)+bb(b).BoundingBox(2) | ...
%                     f.info(:,2)<bb(b).BoundingBox(3) | f.info(:,2)>bb(b).BoundingBox(3)+bb(b).BoundingBox(4);
end

f_clean = f;
d = params.features.descriptors;
f_clean.info(rejected, :) = [];
for id = 1:length(d)
    f_clean.(d{id})(rejected, :) = [];
end
fprintf('\n%d/%d trajectories were rejected from clip %s\n.', length(rejected), length(f.info) ,clip.name);

% keyboard



end

