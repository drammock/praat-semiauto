# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Praat script "Replace selection with noise"
# This script runs within a TextGrid Editor window, with the sole function of
# replacing a selected span of sound with white noise. The noise will have an
# amplitude matching the RMS amplitude of the sound file. This is useful for, 
# e.g., anonymizing field recordings when the speaker or interviewer mentions
# another individual by name.
#
# USAGE: In a TextGrid editor, choose menu command File > Open editor script...
# With a span of sound selected, switch to the script window and choose "Run".
# Optionally, from the script window choose "File > Add to menu..." to 
# permanently add this script as a menu command in all future TextGrid Editors.
#
# LIMITATIONS AND WARNINGS: This script works best with TextGrid editors opened
# with Sound objects, rather than LongSound objects. When working in TextGrid
# editors with LongSound objects, Praat can't make changes to the sound file
# directly, so the script has to create a copy of the LongSound on your Desktop
# (by first extracting the parts of the LongSound before and after the selection
# and concatenating them together with the noise sound in betweeen). This might
# or might not work on your computer, depending on how long the LongSound file
# is (e.g., if it is too big to fit in memory, then extracting all but the
# selection is likely to also be too big to fit in memory, and may lead to an
# "out of memory" error and possibly a Praat crash). Therefore, it is STRONGLY
# recommended that, when working with LongSound files, you save your TextGrid
# (and any other open, unsaved files in Praat) before running the "replace
# selection with noise" script. If you do experience out-of-memory errors or
# crashes, you can either run the script on a computer with more RAM, or cut the
# LongSound into smaller pieces and anonymize them separately as Sound objects,
# then recombine them later.
#
# AUTHOR: Daniel McCloy <drmccloy@uw.edu>
# LICENSE: BSD 3-clause
# VERSION 0.3 (2014 11 23)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# NOTE: This script unfortunately has to close and re-open the TextGrid Editor
# window, because changes it makes to the Sound file are not picked up by a
# TextGrid editor that was already open prior to the changes being made.
	ed_info$ = Editor info
	sn_info$ = nocheck Sound info
	if sn_info$ = ""
		ls = 1
		sn_info$ = LongSound info
	else
		ls = 0
	endif
	tmp_snd = Extract selected sound (preserve times)
	Close
endeditor
win_st = extractNumber (ed_info$, "Window start:")
win_nd = extractNumber (ed_info$, "Window end:")
sel_st = extractNumber (ed_info$, "Selection start:")
sel_nd = extractNumber (ed_info$, "Selection end:")
tg_name$ = extractWord$ (ed_info$, "Data name:")
sn_name$ = extractWord$ (sn_info$, "Object name:")
# Calculate the RMS amplitude of the selection to be replaced
selectObject: tmp_snd
rms = Get root-mean-square: 0, 0
fs = Get sampling frequency
nchan = Get number of channels
Remove
# Replace selection with noise
if ls
	selectObject: "LongSound " + sn_name$
	file_st = Get start time
	file_nd = Get end time
	ls_st = Extract part: file_st, sel_st, "yes"
	noise = Create Sound from formula: "noise", nchan, sel_st, sel_nd, fs, "randomGauss(0," + string$(rms) +")"
	selectObject: "LongSound " + sn_name$
	ls_nd = Extract part: sel_nd, file_nd, "yes"
	selectObject: ls_st
	plusObject: noise
	plusObject: ls_nd
	new_ls = Concatenate
	if right$(sn_name$, 10) = "_anonymous"
		new_sn_name$ = sn_name$
	else
		new_sn_name$ = sn_name$ + "_anonymous"
	endif
	Rename: new_sn_name$
	Save as WAV file: "~/Desktop/" + new_sn_name$ + ".wav"
	plusObject: ls_st
	plusObject: noise
	plusObject: ls_nd
	plusObject: "LongSound " + sn_name$
	Remove
	Open long sound file: "~/Desktop/" + new_sn_name$ + ".wav"
else
	selectObject: "Sound " + sn_name$
	Formula (part): sel_st, sel_nd, 1, 1, "randomGauss(0," + string$(rms) +")"
endif
# Re-open TextGrid editor
plusObject: "TextGrid " + tg_name$
View & Edit
editor: "TextGrid " + tg_name$
	Zoom: win_st, win_nd
	Select: sel_st, sel_nd
