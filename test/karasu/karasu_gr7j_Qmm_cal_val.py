from gr7jmodule import InputDataHandler, ModelGr7j
from numpy import sqrt, mean
from pathlib import Path

import plotly.graph_objects as go
import plotly.io as pio
import pandas as pd
import datetime
import spotpy
import json

import matplotlib.pyplot as plt
from spotpy.analyser import plot_parameter_trace
from spotpy.analyser import plot_posterior_parameter_histogram


""" LOAD CALIBRATION DATA 
    Datasets are available as Pandas dataframe pickle in the project repository.
"""
# Load Catchment Data
working_directory = Path('~/gr7jproject').expanduser().resolve()
data_path = next(working_directory.rglob('**/karasu.csv'), None)
if data_path:
    df = pd.read_csv(data_path)
    df['date'] = pd.to_datetime(df['date'], errors='coerce')
else:
    print("Input data not found")
df.columns = ['date', 'precipitation', 'temperature', 'evapotranspiration', 'flow_mm']
df.index = df['date']
print(df.head())


""" SPOTPY INTERFACE
To use Spotpy, we need to create an interface for our model.
In particular, this interface provides an objective function methods to evaluate the model results.
Here we use NSE (nashsutcliffe) between computed and observed flow.
"""
class SpotpySetup(object):
    """
    Interface to use the model with spotpy
    """

    def __init__(self, data):
        self.data = data
        self.model_inputs = InputDataHandler(ModelGr7j, self.data)
        self.params = [spotpy.parameter.Uniform('x1', 0.0, 2500.0),
                       spotpy.parameter.Uniform('x2', -5.0, 5.0),
                       spotpy.parameter.Uniform('x3', 0.0, 1000.0),
                       spotpy.parameter.Uniform('x4', 0.5, 10.0),
                       spotpy.parameter.Uniform('x5', -4.0, 4.0),
                       spotpy.parameter.Uniform('x6', 0.0, 20.0),
                       spotpy.parameter.Uniform('x7', 0.05, 0.95),
                       ]

    def parameters(self):
        return spotpy.parameter.generate(self.params)

    def simulation(self, vector):
        simulations = self._run(x1=vector[0], x2=vector[1], x3=vector[2], x4=vector[3], x5=vector[4], x6=vector[5], x7=vector[6])
        return simulations

    def evaluation(self):
        return self.data['flow_mm'].values

    def objectivefunction(self, evaluation, simulation):
        nse = spotpy.objectivefunctions.nashsutcliffe(evaluation, simulation)
        return nse
    
    def _run(self, x1, x2, x3, x4, x5, x6, x7):
        parameters = {"X1": x1, "X2": x2, "X3": x3, "X4": x4, "X5": x5, "X6": x6, "X7": x7}
        model = ModelGr7j(parameters)
        outputs = model.run(self.model_inputs.data)
        return outputs['flow'].values
    

""" CALIBRATION
To calibrate model select a sub-period from dataset
To find optimal model parameters, several optimisation algorithm can be tested available in spotpy.
"""
# Reduce the dataset to a sub period :
start_date = datetime.datetime(1988, 1, 1, 0, 0)
end_date = datetime.datetime(1992, 12, 31, 0, 0)
mask = (df['date'] >= start_date) & (df['date'] <= end_date)
calibration_data = df.loc[mask]

spotpy_setup = SpotpySetup(calibration_data)

sampler = spotpy.algorithms.dds(spotpy_setup, dbformat='ram', parallel='seq')

sampler.sample(3000)
results=sampler.getdata() 
best_parameters = spotpy.analyser.get_best_parameterset(results)
spotpy.analyser.plot_parameterInteraction(results)  
spotpy.analyser.plot_fast_sensitivity(results, number_of_sensitiv_pars=3)


""" VALIDATION
Finally, validate calibration on another time period
"""
parameters = list(best_parameters[0])
parameters = {"X1": parameters[0], "X2": parameters[1], "X3": parameters[2], "X4": parameters[3], "X5": parameters[4], "X6": parameters[5], "X7": parameters[6]}

# Export parameters to json file
dir_path = next(Path.cwd().rglob('outputs_karasu'), None)
if dir_path is not None:
    output_path = dir_path / 'gr7j_parameters_Qmm.json'
    with open (output_path, "w") as file:
        json.dump(parameters, file)

start_date = datetime.datetime(1983, 1, 1, 0, 0)
end_date = datetime.datetime(1987, 12, 31, 0, 0)
mask = (df['date'] >= start_date) & (df['date'] <= end_date)
validation_data = df.loc[mask]

model = ModelGr7j(parameters)
model.set_parameters(parameters)

# Set initial state :
initial_states = {
    "production_store": 0.3,
    "routing_store": 0.5,
    "exponential_store": 0.3,
    "uh1": None,
    "uh2": None
}
model.set_states(initial_states)

outputs = model.run(validation_data)
print("\n***VALIDATION***")
print(outputs.head())

# Remove the first year used to warm up the model :
filtered_input = validation_data[validation_data.index >= datetime.datetime(1984, 1, 1, 0, 0)]
filtered_output = outputs[outputs.index >= datetime.datetime(1984, 1, 1, 0, 0)]

nse = spotpy.objectivefunctions.nashsutcliffe(filtered_input['flow_mm'], filtered_output['flow'])
print(f"Used parameters for Validation: {parameters}")
print(f"gr7j_val_nse: {nse}")

# # Plot 1-year long hydrograph
# plot_input = validation_data[validation_data.index >= datetime.datetime(1986, 1, 1, 0, 0)]
# plot_output = outputs[outputs.index >= datetime.datetime(1986, 1, 1, 0, 0)]

# fig = go.Figure([
#     go.Scatter(x=plot_output.index, y=plot_output['flow'], name="Calculated"),
#     go.Scatter(x=plot_input.index, y=plot_input['flow_mm'], name="Observed"),
# ])
# fig.show()


# # Save hydrograph as png
# dir_path = next(Path.cwd().rglob('outputs_karasu'), None)
# if dir_path is not None:
#     output_name = dir_path / 'gr7j_karasu_hydrograph.png'
#     pio.write_image(fig, output_name, scale=5, width=1920, height=1080)


# # SCEUA best model run
# bestindex,bestobjf = spotpy.analyser.get_minlikeindex(results)
# best_model_run = results[bestindex]
# fields=[word for word in best_model_run.dtype.names if word.startswith('sim')]
# best_simulation = list(best_model_run[fields])
# fig= plt.figure(figsize=(16,9))
# ax = plt.subplot(1,1,1)
# ax.plot(best_simulation,color='black',linestyle='solid', label='Best objf.='+str(bestobjf))
# ax.plot(spotpy_setup.evaluation(),'r.',markersize=3, label='Observation data')
# plt.xlabel('Number of Observation Points')
# plt.ylabel ('Discharge [l s-1]')
# plt.legend(loc='upper right')
# fig.savefig('SCEUA_best_modelrun.png',dpi=300)


# # Plot parameter uncertainty
# parameters = spotpy.parameter.get_parameters_array(spotpy_setup)

# fig, ax = plt.subplots(nrows=7, ncols=2)
# for par_id in range(len(parameters)):
#     plot_parameter_trace(ax[par_id][0], results, parameters[par_id])
#     plot_posterior_parameter_histogram(ax[par_id][1], results, parameters[par_id])

# ax[-1][0].set_xlabel('Iterations')
# ax[-1][1].set_xlabel('Parameter range')

# plt.show()
# fig.savefig('hymod_parameters.png',dpi=300)

