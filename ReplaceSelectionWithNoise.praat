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
# VERSION 0.2 (2014 11 22)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# NOTE: This script unfortunately has to close and re-open the TextGrid Editor
# window, because changes it makes to the Sound file are not picked up by a
# TextGrid editor that was already open prior to the changes being made.
    ed_info$ = Editor info
    sn_info$ = Sound info
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
Remove
# Replace selection with noise
selectObject: "Sound " + sn_name$
Formula (part): sel_st, sel_nd, 1, 1, "randomGauss(0," + string$(rms) +")"
# Re-open TextGrid editor
plusObject: "TextGrid " + tg_name$
View & Edit
editor: "TextGrid " + tg_name$
	Zoom: win_st, win_nd
    Select: sel_st, sel_nd
