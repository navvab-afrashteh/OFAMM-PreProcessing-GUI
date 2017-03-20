Preprocessing GUI for Optical-Flow Analysis Toolbox 
in Matlab (Registered) for investigating 
the spatiotemporal dynamics of 
Mesoscale brain activity (OFAMM) Version 1.0

Copyright 2016, Navvab Afrashteh, Samsoon Inayat, Mostafa Mohsenvand, Majid H. Mohajerani

Provided under the GNU General Public License, version 3 (GPL-3.0) 


Main Folder: OFAMM Preprocessing GUI 
contains toolbox m files and subfolders


How to use the Preprocessing GUI OFAMM toolbox?
Procedure for using Graphical User Interface for Preprocessing Data:
Steps for preprocessing data include 1) loading the image sequence into the GUI memory space, 2) correcting the image sequence for artifacts from
bleaching of the fluorescent molecules and determining  % ?F/F_0 with a flat baseline, 3) temporal filtering if required, and 4) spatial filtering 
if required. This GUI uses “locdetrend” function from Chronoux toolbox (1) to estimate the baseline. The “locdetrend” function works on the time 
series for each pixel and estimates the local linear trend of the time series. The estimation is done with a moving window in time where the user 
can specify “Moving window (sec)” and “Step Size (sec)” parameters. The appropriate values of these parameters to be used could differ between 
recordings and depend on the duration of recording and how fast the recorded activity is. For shorter recordings and/or faster activities the 
appropriate values are smaller. For our short recordings (<5 sec), we use a moving window of 0.3 sec and step size of 0.1 sec. For longer recordings, 
we recommend 2 sec and 1 sec for moving window and step size, respectively. We also suggest that the user tries other combinations of values to 
obtain averaged % ?F/F_0 time series with flat baseline. While trying different combinations of values, the user can inspect results with 
“Plot Intensity vs. Time for Selected ROI” button after selecting a region or pixels of interest with “Select ROI” or “Select Points” buttons. For 
finding baseline, if a separate image sequence is available (e.g. image sequence with no stimulation while recording evoked brain activity), it can 
be loaded into the GUI memory space using “No Stim” checkbox and the “Load No Stim” button. The no-stimulus image sequence will then be used to 
normalize the original image sequence and calculate % ?F/F_0. If there is no such image sequence (e.g. for spontaneous activity), then the original
image sequence will be used to estimate the baseline.
In preprocessing of long image sequences, it is beneficial to perform principal component analysis (PCA) to reduce dimensionality and find components 
that are of significant interest. PCA decomposes the image sequence into a number of image sequences with their corresponding weights 
(called Eigen-values). The components with small Eigen values are considered as noise and can be removed from the original image sequence. The number 
of components from the decomposed image sequence can be chosen either directly by specifying an integer value (“Remaining PCs” edit box) or by providing 
a percentage of power (“Remaining Power (%)” edit box) such that the power of remaining components is a percentage of the power of the original image sequence.
After determining % ?F/F_0 with flat baseline, temporal or spatial or both types of filtering could be applied on the data. For spatial filtering, either 
median or a Gaussian filter could be used. Median filtering could help to reduce the so called “salt-and-pepper” noise (2,3). Median filter replaces the 
value of a pixel with the median value of all pixels inside a window surrounding the pixel. The window size of median filter could be set in the provided edit box. 
To make the image sequence smoother in the spatial domain, a two-dimensional Gaussian filter could be used. The standard deviation of the Gaussian filter can be 
specified in the “sigma (pixels)” edit box. The “Temporal Gaussian Filter” could be used to filter the data in time domain. User can select one of low-pass (LPF), 
band-pass (BPF), or high-pass (HPF) filters and set the related cut-off frequencies. All the three types of filters are Gaussian. 
Apart from calculating % ?F/F_0, other steps are optional and could be performed in any order. At each step the result could be visualized on the main axes using 
“Play” button and sliding bar with or without mask (“Mask” checkbox). The minimum and maximum values for visualization could be set in the “Min” and “Max” edit boxes, 
respectively.

Reference:
“Optical-flow analysis toolbox for characterization of spatiotemporal dynamics in mesoscale brain activity”, Navvab Afrashteh, Samsoon Inayat, Mostafa Mohsenvand, Majid H. Mohajerani.
