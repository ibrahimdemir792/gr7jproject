import spotpy
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics import r2_score

df = pd.read_excel('obs_sim_gr6j_gr7j.xlsx')
obs = df['obs']
sim6 = df['sim6']
sim7 = df['sim7']
# nse = spotpy.objectivefunctions.nashsutcliffe(obs, sim)
r2 = r2_score(sim6, sim7)
# print(nse)

# Sort the observed and simulated values
obs_sorted = np.sort(obs)
sim6_sorted = np.sort(sim6)
sim7_sorted = np.sort(sim7)

# Calculate the cumulative probabilities
obs_cdf = np.linspace(0, 1, len(obs_sorted))
sim6_cdf = np.linspace(0, 1, len(sim6_sorted))
sim7_cdf = np.linspace(0, 1, len(sim7_sorted))

# Plot the CDF
plt.title('Kümülatif Dağılım Fonksiyonu (GR6J ve GR7J)')
plt.plot(obs_sorted, obs_cdf, label='Gözlemlenen')
plt.plot(sim6_sorted, sim6_cdf, label='GR6J')
plt.plot(sim7_sorted, sim7_cdf, label='GR7J')
plt.xlabel('Q (mm/gün)')
plt.ylabel('Kümülatif Dağılım')
plt.legend()
plt.show()

# Plot the scatter
plt.title('Saçılım Grafiği (GR6J ve GR7J)')
plt.scatter(sim6, sim7, label='Akım')
plt.plot([min(obs), max(obs)], [min(obs), max(obs)], color='red')
plt.text(max(obs), max(obs), f'R\u00B2: {r2:.2f}')
plt.xlabel('GR6J Simüle Akım (mm/gün)')
plt.ylabel('GR7J Simüle Akım (mm/gün)')
plt.legend()
plt.show()