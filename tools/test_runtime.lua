-- Headless integration test; private inputs stay outside git.
-- Run from gen1recomp checkout: luajit MOD_ROOT/tools/test_runtime.lua MOD_ROOT
local root=assert(arg[1])..'/'
local function read(p) local f=io.open(p,'rb'); if not f then return nil end local b=f:read('*a'); f:close(); return b end
local prefix='mods/gen1_music_frlg/'
local enabled=false
local cache=arg[2] and (arg[2]..'/')
local audio=assert(loadfile(cache and (cache..'data/generated/audio.lua') or (root..'source/red_audio.lua')))()
audio.programBytes=assert(read(cache and (cache..audio.programFile) or (root..'source/programs.bin')))
local cleanAudio={} for k,v in pairs(audio) do if k~='programBytes' then cleanAudio[k]=v end end
local files=require('tests.modkit.dataset_view_fixture').cache({},'red',{audio=cleanAudio})
local missingRed=false
local fs={}
function fs.read(p)
 if missingRed and p:sub(1,4)=='red/' then return nil end
 if p=='red/assets/generated/audio/programs.bin' then return audio.programBytes end
 if files[p] then return files[p] end
 if p=='options.lua' and enabled then return 'return {modsByVersion={firered={gen1_music_frlg=true},leafgreen={gen1_music_frlg=true}}}' end
 if p:sub(1,#prefix)==prefix then return read(root..p:sub(#prefix+1)) end
 if p=='red/assets/generated/audio/programs.bin' then return audio.programBytes end
end
function fs.getInfo(p)
 if p=='mods' or p=='mods/gen1_music_frlg' then return {type='directory'} end
 local b=fs.read(p); if b then return {type='file',size=#b} end
end
function fs.getDirectoryItems(p) return p=='mods' and {'gen1_music_frlg'} or {} end
function fs.load(p) local b=fs.read(p); return b and loadstring(b,'@'..p) end
local Source={}; Source.__index=Source
function Source:play() self.playing=true end
function Source:pause() self.playing=false end
function Source:stop() self.playing=false end
function Source:isPlaying() return self.playing end
function Source:setLooping(v) self.looping=v end
function Source:setVolume(v) self.volume=v end
function Source:setPitch() end
function Source:setFilter() end
function Source:getFreeBufferCount() return 4 end
function Source:queue() return true end
function Source:release() end
_G.love={filesystem=fs,timer={getTime=os.clock},audio={},sound={}}
function love.audio.newQueueableSource() return setmetatable({},Source) end
function love.sound.newSoundData(n,rate,bits,channels)
 return {setSample=function() end,getSampleCount=function() return n end,getChannelCount=function() return channels end}
end
local Loader=require('src.mods.Loader')
local ModAudio=require('src.core.game3.mod_audio')
local Music=require('src.core.Music')
local Song=require('src.core.game3.song_ids')
local Synth=require('src.core.ChipSynth')
local mapping=assert(loadfile(root..'mapping.lua'))()
local function copyfs() local f={} for k,v in pairs(fs) do f[k]=v end return f end
local function loaderFor(version,missing)
 local l=Loader.new{fs=copyfs(),generation=3,version=version,dev=false}
 missingRed=missing==true
 return l
end
local function empty() return {generation=3,audio={songs={},sfx={},cries={},mapSongs={}}} end
for _,rate in ipairs({22050,44100}) do
 require('src.core.ChipAudio')._setEnvRateForTest(rate)
 for _,version in ipairs({'firered','leafgreen'}) do
 require('src.core.GameVersion').set(version); Song.select(version)
 enabled=false
 local off=loaderFor(version);local bare=empty();assert(off:load(bare));assert(not off.mods.gen1_music_frlg.enabled);assert(next(bare.audio.songs)==nil)
 enabled=true
 local l=loaderFor(version);local data=empty();assert(l:load(data));assert(#l.errors==0,table.concat(l.errors,'; '));assert(#l.loaded==1)
 ModAudio.install(data)
 local n=0;local tested={}
 for cue,def in pairs(data.audio.songs) do
  assert(def.chip and not def.file)
  assert(ModAudio.songKey(Song.resolve(cue))==cue)
  if not tested[mapping[cue]] then
   tested[mapping[cue]]=true
   local original=Synth.newEngine({audio=audio},audio.songs[mapping[cue]],{allowLoops=true})
   local derived=Synth.newEngine({audio={}},def,{allowLoops=true})
   local peak=0
   for sample=1,rate do
    local a,b=original:sample(),derived:sample()
    assert(math.abs(a-b)<1e-9, cue..': waveform mismatch at '..sample)
    peak=math.max(peak,math.abs(a))
   end
   assert(peak>0,cue..': silent')
  end
  assert(ModAudio.playSong(Song.resolve(cue)));assert(Music.current()==cue)
  ModAudio.stopSong();assert(Music.current()==nil)
  n=n+1
 end
 assert(n==48); assert(not ModAudio.songKey(Song.resolve('MUS_SEVII_123')));assert(not ModAudio.songKey(Song.resolve('MUS_HEAL')))
 print(version..' '..rate..' Hz: PASS default-off, real dataset views/sandbox/loader/schema, 48 cue dispatches, 42 exact native waveforms (1 s each), stop, native fallbacks')
 local missing=loaderFor(version,true);local m=empty();missing:load(m);assert(missing.mods.gen1_music_frlg.failed);assert(next(m.audio.songs)==nil)
 print(version..': PASS missing-Red rollback (expected load error above)')
end

end
