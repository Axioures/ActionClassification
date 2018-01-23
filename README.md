# Action Classification

This is the root path of the action classification code.
The whole system has the following package dependences:
- Dense trajectories: https://lear.inrialpes.fr/people/wang/dense_trajectories
- yael: https://gforge.inria.fr/projects/yael/
- vlfeat: www.vlfeat.org/

Running an experiment is as simple as excecuting the following command under MATLAB:
>> runExperiment(config_file.yaml)

where config_file.yaml is a string contaning the experiment's configuration file filename (full path would be nice). The configuration file conforms to the yaml fomat.
The above libraries' path, as well are the rest of parameters are defined in the configuration file.
You can find sample configuration files for MOBOT-PC and mavra in the "configs" folder.
For example, you can run:
>> runExperiment('/home/vagelis/ActionClassification/configs/configMain_DT_HMDB_mobotpc.yaml')

Thus running the experiment is all about writing the configuration file.
There is a template file (configs/configMain_TEMPLATE_DT_KTH_mobotpc.yaml) where all the parameters involved are explained.
