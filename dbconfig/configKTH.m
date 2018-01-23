function db_params =  configKTH(paths)
%% KTH database configuration

subjects = 1:25;
subjectNames = strrep(strcat('p',cellstr(num2str(subjects(:)))), '\s', '');
trainSubjects = sort([11, 12, 13, 14, 15, 16, 17, 18, ...
    19, 20, 21, 23, 24, 25, 01, 04])';
testSubjects = sort([22, 02, 03, 05, 06, 07, 08, 09, 10])';
actions = {'walking','jogging','running','boxing','handwaving','handclapping'};

temp = textscan(fopen(fullfile(paths.db_data, 'KTH.txt')), '%s', 'CollectOutput', true);
[videos.subject, ~]=regexp(temp{1}, 'person(\d+)', 'tokens', 'match');
videos.subject = [videos.subject{:}]';
videos.subject = str2double([videos.subject{:}])';
videos.file = temp{1};
num.subjects = length(unique(videos.subject));
num.videos = length(videos.file);
num.classes = length(actions);

% collect all action instances
fid = fopen(fullfile(paths.db_data, 'KTH_sequences.txt'));
iterCounter = zeros(length(subjects), length(actions));
iInstance = 0;
while true
    line = fgetl(fid);
    if line == -1
        break
    elseif strcmp(line, '\n')||isempty(line)
        continue
    end
    videoFile = textscan(line, '%s\t%s');
    videoFile = [videoFile{1}{1} '_uncomp.avi'];
    [tokens, ~]=regexp(line, '(\d*)', 'tokens', 'match');
    tokens = str2double([tokens{:}]);
    %tokens(1) = person, tokens(2) = setup, tokens(3:end) = frames
    subject = tokens(1);
    if ~ismember(subject, subjects)
        continue;
    end
    subjectName = sprintf('p%d', subject);
    setting = tokens(2);
    frames = tokens(3:end);
    token=regexp(line, '_(?<action>\w+)_d', 'names');
    label = token.action;
    for iSegment = 1:length(frames)/2
        iInstance = iInstance + 1;
        iAction = find(strcmp(label, actions));
        iterCounter(subject, iAction) = iterCounter(subject, iAction) +1;
%             db_contents(iInstance).file = fullfile(Mainfile_INPUT,...
%                 sprintf('person%02d_%s_d%d_uncomp.avi', subject, label, setting));
        db_contents(iInstance).file = fullfile(paths.db, videoFile);
        db_contents(iInstance).subject = subjectName;
        db_contents(iInstance).class_label = label;
        db_contents(iInstance).class = iAction;
        db_contents(iInstance).iteration = iterCounter(subject, iAction);
        db_contents(iInstance).startFrame = frames(2*(iSegment-1)+1);
        db_contents(iInstance).endFrame = frames(2*iSegment);
        db_contents(iInstance).class = iAction;
        db_contents(iInstance).setting = setting;
        db_contents(iInstance).train = ismember(subject,trainSubjects);
        [~, name] = fileparts(db_contents(iInstance).file);
        db_contents(iInstance).name = sprintf('%s_%d', name, db_contents(iInstance).iteration);
%         db_contents(iInstance).codename = sprintf('%s_%s_%d', db_contents(iInstance).subject,...
%             db_contents(iInstance).class_label, db_contents(iInstance).iteration);
    end  
end

trainInd = [db_contents.train]';
testInd = ~trainInd;
db_contents = rmfield(db_contents, 'train');

db_params.clips = db_contents;
db_params.num = num;
db_params.training = find(trainInd);
db_params.testing = find(testInd);
db_params.annotation = [db_params.clips.class]';
db_params.annotation_training = db_params.annotation(db_params.training);
db_params.annotation_testing = db_params.annotation(db_params.testing);
db_params.classes = 1:num.classes;
db_params.labels = actions;

% if DEBUG
%     trainSubjects = trainSubjects(1:ceil(length(trainSubjects)/10));
%     testSubjects = testSubjects(1:ceil(length(trainSubjects)/10));
%     subjects = sort([trainSubjects; testSubjects]);
%     subjectNames = strrep(strcat('p',cellstr(num2str(subjects(:)))), '\s', '');
%     ind = false(length(db_contents), length(subjectNames));
%     for i=1:length(subjectNames)
%         ind(:,i) = strcmp({db_contents.subject}, subjectNames{i});
%     end
%     ind = any(ind, 2);
%     db_contents = db_contents(ind);
% end
