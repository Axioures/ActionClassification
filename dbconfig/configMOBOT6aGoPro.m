function db_params = configMOBOT6aGoPro(paths)
	%% MOBOT6.a database configuration
	subjects = [1 4 7 8 9 11 12 13];
	testing_subjects = [1 4 7 8 9 11 12 13];
	training_subjects = [1 4 7 8 9 11 12 13];
	actions = {'Help','WantStandUp','PerformTask','WantSitDown','ComeCloser','ComeHere', 'LetsGo', 'Park'};
%     actions = {'Help','WantStandUp', 'WantSitDown'};
	videoPaths_file = '/home/nick/Dropbox/Gesture/data/MOBOT6a_GoPro_mobotPC.txt';
    annotations_file = '/home/nick/Dropbox/Gesture/data/MOBOT6aGoPro_annotations.txt';
    fps = 25;
	DEBUG = 0;
	
	temp = textscan(fopen(videoPaths_file), '%d %s %d %f');
	videos.subject = temp{1};
	videos.file = temp{2};
    time_offsets = temp{4};
	num.classes = length(actions);
	num.subjects = length(unique(videos.subject));
	num.videos = length(videos.file);
	subjectNames = textscan(sprintf('p%d\n', subjects), '%s');
	subjectNames = subjectNames{1};
    temp = textscan(fopen(annotations_file), '%d %s');
    annotations.subjects = temp{1};
    annotations.files = temp{2};

	% collect all action instances
	db_contents = struct('subject', -1, 'subject_name', '', 'file', '', 'startFrame', -1, 'endFrame', -1, 'class', -1, 'class_label', '', 'iteration', -1);
	i = 0;
	for iVideo=1:num.videos
		if ~ismember(videos.subject(iVideo), subjects)
			continue;
		end
		videoFile = videos.file{iVideo};
		videoSubject = subjectNames{videos.subject(iVideo)==subjects};
		fid = fopen(annotations.files{annotations.subjects==videos.subject(iVideo)});
		annotation = textscan(fid, '%f %f %s');
        startFrames = round((annotation{1} + time_offsets(iVideo))*fps);
        endFrames = round((annotation{2} + time_offsets(iVideo))*fps);
        startTimes = annotation{1} + time_offsets(iVideo);
        endTimes = annotation{2} + time_offsets(iVideo);
        labels = annotation{3};
		iterCounter = zeros(length(actions),1);
		for iSegment=1:length(annotation{3})
			iAction = find(strcmp(actions, annotation{3}{iSegment}));
            if isempty(iAction)
                continue;
            end
			iterCounter(iAction) = iterCounter(iAction) + 1 ;
			i = i + 1;
			db_contents(i).subject = videos.subject(iVideo);
			db_contents(i).subject_name = videoSubject;
			db_contents(i).file = videoFile;
			db_contents(i).startFrame = startFrames(iSegment);
			db_contents(i).endFrame = endFrames(iSegment);
            db_contents(i).startTime = startTimes(iSegment);
            db_contents(i).endTime = endTimes(iSegment);
			db_contents(i).class_label = labels{iSegment};
			db_contents(i).iteration = iterCounter(iAction);
			db_contents(i).class = iAction;
			db_contents(i).codename = sprintf('%s_%s_%d', db_contents(i).subject_name,...
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