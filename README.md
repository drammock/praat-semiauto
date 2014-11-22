praat-semiauto
==============

Praat scripts for streamlining manual measurements in acoustic analysis

This collection of scripts is designed to maximize the efficiency of hand-measurement in Praat.  Many Praat scripts are designed to operate automatically, by taking measurements from all files in a folder, using the same settings for all files, and never showing the user what it's doing until it spits out the finished spreadsheet.  For some analyses (like amplitude/intensity measurements) that approach works fine, but in other cases there is an inevitable risk of bad data due to formant- or pitch-tracking errors.  These scripts take a different approach, forcing the user to look at the spectrogram and Praat's overlaid pitch or formant track for every measurement.  The user's job is to affirm that Praat's algorithms are finding what they're meant to find, and if not, to tweak the settings until the algorithm returns the correct response.  Everything else is handled by the scripts: opening files, zooming, placing the cursor, etc.  The hope is that what the researcher loses in having to "babysit" the script is gained back in her confidence that the data are accurate and clean: no pitch halving or doubling errors, no spurious formants between F1 and F2, no systematically errorful values for certain talkers due to inappropriate settings, etc.

The scripts were originally developed by Daniel McCloy, with help from August McGrath.  Initial development (2011-2012) was supported by NIH grant R01DC006014.  All scripts are licensed under GPLv3 unless otherwise noted.
