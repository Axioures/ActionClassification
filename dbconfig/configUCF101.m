function db_params =  configUCF101(paths)

actions_cell=textscan(fopen(fullfile(paths.db,'UCF101TrainTestSplits-RecognitionTask/ucfTrainTestlist/classInd.txt'),'r'),'%d %s');
actions = actions_cell{2};
actionsInd = actions_cell{1};
splitsDir = fullfile(paths.db,'UCF101TrainTestSplits-RecognitionTask','ucfTrainTestlist');
splitScenarios = [1,2,3];
% videos_cell1 = textscan(fopen(fullfile(splitsDir,'trainlist01.txt')), '%s %d');
% videos_cell2 = textscan(fopen(fullfile(splitsDir,'testlist01.txt')), '%s %d');
% videos = [videos_cell1{1} ; videos_cell2{1}];

clips = struct('file', '', 'startFrame', -1, 'endFrame', -1, 'class', -1, 'class_label', '');

vcnt = 0;
for c=1:length(actions)
    class_dir = fullfile(paths.db, 'UCF-101', actions{c});
    class_videos = dir(class_dir);
    class_videos = {class_videos(~[class_videos(:).isdir]).name}';
    for v=1:length(class_videos)
        vcnt = vcnt + 1;
%         msgSize = fprintf('Processing video %d\n', vcnt);
        clips(vcnt).file = fullfile(class_dir, class_videos{v});
        clips(vcnt).class_label = actions{c};
        clips(vcnt).class = actionsInd(c);
        clips(vcnt).iteration = v;
        clips(vcnt).startFrame = -1;
        clips(vcnt).endFrame = -1;
        [~, codename] = fileparts(clips(vcnt).file);
        clips(vcnt).name = codename;
    end
end
num.videos = vcnt;
[~, videos] = cellfun(@fileparts, {clips.file}', 'UniformOutput', false);
split(1:length(splitScenarios)) = struct('training',[],'testing',[],'training_annotation',[],'testing_annotation',[]);
for s=splitScenarios
    train_list = textscan(fopen(fullfile(splitsDir, sprintf('trainlist%02d.txt', s))), '%s %d');
    test_list = textscan(fopen(fullfile(splitsDir, sprintf('testlist%02d.txt', s))), '%s %d');
    [~,train_list] = cellfun(@fileparts, train_list{1}, 'UniformOutput', false);
    [~,test_list] = cellfun(@fileparts, test_list{1}, 'UniformOutput', false);
    train_ind = ismember(videos, train_list);
    test_ind = ismember(videos, test_list);
    split(s).training = find(train_ind);
    split(s).training_annotation = [clips(split(s).training).class]';
    split(s).testing = find(test_ind);
    split(s).testing_annotation = [clips(split(s).testing).class]';
    
end

db_params.clips = clips;
db_params.split = split;
db_params.num.videos = num.videos;
db_params.num.classes = length(actions);
db_params.annotation = [db_params.clips.class]';
db_params.num.splits = length(splitScenarios);

end
