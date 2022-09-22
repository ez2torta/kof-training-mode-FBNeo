local player = {}

function player.new(number)
	return  {
		number = number,
		charaName="",
		charId=0,
		side = 0,
		health = { 
			current = 0,
			previous = 0 
		},
		guard = {
			current = 0,
			previous = 0
		},
		stun = {
			current = 0,
			previous = 0
		},
		super = {
			value = 0,
			timeout = 0
		},
		damage = { 
			hit = 0,
			combo = 0
		},
		inputs = {
			current = {},
			previous = {},
			history = {-1},
			record = {
				enabled = false,
				memory = {},
				index = 1,
				side = 0,
				current = {}
			},
			playback = {
				enabled = false,
				memory = {},
				index = 1
			},
		}
	}
end

local function getBase(playerNumber, game)
	return game.address.player + (playerNumber - 1) * game.address.space
end
local function toBits(num,bits)
    -- returns a table of bits, most significant first.
    bits = bits or math.max(1, select(2, math.frexp(num)))
    local t = {} -- will contain the bits        
    for b = bits, 1, -1 do
        t[b] = math.fmod(num, 2)
        num = math.floor((num - t[b]) / 2)
    end
    return t
end

local function printLotsOfInfo(base)
	for offset=0,511 do
		print("offset"..offset)
		local readvalue = readByte(base + offset) 
		local bits = toBits(readvalue)
		print(table.concat(bits))
	end
end


local chara_table =
{
  [0x0] = 'Kyo',
  [0x1] = 'Benimaru',
  [0x2] = 'Daimon',
  [0x3] = 'Terry',
  [0x4] = 'Andy',
  [0x5] = 'Joe',
  [0x6] = 'Ryo',
  [0x7] = 'Robert',
  [0x8] = 'Yuri',
  [0x9] = 'Leona',
  [0xa] = 'Ralf',
  [0xb] = 'Clark',
  [0xc] = 'Athena',
  [0xd] = 'Kensou',
  [0xe] = 'Chin',
  [0xf] = 'Chizuru',
  [0x10] = 'Mai',
  [0x11] = 'King',
  [0x12] = 'Kim',
  [0x13] = 'Chang',
  [0x14] = 'Choi',
  [0x15] = 'Yashiro',
  [0x16] = 'Shermie',
  [0x17] = 'Chris',
  [0x18] = 'Yamazaki',
  [0x19] = 'Mary',
  [0x1a] = 'Billy',
  [0x1b] = 'Iori',
  [0x1c] = 'Mature',
  [0x1d] = 'Vice',
  [0x1e] = 'Heidern',
  [0x1f] = 'Takuma',
  [0x20] = 'Saisyu',
  [0x21] = 'Heavy D',
  [0x22] = 'Lucky',
  [0x23] = 'Brian',
  [0x24] = 'Rugal',
  [0x25] = 'Shingo',
}

local function printPlayer(base)
	local offset = 113
	local readvalue = readByte(base + offset)
	local chara = chara_table[readvalue]
	print("character receiving damage? "..chara)
end
	 
local function getDamage(player, hitting_player)
	local current = player.health.current
	local previous = player.health.previous
	local damage = player.damage.hit
	if (previous > current) then
		damage = math.abs(previous - current)
		-- file to write
		file = io.open("sound_output.txt", "w")
		io.output(file)
		local soundOutput = hitting_player.charaName .. " hits ".. player.charaName .. damage
		print(soundOutput)
		io.write(soundOutput)
		-- closes the open file
		io.close(file)
	end
	return damage
end

local function checkMaxValue(value, max)
	if value > max then
		value = 0
	end
	return value
end

function player.recoverLife(player)
	local data = player.game.data
	local base = getBase(player.number, player.game)
	local enabled = player.game.cheats.health.enabled
	local mode = player.game.cheats.health.mode
	local address = player.game.cheats.health.address
	local value = player.game.cheats.health.value
	local max = player.game.cheats.health.max
	local current = player.health.current 

	if enabled then 
		if mode == "refill" then
			if current <= value then
				writeWord(base + address, max)
			end
		elseif mode == "fixed" then
			writeWord(base + address, value)
		end
	end
end

function player.enableCheats(game)
	local cheats = game.cheats

	for k, v in pairs(cheats) do
		local address = v.address
		local value = v.value

		if v.enabled and k ~= "health" then
			writeByte(address, value)
		end
	end
end

function player.set(player, key, value)
	player[key] = value
end 

function player.getNumber(player)
	return player.number
end 

function player.getGameData(player)
	return player.game.data
end 

function player.update(player, player2)
	local data = player.game.data
	local base = getBase(player.number, player.game)
	player.side = data.side(base)
	local charId = data.charId(base)
	player.charId = charId
	local charaName = chara_table[player.charId]
	player.charaName = charaName
	player.health.previous = player.health.current
	player.health.current = checkMaxValue(data.health.value(base), data.health.max)
	
	player.damage.hit = checkMaxValue(getDamage(player, player2), data.damage.max)

	player.guard.previous = player.guard.current
	player.guard.current = data.guard.value(base)
	
	player.stun.previous = player.stun.current
	player.stun.current = checkMaxValue(data.stun.value(base), data.stun.max)

	player.super.value = data.super.value(base)
	player.super.timeout = data.super.timeout.value(base)
end

return player