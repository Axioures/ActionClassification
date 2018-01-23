function db_params =  configHMDB51(paths)
	%% HMDB51 Sports Parameters
	reduced = false;
	DEBUG = 0;
	% dirs = dir(paths.db);
	% dirs = sort(extractfield(dirs([dirs.isdir]),  'name'));
	% actions  = dirs((~strcmp(dirs, '.'))&(~strcmp(dirs, '..')))';
	actions = {'brush_hair','cartwheel','catch','chew','clap','climb','climb_stairs',...
			'dive','draw_sword','dribble','drink','eat','fall_floor','fencing',...
			'flic_flac','golf','handstand','hit','hug','jump','kick_ball',...
			'kick','kiss','laugh','pick','pour','pullup','punch',...
			'push','pushup','ride_bike','ride_horse','run','shake_hands','shoot_ball',...
			'shoot_bow','shoot_gun','sit','situp','smile','smoke','somersault',...
			'stand','swing_baseball','sword_exercise','sword','talk','throw','turn',...
			'walk','wave'};
	% splitsDir = fullfile(paths.db_data, 'HMDB51_splits');
	splitsDir = paths.db_data;
	if reduced
		action_indicies = [1,3,5,7,...
				16,20,21,...
				25,26,27,...
				29,33,35,...
				36,37,38,39,...
				43,44,48,...
				50,51];
		nVideos = 3143;
	else
		action_indicies = 1:length(actions);
		nVideos = 6766;
	end

	db_contents = struct('file', '', 'startFrame', -1, 'endFrame', -1, 'label', '', 'iteration', -1);
	trainingSamples = false(nVideos,3);
	testingSamples = false(nVideos,3);
	split = cell(1,3);
	i = 0;

	fprintf('\n');
	for a = action_indicies
		videos = extractfield(dir(fullfile(paths.db, actions{a}, '*.avi')), 'name')';
		if DEBUG
			videos = videos(1:ceil(length(videos)/15));
		end
		videos2bash = correctSpecials(videos); % correct special caracters in filenames
		for iSplit=1:3
			fid= fopen(fullfile(splitsDir, sprintf('%s_test_split%d.txt', actions{a}, iSplit)), 'r');
			split{iSplit} = textscan(fid, '%s %d');
			fclose(fid);
		end
		
		for iIter=1:length(videos)
			i = i + 1;
			msgSize = fprintf('Processing video %d/%d\n', i, nVideos);
			db_contents(i).file = fullfile(fullfile(paths.db, actions{a}, videos{iIter}));
			db_contents(i).class_label = actions{a};
			db_contents(i).class = a;
			db_contents(i).iteration = iIter;
			db_contents(i).startFrame = -1;
			db_contents(i).endFrame = -1;
	%         nFrames = extractfield(mmread(db_contents(i).file, [], [], false, true), 'nrFramesTotal');
	%         db_contents(i).endFrame = nFrames;
			
			ind = find(strcmp(videos{iIter}, split{1}{1}));
			for iSplit=1:3
				trainingSamples(i, iSplit) = split{iSplit}{2}(ind)==1;
				testingSamples(i, iSplit) = split{iSplit}{2}(ind)==2;
			end
			db_contents(i).file = fullfile(fullfile(paths.db, actions{a}, videos2bash{iIter}));
			db_contents(i).file_orig = fullfile(fullfile(paths.db, actions{a}, videos{iIter}));
            [~, name] = fileparts(db_contents(i).file_orig);
            db_contents(i).name = name;
% 			db_contents(i).codename = sprintf('%s_%d', db_contents(i).class_label, db_contents(i).iteration);
			
			% just in case...
			if ind~=iIter
				disp(ind)
			end
			if ~strcmp(split{iSplit}{1}(iIter), videos{iIter})
				disp(i)
			end
			erase_msg(msgSize, 0);
		end
	end
	erase_msg(0, 1);
	
	if (i~=nVideos)
	   if DEBUG
		   nVideos = i;
	   else
		   error('Database error.');
	   end
	end
	db_params.clips = db_contents;
	db_params.num.videos = nVideos;
	db_params.num.classes = length(actions);
	db_params.annotation = [db_params.clips.class]';
	db_params.num.splits = 3;
	for i=1:db_params.num.splits
		db_params.split(i).training = find(trainingSamples(:,i));
		db_params.split(i).training_annotation = db_params.annotation(db_params.split(i).training);
		db_params.split(i).testing = find(testingSamples(:,i));
		db_params.split(i).testing_annotation = db_params.annotation(db_params.split(i).testing);
	end
	db_params.classes = action_indicies;
	db_params.labels = actions;

	fprintf('\n');
end


