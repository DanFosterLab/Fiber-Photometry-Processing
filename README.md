# Fiber-Photometry-Processing
Various MatLab script files for processing photometry data, especially TDT-acquired data.

Spontaneous Data
- Scripts for spontaneous data are named as A and C for the two animal channels present in the TDT processing unit used.
- The main **Spont** files perform a low-pass and photobleach correction (in a way that flattens broad curves) on the data streams, then detects Events (with an option to output a full-experiment list of them).
- These scripts can analyze 1 or 2 chosen time windows (such as baseline and experimental periods) and output stats for each window.
- Additional sections can be un-commented to offer outputting detected events and a downsampled data stream for each window.
- There is an optional section to output plottable data of averaged and/or individual event traces (Note: the **Transient Trace** script must also be open to be called). 
- Optional **Binned** data scripts are intended to be ran immediately after the corresponding main script. These will carry over event data, divide it into bins, and normalize bins to the defined baseline (pre-injection) period.

Base Shift Data
- Used for analyzing drug effects that shift the overall curve of the signal, such as stimulants.
- This one script processes data from both channels, A & C, simultaneously.
- It applies a low-pass, a mild (polyfit) photobleach correction based on user-defined baseline, and calculates the dF/F.
- It then calculates Z-score of this data stream to determine divergence from the baseline period.
- By default it downsamples Z-score data to 1 Hz, which can be adjusted, and outputs it. It can also output downsampled dF/F data rather than Z-Score.

Additional Notes
- For convenient naming of output files (figures and data), all script files utilize a 4-character convention that assumes the data folders are named for each subject (A & C) as AAAA_CCCC_RestOfFolderName.
