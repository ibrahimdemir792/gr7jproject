from pathlib import Path
import pandas as pd
import datetime
from gr7jmodule import InputDataHandler, ModelGr7j
import plotly.graph_objects as go
import spotpy
import json

# Load Catchment Data
working_directory = Path('~/gr7jproject').expanduser().resolve()
data_path = next(working_directory.rglob('**/nemetice_data.pkl'), None)
if data_path:
    df = pd.read_pickle(data_path)
else:
    print("Input data not found")
df.columns = ['date', 'precipitation', 'temperature', 'evapotranspiration', 'flow', 'flow_mm']
df.index = df['date']

inputs = InputDataHandler(ModelGr7j, df)
start_date = datetime.datetime(1998, 1, 1, 0, 0)
end_date = datetime.datetime(2004, 12, 31, 0, 0)
inputs = inputs.get_sub_period(start_date, end_date)

# Set the model parameters by hand:
# parameters = {
#         "X1": 170.532,
#         "X2": 0.457612,
#         "X3": 46.6777,
#         "X4": 3.73663,
#         "X5": 0.435072,
#         "X6": 17.8694,
#     }

# Read the model parameters from file
parameters_path = next(Path.cwd().rglob('gr7j_param_nemetice.json'), None)
if parameters_path:
    with open (parameters_path, "r") as file:
        parameters = json.load(file)
else:
    print("Parameters file not found!")

model = ModelGr7j(parameters)
model.set_parameters(parameters)  # Re-define the parameters for demonstration purpose.

# Initial state :
initial_states = {
    "production_store": 0.5, # was 0.5 according to Simon
    "routing_store": 0.6, # was 0.6 according to Simon
    "exponential_store": 0.3,
    "uh1": None,
    "uh2": None
}
model.set_states(initial_states)

outputs = model.run(inputs.data)
print("\n***VALIDATION***")
print(outputs.head())

nse = spotpy.objectivefunctions.nashsutcliffe(inputs.data['flow_mm'], outputs['flow'])
print(f"Used parameters for Validation: {parameters}")
print(f"val_nse: {nse}")

# fig = go.Figure([
#     go.Scatter(x=outputs.index, y=outputs['flow'], name="Calculated"),
#     go.Scatter(x=inputs.data.index, y=inputs.data['flow_mm'], name="Observed"),
# ])
# fig.show()
