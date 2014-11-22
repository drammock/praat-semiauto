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
# LIMITATIONS: At present, the script only works in TextGrid Editors created
# from Sound objects, not from LongSound objects.
#
# AUTHOR: Daniel McCloy <drmccloy@uw.edu>
# LICENSE: BSD 3-clause
# VERSION 0.1 (2014 11 22)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    ed_info$ = Editor info
    sn_info$ = Sound info
    Close
endeditor
win_st = extractNumber (ed_info$, "Window start:")
win_nd = extractNumber (ed_info$, "Window end:")
sel_st = extractNumber (ed_info$, "Selection start:")
sel_nd = extractNumber (ed_info$, "Selection end:")
tg_name$ = extractWord$ (ed_info$, "Data name:")
sn_name$ = extractWord$ (sn_info$, "Object name:")
rms = extractNumber (sn_info$, "Root-mean-square:")
selectObject: "Sound " + sn_name$
Formula (part): sel_st, sel_nd, 1, 1, "randomGauss(0," + string$(rms) +")"
plusObject: "TextGrid " + tg_name$
View & Edit
editor: "TextGrid " + tg_name$
	Zoom: win_st, win_nd
    Select: sel_st, sel_nd
