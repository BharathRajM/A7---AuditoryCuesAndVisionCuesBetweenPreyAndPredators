# Comparison between only visual transmission and both auditory and visual transmission in groups under predation
This repository contains a NetLogo model simulating groups of prey under predation.

This model was built on an existing model on frontal vision and flocking behaviour that was created for a previous course. That base model is contained in `Base Model/MahadevaRaoFelthamModelMsc2020.nlogo`. The final model we created is contained in `Final Model/DMAS_Submission.nlogo`.

## Running the model
The model can be run in [NetLogo](https://ccl.northwestern.edu/netlogo/). It was built in NetLogo 6.1.1 - other versions may work, but are not recommended for running this model. To run the model, simply download the model and load it in NetLogo.

You can initialize the model with the `Setup` button - this creates the initial conditions, spawning some prey and predators. You can then press `Go` to start running the model, or `Step` to step through it slowly. Surrounding the main screen in the middle are various options for changing the model parameters. The output can be read in the graphs to the right. Make sure you run the model by viewing the updates 'on ticks' 

## Analyzing the results
You can run experiments using NetLogo's built-in tool BehaviourSpace. If you clean the output such that the layout is similar to that of `Experiment Results/cleaned-data-final.csv`, you can run the included notebook `Experiment Results/analysis.ipynb`. This will allow you to easily inspect the data, and by default will print some results. It has also been exported to `Experiment Results/analysis.py` for people who do not have jupyter installed.
