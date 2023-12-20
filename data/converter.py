import pandas as pd

""" 
    Convert excel data to csv and pkl
    Write your file name into related fields
"""
# Load excel file (read attribute reads as str)
df = pd.read_excel('adanadata.xlsx')

# Convert date column into datetime format
df['date'] = pd.to_datetime(df['date'], format='%d/%m/%Y')

# Format date column with "/" seperator
df['date'] = pd.to_datetime(df['date']).dt.strftime('%d/%m/%Y')

# Export as csv
df.to_csv('adana_data.csv', index=False)

# Load csv file and round values 
df = pd.read_csv('adana_data.csv')
df[['P', 'T', 'E', 'Q', 'Qmm']] = df[['P', 'T', 'E', 'Q', 'Qmm']].round(2)
df.to_csv('adana_data.csv', index=False)

# Convert date column into datetime format
df['date'] = pd.to_datetime(df['date'], format='%d/%m/%Y')

# Export pickle file
df.to_pickle('adana_data.pkl')