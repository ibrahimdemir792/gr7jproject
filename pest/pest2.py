import datetime
import json
import pandas as pd
from pathlib import Path
from gr7jmodule import ModelGr7j
import spotpy
import plotly.graph_objects as go
import plotly.io as pio


""" VALIDATION
    Validate calibration on another time period
"""

# Load catchment data
working_directory = Path('~/gr7jproject').expanduser().resolve()
data_path = next(working_directory.rglob('**/karasu_cdo_karli_copy.csv'), None)

if data_path:
    df = pd.read_csv(data_path)
    df['date'] = pd.to_datetime(df['date'], format='%d/%m/%Y')
    df.columns = ['date', 'precipitation', 'temperature', 'evapotranspiration', 'flow_mm']
    df.index = df['date']
else:
    print("Input data not found")


# Load parameters from PEST output
parameters_path = next(working_directory.rglob('**/PARS.out'), None)
parameters = {}
keys = ['X1', 'X2', 'X3', 'X4', 'X5', 'X6', 'X7']

with open(parameters_path, 'r') as file:
    for i, key in enumerate(keys):
        line = file.readline()
        if i == 6:  # Skip the 7th value (0-indexed)
            line = file.readline()
        parameters[key] = float(line.strip())


# Select a sub-period for validation
start_date = datetime.datetime(1983, 1, 1, 0, 0)
end_date = datetime.datetime(1992, 12, 31, 0, 0)
mask = (df['date'] >= start_date) & (df['date'] <= end_date)
sub_period_data = df.loc[mask]


# Run the model
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

outputs = model.run(sub_period_data)
print("\n***VALIDATION***")
print(outputs.head())

# Remove the first year used to warm up the model :
filtered_input = sub_period_data[sub_period_data.index >= datetime.datetime(1984, 1, 1, 0, 0)]
filtered_output = outputs[outputs.index >= datetime.datetime(1984, 1, 1, 0, 0)]

nse = spotpy.objectivefunctions.nashsutcliffe(filtered_input['flow_mm'], filtered_output['flow'])
print(f"Used parameters for Validation: {parameters}")
print(f"gr7j_val_nse: {nse}")

# fig = go.Figure([
#     go.Scatter(x=filtered_output.index, y=filtered_output['flow'], name="Calculated"),
#     go.Scatter(x=filtered_input.index, y=filtered_input['flow_mm'], name="Observed"),
# ])
# fig.show()