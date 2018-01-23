function db_params = configMOBOT6a(paths)
	%% MOBOT6.a database configuration
	subjects = [1 4 7 10 12 13 16 18];
	testing_subjects = [1 4 7 10 12 13 16 18];
	training_subjects = [1 4 7 10 12 13 16 18];
	actions = {'Help','WantStandUp','PerformTask','WantSitDown','ComeCloser','ComeHere', 'GoStraight', 'Park'};
% 	videoPaths_file = '/home/nick/Dropbox/Gesture/data/MOBOT6.a_mobotPC.txt';
	videoPaths_file = '/home/nick/SVNfolder/action_nick/data/MOBOT6.a_frames.txt';
	%videoPaths_file = '/home/nick/action_nick/data/MOBOT6a_mavra.txt';
	DEBUG = 0;
	
	temp = textscan(fopen(videoPaths_file), '%d %s');
	videos.subject = temp{1};
	videos.file = temp{2};
	num.classes = length(actions);
	num.subjects = length(unique(videos.subject));
	num.videos = length(videos.file);
	subjectNames = textscan(sprintf('p%d\n', subjects), '%s');
	subjectNames = subjectNames{1};

	% collect all action instances
	db_contents = struct('subject', -1, 'subject_name', '', 'file', '', 'startFrame', -1, 'endFrame', -1, 'label', -1, 'class_label', '', 'iteration', -1);
	i = 0;
	for iVideo=1:num.videos
		if ~ismember(videos.subject(iVideo), subjects)
			continue;
		end
		videoFile = fullfile(paths.db, videos.file{iVideo});
		videoSubject = subjectNames{videos.subject(iVideo)==subjects};
		fid = fopen((fullfile(paths.db_data, sprintf('Sample%05d_annot.txt', videos.subject(iVideo)))));
		annotation = textscan(fid, '%d %d %s');
		iterCounter = zeros(length(actions),1);
		for iSegment=1:length(annotation{3})
			iAction = find(strcmp(actions, annotation{3}{iSegment}));
			iterCounter(iAction) = iterCounter(iAction) + 1 ;
			i = i + 1;
			db_contents(i).subject = videos.subject(iVideo);
			db_contents(i).subject_name = videoSubject;
			db_contents(i).file = videoFile;
			db_contents(i).startFrame = annotation{1}(iSegment);
			db_contents(i).endFrame = annotation{2}(iSegment);
			db_contents(i).class_label = annotation{3}{iSegment};
			db_contents(i).iteration = iterCounter(iAction);
			db_contents(i).class = iAction;
			db_contents(i).name = sprintf('%s_%s_%d', db_contents(i).subject_name,...
				db_contents(i).class_label, db_contents(i).iteration);
		end
	end

	if DEBUG
		db_contents = db_contents(strcmp({db_contents.subject}, subjectNames{1})|...
			strcmp({db_contents.subject}, subjectNames{2}));
		subjects = subjects(1:2);
	end
	
	db_params.clips = db_contents;
	db_params.num = num;
	db_params.annotation = [db_params.clips.class]';
	db_params.classes = 1:num.classes;
	db_params.class_labels = actions;
	db_params.subjects = subjects;
	db_params.subject_names = subjectNames;
	db_params.testing_subjects = testing_subjects;
	db_params.training_subjects = training_subjects;	

end
