# PRAAT SCRIPT "MIX SPEECH WITH NOISE"
# This Praat script takes a directory of sound files, and a single noise file, mixes the stimuli with the noise at a specified SNR, and writes the resultant sounds as WAV files in a specified directory.  Two methods of (optional) intensity scaling of the resultant sounds is available.
# AUTHOR: Daniel McCloy (drmccloy@uw.edu)
# LICENSED UNDER THE GNU GENERAL PUBLIC LICENSE v3.0: http://www.gnu.org/licenses/gpl.html

form Mix speech with noise
  comment Make sure to put trailing slashes in the folder paths
	sentence Stimuli_folder /home/dan/Desktop/stimuli/
	sentence Noise_file /home/dan/Desktop/SpeechShapedNoise.wav
	sentence Output_folder /home/dan/Desktop/stimuliWithNoise/
	real Desired_SNR 0
	optionmenu finalIntensity: 1
		option match final intensity to stimulus intensity
		option maximize (scale peaks to plus/minus 1)
		option just add noise to signal (don't scale result)
endform

echo Mixing at SNR 'desired_SNR'

# if output_folder already exists, this does nothing:
createDirectory("'output_folder$'")

# NOISE
noise = Read from file... 'noise_file$'
Rename... noise
noiseDur = Get total duration
noiseRMS = Get root-mean-square... 0 0

# STIMULI
stimList = Create Strings as file list... stimList 'stimuli_folder$'*.wav
n = Get number of strings

for i from 1 to n
	# READ IN EACH STIMULUS
	select stimList
	curFile$ = Get string... 'i'
	curSound = Read from file... 'stimuli_folder$''curFile$'
	curDur = Get total duration
	curRMS = Get root-mean-square... 0 0
	curInten = Get intensity (dB)

  while curDur > noiseDur
		# duplicate noise and concatenate it to itself
		select noise
		temp = Concatenate
		plus noise
		noise = Concatenate
		select temp
		Remove
		select noise
		noiseDur = Get total duration
  endwhile

	# CALCULATE NOISE COEFFICIENT THAT YIELD DESIRED SNR
	# SNR = 20*log10(SignalAmpl/NoiseAmpl)
	# NoiseAmpl = SignalAmpl / (10^(SNR/20))
	noiseAdjustCoef = (curRMS / (10^(desired_SNR/20))) / noiseRMS

	# MIX SIGNAL AND NOISE AT SPECIFIED SNR
	select curSound
	Formula...  self[col] + 'noiseAdjustCoef' * Sound_noise[col]


	# SCALE RESULT IF NECESSARY
  if finalIntensity = 1
		# scale to match original
		Scale intensity... curInten

	elsif finalIntensity = 2
		# scale to +/- 1
		Scale peak... 0.99
  endif

	# WRITE OUT FINAL FILE
	select curSound
	Save as WAV file... 'output_folder$''curFile$'
	Remove

endfor

if finalIntensity = 1
	printline Scaling to match original intensities
elsif finalIntensity = 2
	printline Scaling peaks to +/- 0.99
else
	printline No scaling requested, watch out for clipping
endif

select noise
plus stimList
Remove
printline Done!
