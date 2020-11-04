#!/usr/bin/env python
# coding: utf-8

# In[1]:


import pandas as pd


# In[8]:


# The data file to read
data_file = 'cleaned-data-final.csv'
# The number of runs in the file
nruns = 160
# The number of runs per condition
nruns_per_condition = 40

# The script is not exactly generic over the number of report variables used
# In our case, it was 5; this is why you see the number 5 sprinkled throughout the code


# In[9]:


df = pd.read_csv(data_file, delimiter=';', low_memory=False)


# In[10]:


# Remove the label column
df = df.iloc[:, 1:]
# Spread the run variables to all the columns where it applies
# (it turns out this was not necessary for the data layout I ended
# up using, but I'm keeping it because it can be helpful when
# inspecting the data)
for i in range(df.shape[1]):
    if i % 5 != 0:
        df.iloc[0, i] = df.iloc[0, i - i % 5]
        df.iloc[1, i] = df.iloc[0, i - i % 5]
        df.iloc[2, i] = df.iloc[0, i - i % 5]


# In[11]:


# Make a dataframe indicating the experimental variables for each run
vars = df.iloc[0:3, 0::5]
vars = vars.rename(index={0: 'clusters', 1: 'vision', 2: 'audio-range'})


# In[12]:


# Select the output variables we're interested in
# And only capture the last value from the simulation
# (because for these variables the intermediate values are not interesting)
kills = df.iloc[4, 1::5].astype('int32')
lifetime = df.iloc[4, 2::5].astype('float32')
alive = df.iloc[4, 0::5].astype('int32')


# In[13]:


# Go through the different experimental conditions
# and print a simple analysis of each
for condition in range(nruns // nruns_per_condition):
    vs = vars.iloc[:, condition]
    ks = kills.iloc[condition::6]
    ls = lifetime.iloc[condition::6]
    als = alive.iloc[condition::6]
    print('Condition nclusters={}, audiorange={}, vision={}'
          .format(vs['clusters'], vs['audio-range'], vs['vision']))
    print('\tMean predator kills: {} ± {}'.format(ks.mean(), ks.std()))
    print('\tMean flock lifetime: {} ± {}'.format(ls.mean(), ls.std()))
    print('\tMean turtles left alive: {} ± {}'.format(als.mean(), als.std()))
    print('')


# In[53]:


df


# In[ ]:




