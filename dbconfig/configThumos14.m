function db_params =  configThumos14(paths)

actions_cell=textscan(fopen(paths.class_list,'r'),'%d %s');
actions = actions_cell{2};
actionsInd = actions_cell{1};

% read list of videos with audio
[video_names,start_times,end_times,clip_names,class_names] = textread(paths.clip_list,'%s %f %f %s %s\n'); 


clips = struct('name','','startTime', -1, 'endTime', -1, 'class', -1, 'class_label', '');

for v=1:length(clip_names)
    clips(v).class_label = class_names{v};
    clips(v).class = actionsInd(strcmp(actions,class_names{v}));
    clips(v).startTime = start_times(v);
    clips(v).endTime = end_times(v);
    clips(v).name = clip_names{v};
    
end

% [~, videos] = cellfun(@fileparts, {clips.file}', 'UniformOutput', false);


split = struct('testing',[],'testing_annotation',[]);
split.testing = 1:length(clip_names);
split.testing_annotation = [clips(split(1).testing).class]';    

db_params.clips = clips;
db_params.split = split;
db_params.num.videos = length(clip_names);
db_params.num.classes = length(actions);
db_params.annotation = [db_params.clips.class]';
db_params.num.splits = 1;

end
