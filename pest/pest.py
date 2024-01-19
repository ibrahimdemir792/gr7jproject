
import pyemu
import pandas as pd
from gr7jmodule import InputDataHandler, ModelGr7j
from pathlib import Path
import flopy

class PyPestSetup:
    def __init__(self, data):
        self.data = data
        self.model_inputs = InputDataHandler(ModelGr7j, self.data)


    def create_pst_file(self, pst_file):
        # Create a new PEST control file
        pst = pyemu.Pst(filename=pst_file)

        # Define parameters
        self.params = ['x1', 'x2', 'x3', 'x4', 'x5', 'x6', 'x7']
        param_bounds = [(0.0, 2500.0), (-5.0, 5.0), (0.0, 1000.0), (0.5, 10.0), (-4.0, 4.0), (0.0, 20.0), (0.05, 0.95)]

        # Add parameters to PEST control file
        for param, bounds in zip(self.params, param_bounds):
            pst.parameter_data = pst.parameter_data._append({
                'parnme': param,
                'parval1': (bounds[0] + bounds[1]) / 2,  # initial value
                'parlbnd': bounds[0],  # lower bound
                'parubnd': bounds[1],  # upper bound
            }, ignore_index=True)

        # Write the PEST control file
        pst.write(pst_file)

    def run(self, pst_file):
        # Load the PEST control file
        pst = pyemu.Pst(pst_file)

        # Run PEST
        pst.control_data.noptmax = 0
        pst.write()

        # Here you would add code to run PEST, e.g., using the `os.system` function to call PEST from the command line
    
working_directory = Path('~/gr7jproject').expanduser().resolve()
data_path = next(working_directory.rglob('**/karasu.csv'), None)
if data_path:
    df = pd.read_csv(data_path)
    df['date'] = pd.to_datetime(df['date'], errors='coerce')
    df.columns = ['date', 'precipitation', 'temperature', 'evapotranspiration', 'flow_mm']
    df.index = df['date']
else:
    print("Input data not found")

# Create a PEST setup object
pest_setup = PyPestSetup(df)
pest_setup.create_pst_file(pst_file='GR7J.pst')
pest_setup.run(pst_file='GR7J.pst')