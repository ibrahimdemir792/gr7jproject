import pandas as pd

""" 
    Convert excel data to csv and pkl
    Write your excel filename of your data into related fields
"""
# Load excel file (read attribute reads as str)
df = pd.read_excel('karasuPestValidation.xlsx')

# Convert date column into datetime format
df['date'] = pd.to_datetime(df['date'], format='%d/%m/%Y')

# Format date column with "/" seperator
df['date'] = pd.to_datetime(df['date']).dt.strftime('%d/%m/%Y')

# Convert NaN values to zero
df = df.fillna(0)

# Export as csv
df.to_csv('karasuPestValidation.csv', index=False)

# Load csv file and round values 
df = pd.read_csv('karasuPestValidation.csv')
# df = df.round(2)
df.to_csv('karasuPestValidation.csv', index=False)

# Convert date column into datetime format
df['date'] = pd.to_datetime(df['date'], format='%d/%m/%Y')

# Export pickle file
df.to_pickle('karasuPestValidation.pkl')