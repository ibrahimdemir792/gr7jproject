## USAGE
1. Load your .xlsx data into "data" folder. (Make sure your column names are match with the examples. Use "dot" for decimals)
2. In data_converter.py file, write your data file name into related fields and run `data_converter.py`. It will generate .csv and .pkl extensions of your data.
3. To run spotpy calibrating tool, in `calibrating.py` write your new .pkl file into L:15
4. Check validation and calibration dates (L:69, 70 and L:104, 105)
5. Select calibrating algorithm from L:74 to L:82
5. Run `calibrating.py`

## SELECTING GR MODEL
- To select specific GR model
```bash
# Import selected model
from gr7jmodule import ModelGr6j
# In this case Gr6j is selected
```
- initialize the parameters according to selected model L:34.
- add or remove parameters from related lines according to Model parameters count.
