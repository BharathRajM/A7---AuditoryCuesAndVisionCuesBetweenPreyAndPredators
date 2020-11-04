#!/usr/bin/env python
# coding: utf-8

# In[17]:


import matplotlib
import matplotlib.pyplot as plt
import numpy as np

matplotlib.rcParams.update({'font.size': 14})

labels = ['No audio', 'Audio']
obs = [21.1, 22.2]
no_obs = [22.2, 23.8]

x = np.arange(len(labels))  # the label locations
width = 0.35  # the width of the bars

fig, ax = plt.subplots()
rects1 = ax.bar(x - width/2, obs, width, yerr=[4.9, 5.0], label='Obstacles', capsize=7)
rects2 = ax.bar(x + width/2, no_obs, width, yerr=[7.1, 6.5], label='No obstacles', capsize=7)

# Add some text for labels, title and custom x-axis tick labels, etc.
ax.set_ylabel('Kills by predators')
ax.set_xticks(x)
ax.set_xticklabels(labels)
ax.set_ylim((0, 40))
ax.legend()

def autolabel(rects):
    """Attach a text label above each bar in *rects*, displaying its height."""
    for rect in rects:
        height = rect.get_height()
        ax.annotate('{}'.format(height),
                    xy=(rect.get_x() + rect.get_width() / 2, 0),
                    xytext=(0, 3),  # 3 points vertical offset
                    textcoords="offset points",
                    ha='center', va='bottom')


autolabel(rects1)
autolabel(rects2)

# fig.tight_layout()

plt.savefig('plot.png', dpi=300)


# In[ ]:




