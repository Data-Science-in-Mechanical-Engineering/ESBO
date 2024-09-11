# Early Stopping Bayesian Optimization for Controller Tuning
This repository contains the Matlab code for the paper "Early Stopping Bayesian Optimization for Controller Tuning (2024)" accepted at the [63st IEEE Conference on Decision and Control](https://cdc2024.ieeecss.org/).

![methods_figure](https://github.com/Data-Science-in-Mechanical-Engineering/ESBO/blob/main/figures/MethodsFigure.PNG)

We propose to stop episodes in Bayesian Optimization for controller tuning early to save overall experimentation time. To achieve this, we formulate the problem in terms of time-integrated cost functions and formulate a simple stopping criterion. Episodes that are stopped early result in incomplete cost observations. To facilitate the partially evaluated episodes in the BO framework, we propose three heuristics. All heuristics include virtual observation in the GP model to steer optimization away from unpromising regions. The methods are evaluated in simulation on five controller tuning tasks and one hardware experiment.

If you find our code or paper useful, please consider citing
```
@inproceedings{stenger2024early,
  title={Early Stopping Bayesian Optimization for Controller Tuning},
  author={Stenger, David and Scheurenberg, Dominik and Vallery, Heike and Trimpe, Sebastian},
  booktitle={2024 IEEE 63st Conference on Decision and Control (CDC)},
  year={2024},
  organization={IEEE}
}
```


## Implementation and Results

The implementation has been tested with Matlab/Simulink version 2022b. The GP Model is implemented based on the [GPML](http://gaussianprocess.org/gpml/code/matlab/doc/) (FreeBSD License) and we use the [max-value entropy search](https://github.com/zi-w/Max-value-Entropy-Search) (MIT License) acquisition function. 

To reproduce the figures of the paper, please run `FiguresPaper.m`. To rerun the simulation experiments run `main.m`. This will take several hours. The calculation of the virtual data points is performed in the file `src/bayesian_optimization/src/genESVirtDat.m`. It is called in line 136 of the main BO script `src/bayesian_optimization/EGO.m`. If you have any questions regarding paper or code please do not hesitate to contact us at david.stenger@dsme.rwth-aachen.de.     


