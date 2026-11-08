-- All musical bytes and wave/drum data are derived on this device at enable time.
-- No ROM-derived data is part of this file or the distributable.
return function(mod, mapping)
  local red, reason = mod.datasets:open("red")
  assert(red, "Import your own Pokemon Red in the launcher first (" .. tostring(reason) .. ")")
  local native = require("src.core.ChipSynth")
  -- Drum envelopes use sample positions. Match the engine's platform/performance
  -- rate before deriving them (Android normally selects 22050 Hz).
  local playback = require("src.core.ChipAudio")
  playback.setSampleRate(playback.selectSampleRate(require("src.core.SaveData").loadOptions()))
  local audio = {}
  for _, key in ipairs({ "bankOrder", "waveBanks", "noiseHeaders" }) do
    audio[key] = assert(red.content.audio:get(key), "Imported Red audio is missing " .. key)
  end
  local program = assert(red.content.audio:get("programFile"), "Imported Red sound programs missing")
  audio.programFile = assert(red.assets:path(program), "Imported Red audio cache unavailable")
  audio.generation = 1
  local data = { audio = audio }
  local built = {}
  for cue, label in pairs(mapping) do
    local chip = built[label]
    if not chip then
      local header = assert(red.content.music:get(label), "Imported Red track missing: " .. label)
      -- Native synth resolves the public imported-asset path. No filesystem API,
      -- private cache path, global monkeypatch or engine source modification.
      local engine = native.newEngine(data, header, { allowLoops = true })
      local blob = assert(engine.banks[header.bank], "Imported sound bank unavailable")
      local function byte(address) return assert(blob:byte(address - 0x4000 + 1)) end
      local address = header.address
      local count = math.floor(byte(address) / 64) + 1
      local channels = {}
      for index = 1, count do
        local at = address + (index - 1) * 3
        channels[index] = { number = byte(at) % 16 + 1,
          address = byte(at + 1) + byte(at + 2) * 256 }
      end
      local drums = {}
      for number in pairs(engine.noiseHeaders) do
        local n = tonumber(number)
        if n then drums[n] = engine:noiseInstrument(n) end
      end
      chip = { blob = blob, channels = channels, waves = engine.waves,
        drums = drums, engine = header.engine or 1 }
      built[label] = chip
    end
    mod.content.music:override(cue, { chip = chip })
  end
end
