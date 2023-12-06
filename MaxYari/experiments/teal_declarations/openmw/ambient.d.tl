--[[
  `openmw.ambient` controls background sounds, specific to given player (2D-sounds).
  Can be used only by local scripts, that are attached to a player.
  local ambient = require('openmw.ambient')
]]

local record ambient
  --[[
    Check if music is playing
    local isPlaying = ambient.isMusicPlaying();
  ]]
  isMusicPlaying: function(): boolean
  
  --[[
    Check if sound file is playing
    local isPlaying = ambient.isSoundFilePlaying("Sound\\test.mp3");
  ]]
  isSoundFilePlaying: function(
    fileName: string
  ): boolean
  
  --[[
    Check if sound is playing
    local isPlaying = ambient.isSoundPlaying("shock bolt");
  ]]
  isSoundPlaying: function(
    soundId: string
  ): boolean
  
  --[[
    Play a 2D sound
    local params = {
       timeOffset=0.1
       volume=0.3,
       scale=false,
       pitch=1.0,
       loop=true
    };
    ambient.playSound("shock bolt", params)
  ]]
  playSound: function(
    soundId: string, --[[ID of Sound record to play]]
    options: table
  )
  
  --[[
    Play a 2D sound file
    local params = {
       timeOffset=0.1
       volume=0.3,
       scale=false,
       pitch=1.0,
       loop=true
    };
    ambient.playSoundFile("Sound\\test.mp3", params)
  ]]
  playSoundFile: function(
    fileName: string, --[[Path to sound file in VFS]]
    options: table
  )
  
  --[[
    Stop to play current music
    ambient.stopMusic();
  ]]
  stopMusic: function()
  
  --[[
    Stop a sound
    ambient.stopSound("shock bolt");
  ]]
  stopSound: function(
    soundId: string
  )
  
  --[[
    Stop a sound file
    ambient.stopSoundFile("Sound\\test.mp3");
  ]]
  stopSoundFile: function(
    fileName: string
  )
  
  --[[
    Play a sound file as a music track
    ambient.streamMusic("Music\\Test\\Test.mp3");
  ]]
  streamMusic: function(
    fileName: string
  )
  
end
return ambient