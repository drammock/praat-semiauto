# PRAAT SCRIPT "CALCULATE LTAS OF CORPUS"
# This Praat script takes a directory of stimulus files and creates a Gaussian noise file that is spectrally shaped to match the long-term average spectrum of the stimuli, matches the duration of the longest stimulus (plus any noise padding specified in the arguments to the script), and scaled to match the average intensity of the stimuli.  Two methods of spectral averaging are provided: either (1) calculating the LTAS of each file and averaging them, or (2) concatenating the stimuli and breaking into equal-sized chunks and averaging the LTAS's of the chunks.  The methods are expected to differ substantially only when the stimuli vary dramatically in length (in which case method 1, by treating all LTAS's as equal, effectively weights the final spectrum in favor of shorter files).  The script also saves the LTAS object into the output directory (along with the noise file).
# This script is loosely based on the script "ltasnoise.praat" by Theo Veenker, Lisette van Delft, and Hugo Quené (see Quené & Van Delft (2010). Speech Commun, 52, 911-918. doi:10.1016/j.specom.2010.03.005)
# AUTHOR: Daniel McCloy (drmccloy@uw.edu)
# LICENSED UNDER THE GNU GENERAL PUBLIC LICENSE v3.0: http://www.gnu.org/licenses/gpl.html

form Calculate LTAS of corpus
	sentence input_folder /home/dan/Documents/academics/research/dissertation/stimuli/dissTalkers/
	sentence output_folder /home/dan/Documents/academics/research/dissertation/stimuli/noise/
	positive ltasBandwidth_(Hz) 100
	positive noisePadding 0.05
	optionmenu method: 2
		option by file
		option by chunk
	positive Chunk_duration 30
	comment Chunk duration is ignored if method is "by file".
endform

Create Strings as file list... stimuli 'input_folder$'*.wav
n = Get number of strings
intensityRunningTotal = 0
longestFileDuration = 0
echo 'n' WAV files in directory 'input_folder$'

# OPEN ALL SOUND FILES
for i from 1 to n
	select Strings stimuli
	curFile$ = Get string... 'i'
	tempSound = Read from file... 'input_folder$''curFile$'
	# KEEP TRACK OF INTENSITIES SO WE CAN SCALE NOISE APPROPRIATELY
	intens = Get intensity (dB)
	intensityRunningTotal = intensityRunningTotal + intens
	# KEEP TRACK OF DURATIONS SO THE NOISE IS LONG ENOUGH FOR THE LONGEST STIMULUS
	tempDur = Get total duration
	if longestFileDuration < tempDur
		longestFileDuration = tempDur
	endif
	if method = 1
		if i = 1
			printline Creating LTAS objects...
		endif
		# CREATE LTAS FOR EACH FILE AS IT'S OPENED, AND IMMEDIATELY CLOSE SOUND FILE
		ltas_'i' = To Ltas... ltasBandwidth
		select tempSound
		Remove
	else
		# RE-OPEN EACH FILE AS LONGSOUND, TO BE CONCATENATED AND CHUNKED LATER
		Remove
		snd_'i' = Open long sound file... 'input_folder$''curFile$'
	endif
endfor

if method = 1
	# SELECT FILEWISE LTAS OBJECTS AND AVERAGE
	printline Averaging LTAS objects...
	select ltas_1
	for i from 2 to n
		plus ltas_'i'
	endfor
	finalLTAS = Average
	Save as binary file... 'output_folder$'CorpusFilewise.Ltas
	select ltas_1
	for i from 2 to n
		plus ltas_'i'
	endfor
	Remove
else
	# Calculate LTAS in equal-length chunks instead of by file (otherwise it would effectively weight the shorter files and deweight the longer files). Note that this is a bad idea if your files don't begin and end in silence, and is unnecessary (and slower) if all your files are the same duration.
	# CONCATENATE
	printline Concatenating corpus...
	select snd_1
	for i from 2 to n
		plus snd_'i'
	endfor
	Save as WAV file... 'output_folder$'ConcatenatedCorpus.wav
	Remove
	# SPLIT INTO EQUAL-LENGTH CHUNKS
	printline Chunking corpus...
	corpus = Open long sound file... 'output_folder$'ConcatenatedCorpus.wav
	corpusDur = Get total duration
	chunkCount = ceiling(corpusDur/chunk_duration)
	# CREATE LTAS FOR EACH CHUNK
	printline Creating LTAS objects...
	for i from 1 to chunkCount
		select corpus
		tempSound = Extract part... chunk_duration*(i-1) chunk_duration*i no
		ltas_'i' = To Ltas... ltasBandwidth
		select tempSound
		Remove
	endfor
	# CREATE FINAL LTAS
	printline Averaging LTAS objects...
	select ltas_1
	for i from 2 to chunkCount
		plus ltas_'i'
	endfor
	finalLTAS = Average
	Save as binary file... 'output_folder$'CorpusChunkwise.Ltas
	# CLEAN UP INTERIM FILES
	select corpus
	for i from 1 to chunkCount
		plus ltas_'i'
	endfor
	Remove
	filedelete 'output_folder$'ConcatenatedCorpus.wav
endif

# CREATE WHITE NOISE SPECTRUM
printline Creating speech-shaped noise...
whiteNoise = Create Sound from formula... noise 1 0 longestFileDuration+2*noisePadding 44100 randomGauss(0,0.1)
noiseSpect = To Spectrum... no
Formula... self*10^(Ltas_averaged(x)/20)
ltasNoise = To Sound
# SCALE TO AVERAGE INTENSITY OF INPUT FILES
meanIntensity = intensityRunningTotal / n
Scale intensity... meanIntensity
Save as WAV file... 'output_folder$'SpeechShapedNoise.wav
# CLEAN UP
select whiteNoise
plus noiseSpect
plus Strings stimuli
plus finalLTAS
plus ltasNoise
Remove

printline Done!
