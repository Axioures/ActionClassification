function db_params =  configHollywood2(paths)

DEBUG = 0;
actions = {'AnswerPhone', 'DriveCar', 'Eat', 'FightPerson', 'GetOutCar',...
    'HandShake', 'HugPerson', 'Kiss', 'Run', 'SitDown', 'SitUp', 'StandUp'};


training_clips = textscan(fopen(fullfile(paths.db_data, 'actions_train.txt')), '%s %d');
testing_clips = textscan(fopen(fullfile(paths.db_data, 'actions_test.txt')), '%s %d');
training_clips = training_clips{1};
testing_clips = testing_clips{1};
num.trainClips = length(training_clips);
num.testClips = length(testing_clips);
num.classes = length(actions);
if DEBUG
    num.trainClips = ceil(num.trainClips/17);
    num.testClips = ceil(num.testClips/17);
end
num.clips = num.trainClips + num.testClips;
clips(1:num.clips) = ...
    struct('file', '', 'startFrame', -1, 'endFrame', -1, 'label', '', 'iteration', -1, 'nlabels', -1, 'codename', '');
trainInd = 1:num.trainClips;
testInd = (num.trainClips+1):num.clips;

annotTrain = zeros(num.trainClips, length(actions));
annotTest = zeros(num.testClips, length(actions));

for iAction = 1:length(actions)
    fid = fopen(fullfile(paths.db_data, sprintf('%s_train.txt', actions{iAction})));
    annot = textscan(fid, '%s %d');
    if ~DEBUG
        annotTrain(:, iAction) = annot{2};
    else
        annotTrain(:, iAction) = annot{2}(1:num.trainClips);
    end

    fid = fopen(fullfile(paths.db_data, sprintf('%s_test.txt', actions{iAction})));
    annot = textscan(fid, '%s %d');
    if ~DEBUG
        annotTest(:, iAction) = annot{2};
    else
        annotTest(:, iAction) = annot{2}(1:num.testClips);
    end
    
end

classCounter = zeros(length(actions), 1);
for iClip=1:num.trainClips
    clips(iClip).file = fullfile(paths.db, sprintf('%s.avi',training_clips{iClip}));
    classes = find(annotTrain(iClip,:)==1);
    clips(iClip).label = actions(classes);
    clips(iClip).class = classes;
    clips(iClip).iteration = iClip;
    clips(iClip).nlabels = length(classes);
    classCounter(classes) = classCounter(classes) + 1;
    for i=1:length(classes)
        clips(iClip).codename =...
            sprintf('%s_%s_%d',clips(iClip).codename,...
            clips(iClip).label{i}, classCounter(classes(i)));
    end
%     clips(iClip).codename = clips(iClip).codename(2:end);
    [~, name] = fileparts(clips(iClip).file);
    clips(iClip).name = name;
end

% classCounter = zeros(length(actions), 1);
for iClip=num.trainClips+(1:num.testClips)
    clips(iClip).file = fullfile(paths.db, sprintf('%s.avi',testing_clips{iClip-num.trainClips}));
    classes = find(annotTest(iClip-num.trainClips,:)==1);
    clips(iClip).label = actions(classes);
    clips(iClip).class = classes;
    clips(iClip).iteration = iClip;
    clips(iClip).nlabels = length(classes);
    classCounter(classes) = classCounter(classes) + 1;
    for i=1:length(classes)
        clips(iClip).codename =...
            sprintf('%s_%s_%d',clips(iClip).codename,...
            clips(iClip).label{i}, classCounter(i));
    end
%     clips(iClip).codename = clips(iClip).codename(2:end);
    [~, name] = fileparts(clips(iClip).file);
    clips(iClip).name = name;
end


db_params.clips = clips;
db_params.num = num;
db_params.training = trainInd;
db_params.testing = testInd;
db_params.annotation = {db_params.clips.class}';
db_params.annotation_training = db_params.annotation(db_params.training);
db_params.annotation_testing = db_params.annotation(db_params.testing);
db_params.classes = 1:num.classes;
db_params.labels = actions;

end

