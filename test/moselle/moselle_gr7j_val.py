from pathlib import Path
import pandas as pd
import datetime
from gr7jmodule import InputDataHandler, ModelGr7j
import plotly.graph_objects as go
import plotly.io as pio
import spotpy
import json

# Load Catchment Data
working_directory = Path('~/gr7jproject').expanduser().resolve()
data_path = next(working_directory.rglob('**/MOSELLE_verisi.pkl'), None)
if data_path:
    df = pd.read_pickle(data_path)
else:
    print("Input data not found")
df.columns = ['date', 'precipitation', 'temperature', 'evapotranspiration', 'flow', 'flow_mm']
df.index = df['date']

inputs = InputDataHandler(ModelGr7j, df)
start_date = datetime.datetime(1951, 1, 1, 0, 0)
end_date = datetime.datetime(1980, 12, 31, 0, 0)
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
parameters_path = next(Path.cwd().rglob('gr7j_parameters.json'), None)
if parameters_path:
    with open (parameters_path, "r") as file:
        parameters = json.load(file)
else:
    print("Parameters file not found!")

model = ModelGr7j(parameters)
model.set_parameters(parameters)  # Re-define the parameters for demonstration purpose.

# Initial state :
initial_states = {
    "production_store": 0.5,
    "routing_store": 0.5,
    "exponential_store": 0.3,
    "uh1": None,
    "uh2": None
}
model.set_states(initial_states)

outputs = model.run(inputs.data)
print("\n***VALIDATION***")
print(outputs.head())


filtered_input = inputs.data[inputs.data.index >= datetime.datetime(1952, 1, 1, 0, 0)]
filtered_output = outputs[outputs.index >= datetime.datetime(1952, 1, 1, 0, 0)]

nse = spotpy.objectivefunctions.nashsutcliffe(filtered_input['flow_mm'], filtered_output['flow'])
print(f"Used parameters for Validation: {parameters}")
print(f"gr7j_val_nse: {nse}")


fig = go.Figure([
    go.Scatter(x=filtered_output.index, y=filtered_output['flow'], name="Calculated"),
    go.Scatter(x=filtered_input.index, y=filtered_input['flow_mm'], name="Observed"),
])
fig.show()

# Save plot as png
dir_path = next(Path.cwd().rglob('outputs_moselle'), None)
if dir_path is not None:
    output_name = dir_path / 'plot.png'
    pio.write_image(fig, output_name, scale=5, width=1920, height=1080)
