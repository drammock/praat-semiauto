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
# LIMITATIONS: At present, the script only works in TextGrid Editors opened with
# Sound objects, not from LongSound objects. So far no workaround is known,
# since LongSound objects don't have the "Formula (part)" command available.
# Probably it would require cutting the LongSound into pieces at the start and
# end of the selection, and concatenating the white noise in between the
# beginning piece and the end piece.
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
