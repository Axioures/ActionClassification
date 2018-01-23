function db_params =  configUCFSports(paths)
%% UCF Sports Parameters
% clear;
% Mainfile_INPUT = '/home/homer/Videos/UCFSports/';
% paths.data = '/home/homer/Dropbox/Gesture/data';
% paths.code = pwd;
% addpath(fullfile(paths.code,'SupportPackages','mmread'));
actionDirs = textscan(fopen(fullfile(paths.db_data, 'UCFSports.txt')), '%s %s');
actions = unique(actionDirs{1});
actionCounter = zeros(length(actions), 1);
for iAction=1:length(actions)
    actionCounter(iAction) = sum(strcmp(actionDirs{1}, actions{iAction}));
end

trainSamples = [5 6 7 8 9 10 11 12 13 14 21 22 23 24 25 26 27 28 29 30 31 32 39 40 41 42 43 44 45 46 47 48 ...
    49 50 51 52 55 56 57 58 63 64 65 66 67 68 69 70 75 76 77 78 79 80 81 82 83 88 89 90 91 92 93 94 95 102 103 ...
    104 105 106 107 108 109 110 111 112 113 114 115 120 121 122 123 124 125 126 127 128 136 137 138 139 140 141 ...
    142 143 144 145 146 147 148 149 150];
testSamples = [1 2 3 4 15 16 17 18 19 20 33 34 35 36 37 38 53 54 59 60 61 62 71 72 73 74 84 85 86 87 96 97 98 ...
    99 100 101 116 117 118 119 129 130 131 132 133 134 135];
num.videos = length(actionDirs{2});
num.classes = length(actions);

clips = struct('file', '', 'startFrame', -1, 'endFrame', -1, 'label', '', 'iteration', -1, 'subject', '');
iterCounter = zeros(length(actions), 1);
for v = 1:num.videos
    action = find(strcmp(actions, actionDirs{1}{v}));
    iterCounter(action) = iterCounter(action) + 1;
    fileNames = sort(extractfield(dir(fullfile(paths.db, actionDirs{2}{v})), 'name'))';
    aviFile = find(~cellfun(@isempty,regexp(fileNames, '(.avi)')'));
    jpgFiles = find(~cellfun(@isempty,regexp(fileNames, '(.jpg)')'));
    fprintf('Action %s, iteration %d (#%d), avi: %d, jpg: %d\n', actionDirs{1}{v},...
        iterCounter(action), v, ~isempty(aviFile), ~isempty(jpgFiles));
    
    if ~isempty(jpgFiles)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%  WARNING: RENAMING DATABASE FILENAMES  %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for iFile = 1:length(jpgFiles)
            before = fullfile(paths.db, actionDirs{2}{v}, fileNames{jpgFiles(iFile)});
            after = fullfile(paths.db, actionDirs{2}{v}, sprintf('frame%03d.jpg', iFile-1));
            if ~strcmp(before, after)
                movefile(before, after);
            end
        end
        
        clips(v).file = fullfile(paths.db, actionDirs{2}{v}, sprintf('frame%%03d.jpg'));
    else
        clips(v).file = fullfile(paths.db, actionDirs{2}{v}, fileNames{aviFile});
        clips(v).file = correctSpecials(clips(v).file);
	clips(v).file = strrep(clips(v).file, './', '');
    end

    clips(v).startFrame = -1;
    clips(v).endFrame = -1;
    clips(v).class = action;
    clips(v).label = actions{clips(v).class};
    clips(v).iteration = iterCounter(action);
    clips(v).name = sprintf('%s_%d', clips(v).label, clips(v).iteration);
end

db_params.num = num;
db_params.clips = clips;
db_params.training = trainSamples;
db_params.testing = testSamples;
db_params.classes = 1:num.classes;
db_params.actions = actions;
db_params.annotation = [db_params.clips.class]';
db_params.annotation_training = db_params.annotation(db_params.training);
db_params.annotation_testing = db_params.annotation(db_params.testing);


end
