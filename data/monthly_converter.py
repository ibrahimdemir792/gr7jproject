import pandas as pd

# Read data from csv
data = pd.read_csv("MOSELLE_verisi.csv")

# Convert date into datetime format
data['date'] = pd.to_datetime(data['date'], format='%d/%m/%Y')

# Set date column as index
data.set_index('date', inplace=True)

# Calculate monthly data for each year
monthly_data = data.resample("M").mean().round(2)

# Extract the month from the index before converting it to strings
monthly_data['Month'] = monthly_data.index.month

# Convert date column into string formatted as d/m/y
monthly_data.index = monthly_data.index.strftime('%d/%m/%Y')

# Export monthly data for each year
monthly_data.to_csv("MOSELLE_monthly.csv")

# Calculate averages for each month for all data
monthly_averages = monthly_data.groupby('Month').mean().round(2)

# Export 12 row monthly data
monthly_averages.to_csv("MOSELLE_twelwe.csv")