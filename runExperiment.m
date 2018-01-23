function [] = runExperiment(configFile)
    params = config_parser(configFile);
    switch params.dbName
        case 'KTH'
            KTH_experiment(params)
        case 'UCFSports'
            UCFSports_experiment(params)
		case 'Hollywood2'
            Hollywood2_experiment(params)
        case 'HMDB51'
            HMDB_experiment(params)
        case 'UCF101'
            UCF101_experiment(params)            
		case 'MOBOT6a'
            MOBOT6a_experiment(params)
		case 'MOBOT6aGoPro'
            MOBOT6aGoPro_experiment(params)
		case 'MOBOT6a_ROS'
            MOBOT6aROS_experiment(params)
		case 'cvsp'
            cvsp_experiment(params)            
        case 'thumos14'
            params_train = config_parser(params.paths.ucf101_config);
            params_test = params;
            thumos14_experiment(params_train,params_test)
        otherwise
            error('Unrecognized database: %s', params.dbName)
    end
	diary off;
end

function [] =  KTH_experiment(params)
    db_params = configKTH(params.paths);
    KTH_training(params, db_params);
    KTH_testing(params, db_params);
end

function [] =  UCFSports_experiment(params)
    db_params = configUCFSports(params.paths);
    UCFSports_training(params, db_params);
    UCFSports_testing(params, db_params);
end

function [] =  HMDB_experiment(params)
    db_params = configHMDB51(params.paths);
    HMDB51_training(params, db_params);
    HMDB51_testing(params, db_params);
end

function [] =  UCF101_experiment(params)
    db_params = configUCF101(params.paths);
    HMDB51_training(params, db_params);
    HMDB51_testing(params, db_params);
end

function [] = Hollywood2_experiment(params)
    db_params = configHollywood2(params.paths);
    Hollywood2_training(params, db_params);
    Hollywood2_testing(params, db_params);
end

function [] =  MOBOT6a_experiment(params)
    db_params = configMOBOT6a(params.paths);
    MOBOT6a_training(params, db_params);
    MOBOT6a_testing(params, db_params);
end

function [] =  MOBOT6aGoPro_experiment(params)
    db_params = configMOBOT6aGoPro(params.paths);
    MOBOT6a_training(params, db_params);
    MOBOT6a_testing(params, db_params);
end

function [] =  MOBOT6aROS_experiment(params)
    db_params = configMOBOT6a(params.paths);
    MOBOT6a_training(params, db_params);
    MOBOT6a_testing(params, db_params);
end

function [] =  cvsp_experiment(params)
    db_params = configCVSP(params.dbconfig);
    cvsp_training(params, db_params);
    cvsp_testing(params, db_params);
end

function [] =  thumos14_experiment(params_train,params_test)
    train_db_params = configUCF101(params_train.paths);
    HMDB51_training(params_train, train_db_params);
    test_db_params = configThumos14(params_test.paths);
    thumos14_testing(params_train,params_test, test_db_params, train_db_params);
end
