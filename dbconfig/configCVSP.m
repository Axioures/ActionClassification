function db_params = configCVSP(config_file)
	%% database configuration
%     config_file = '/home/nick/SVNfolder/action_nick/rtg/training/configs/db_cvsp_mobotpc.yaml';
    params = ReadYaml(config_file);
    
    subjectNames = params.subjects;
    subjects = 1:length(subjectNames);
% 	testing_subjects = subjects;
% 	training_subjects = subjects;
	actions = params.vocabulary;
	videoPaths_file = params.files_list;
	
	temp = textscan(fopen(videoPaths_file), '%s %s %s');
	videos.subjectName = temp{1};
	videos.file = temp{2};
    videos.annot_file = temp{3};
	num.classes = length(actions);
	num.subjects = length(unique(videos.subjectName));
	num.videos = length(videos.file);

	% collect all action instances
	db_contents = struct('subject', -1, 'subject_name', '', 'file', '', 'startFrame', -1, 'endFrame', -1, 'class_label', '', 'iteration', -1);
	i = 0;
    iterCounter = zeros(num.subjects, length(actions));
    for iVideo=1:num.videos
		if ~ismember(videos.subjectName{iVideo}, subjectNames)
			continue;
		end
% 		videoFile = fullfile(paths.db, videos.file{iVideo});
		videoSubject = subjects(strcmp(videos.subjectName{iVideo}, subjectNames));
		fid = fopen(fullfile(videos.annot_file{iVideo}));
		annotation = textscan(fid, '%f %f %s');
% 		iterCounter = zeros(length(actions),1);
        for iSegment=1:length(annotation{3})
			iAction = find(strcmp(actions, annotation{3}{iSegment}));
            if isempty(iAction)
                continue;
            end
			iterCounter(videoSubject, iAction) = iterCounter(videoSubject, iAction) + 1 ;
			i = i + 1;
			db_contents(i).subject = videoSubject;
			db_contents(i).subject_name = subjectNames{videoSubject};
% 			db_contents(i).file = videoFile;
			db_contents(i).startFrame = annotation{1}(iSegment);
			db_contents(i).endFrame = annotation{2}(iSegment);
			db_contents(i).class_label = annotation{3}{iSegment};
			db_contents(i).iteration = iterCounter(videoSubject, iAction);
			db_contents(i).class = iAction;
			db_contents(i).name = sprintf('%s_%s_%d', db_contents(i).subject_name,...
				db_contents(i).class_label, db_contents(i).iteration);
        end
    end
    
    splits(1:length(subjects)) = struct('training', -1, 'testing', -1, 'test_subject', '-1');
    for i=1:num.subjects
        splits(i).testing = find([db_contents.subject] == subjects(i));
        splits(i).training = find([db_contents.subject] ~= subjects(i));
        splits(i).test_subject = subjects(i);
    end
	db_params.clips = db_contents;
	db_params.num = num;
	db_params.annotation = [db_params.clips.class]';
	db_params.classes = 1:num.classes;
	db_params.class_labels = actions;
	db_params.subjects = subjects;
	db_params.subject_names = subjectNames;
    db_params.splits = splits;
% 	db_params.testing_subjects = testing_subjects;
% 	db_params.training_subjects = training_subjects;

end
