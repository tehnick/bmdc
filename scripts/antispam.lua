--based on some parts of lwolf's & BottledHate's scripts, created by Patch for both ApexDC++ and BCDC++

local pmcount = 0
local totalpmcount = 0
local ignorelist = 0
local nicklist = 0
local favnick
local client = 0
local text
local text1
local nick
local nick
local nicks
local action
filterfile = GetConfigPath() .. "scripts/Filter.txt"
settingsfile = GetConfigPath() .. "scripts/Filtersettings.txt"
spamsfile = GetConfigPath() .. "scripts/Filterspams.txt"
nicksfile = GetConfigPath() .. "scripts/Filternicks.txt"
ignorelistfile = GetConfigPath() .. "DCPlusPlus.xml"
historyfile = GetConfigPath() .. "scripts/Filterhistory.txt"
--reneuwing and (or) loading reneuwing the needed files
f = io.open(spamsfile, "w+")
if f then
	f:write(" This file contains all filtered PM's text and sender's nick. Generated by antispam filter v1.2")
	f:write("\n Ez a fájl tartalmazza a spamek szövegét. Antispam filter v1.2 \n\n")	
	f:close()
else
	PrintDebug("Scripts/Filterspams.txt not accessible")
end

f = io.open(historyfile, "w+")
if f then
	f:write("Script actions history:")
	f:close()
else
	PrintDebug("Scripts\Filterhistory.txt not accessible")
end

f = io.open(filterfile, "r")
if f then
	f:close()
else
	f = io.open(filterfile, "w+")
	f:write("This file contains the filtering words")
	f:write("\nwww")
	f:write("\n/fav")
	f:write("\ndchub://")
	f:write("\nhttp://")
	f:write("\nflood")
	f:close()
	PrintDebug("Scripts/Filter.txt is generated")
end

f = io.open(settingsfile, "r")
if f then
	f:close()
else
	f = io.open(settingsfile, "w+")
	f:write("copytext")
	f:write("\n	copytextvalue='0'")
	f:write("\n/copytext")
	f:write("\nspamfilter")
	f:write("\n	spamfiltervalue='1'")
	f:write("\n/spamfilter")
	f:write("\nmaxlen")
	f:write("\n	maxlenvalue='240'")
	f:write("\n/maxlen")
	f:write("\nignorefromlist")
	f:write("\n	ignorefromlistvalue='1'")
	f:write("\n/ignorefromlist")
	f:write("\nnickfiltering")
	f:write("\n	nickfilteringvalue='1'")
	f:write("\n/nickfiltering")
	f:close()
	PrintDebug("Scripts/Filtersettings.txt is generated")
end

f = io.open(nicksfile, "r")
if f then
	f:close()
else
	f = io.open(nicksfile, "w+")
	f:write("This file contain the unwanted things in nicks, you can simply write your own words to the end of the file")
	f:write("\nbot")
	f:write("\nBOT")
	f:close()
	PrintDebug("Scripts/Filternicks.txt is generated")
end
	
--determinating witch client running, looking for Favorites.xml
Favorites = io.open(GetConfigPath() .. "/Favorites.xml")
if not Favorites then
	Favorites = GetConfigPath() .. "/Favorites.xml"
	ignorelistfile = GetConfigPath() .. "/DCPlusPlus.xml"
	Favorites = io.open(GetConfigPath() .. "/Favorites.xml")
	if not Favorites then
		fav = 0
	else
		Favorites = GetConfigPath() .. "/Favorites.xml"
		fav = 1
	end	
else
	Favorites:close()
	Favorites = GetConfigPath() .. "/Favorites.xml"
	ignorelistfile = GetConfigPath() .. "/DCPlusPlus.xml"
	fav = 1
end


--load settings from the settings file
for line in io.lines(settingsfile) do
	if string.find(line, "/spamfilter") then
		start = 0
	elseif start == 1 then
		a,b,spamfilter1 = string.find(line, "spamfiltervalue=\'(.-)\'")
		spamfilter = tonumber(spamfilter1)
	elseif string.find(line, "spamfilter") then
		start = 1
	end
end
for line in io.lines(settingsfile) do
	if string.find(line, "/maxlen") then
		start = 0
	elseif start == 1 then
		a,b,maxlen1 = string.find(line, "maxlenvalue=\'(.-)\'")
		maxlen = tonumber(maxlen1)
	elseif string.find(line, "maxlen") then
		start = 1
	end
end
for line in io.lines(settingsfile) do
	if string.find(line, "/ignorefromlist") then
		start = 0
	elseif start == 1 then
		a,b,ignorefromlist1 = string.find(line, "ignorefromlistvalue=\'(.-)\'")
		ignorefromlist = tonumber(ignorefromlist1)
	elseif string.find(line, "ignorefromlist") then
		start = 1
	end
end
for line in io.lines(settingsfile) do
	if string.find(line, "/nickfiltering") then
		start = 0
	elseif start == 1 then
		a,b,nickfiltering1 = string.find(line, "nickfilteringvalue=\'(.-)\'")
		nickfiltering = tonumber(nickfiltering1)
	elseif string.find(line, "nickfiltering") then
		start = 1
	end
end

if not antispamcontrol then
	antispamcontrol = {}
end

function antispamcontrol.tokenize( str )
	local ret = {}
	string.gsub( str, "([^ ]+)", function( s ) table.insert( ret, s ) end )
	return ret
end

--control interface
dcpp:setListener("ownChatOut", "antispamcontrol",
function( hub, message, ret )
	--if string.sub( message, 1, 1) ~= "/" then
		--return nil
	--end
	local params = antispamcontrol.tokenize( message )
	if params[1] == "/antispam" then
		hub:addLine(" ")
		hub:addLine("       ------------------------------------------------------------------------------------------------------------------------------------------------------", true)
		hub:addLine("       Contorl Commands                                        Anti-spam filter v1.2", true)
		hub:addLine("       ------------------------------------------------------------------------------------------------------------------------------------------------------", true)
		hub:addLine("       /antispam or				Displays this help", true)
		hub:addLine("       /as wlist				Lists the words currently added to the Filter.txt", true)
		hub:addLine("       /as nicklist				Lists the words currently added to the Filternicks.txt", true)
		--hub:addLine("       /as settings				Display the current settings", true)
		hub:addLine("       /as on				Turns on the filtering", true)
		hub:addLine("       /as off				Turns off the filtering", true)
		hub:addLine("       /as texttomain on			Turns on spam text injecting", true)
		hub:addLine("       /as texttomain off			Turns off spam text injecting", true)
		hub:addLine("       /as addword [word]			Add a word between [] to the Filter.txt - script will seek for that word in PM's", true)
		hub:addLine("       /as addnick [nick]			Add a nick between [] to the Filternicks.txt - ignore PM's from that nick", true)
		hub:addLine("       /as readspam [number]			Display the spam's text", true)
		hub:addLine("       /as history				Display the script all actions", true)		
		hub:addLine("       ------------------------------------------------------------------------------------------------------------------------------------------------------", true)
		hub:addLine("       Current settings:", true)
		hub:addLine("       1 means online, 0 means offline", true)
		hub:addLine("       Filtering: " ..spamfilter.. " ", true)
		hub:addLine("       Ignore nick from list " ..ignorefromlist.. " ", true)
		hub:addLine("       Max allowed line in PM's " ..maxlen.. " ", true)
		hub:addLine("       ------------------------------------------------------------------------------------------------------------------------------------------------------", true)
		hub:addLine("       Current state:", true)
		hub:addLine("       TotalPM: " ..totalpmcount.. " ", true)
		hub:addLine("       Blocked SPAM: " ..pmcount.. " ", true)
		hub:addLine("       Ignored (ignorelist): " ..ignorelist.. " ", true)
		hub:addLine("       Ignored (nicklist): " ..nicklist.. " ", true)
		hub:addLine("       ------------------------------------------------------------------------------------------------------------------------------------------------------", true)
		return 1
	end	
	if params[1] == "/as" then
		if params[2] == "wlist" then
			f = io.open(filterfile, "r")
					if f then
						hub:addLine(" Filtering words: ")
						local line = f:read()
						hub:addLine(" ")						
						while line do
							line = f:read()
							if not (line == nil) then
								hub:addLine(" " .. line .. " ")
							end		
						end
					end
			hub:addLine(" ")
			f:close()
			return 1
			end
		if params[2] == "nicklist" then
			f = io.open(nicksfile, "r")
					if f then
						hub:addLine(" Ignored nicks: ")
						local line = f:read()
						hub:addLine(" ")						
						while line do
							line = f:read()
							if not (line == nil) then
								hub:addLine(" " .. line .. " ")
							end		
						end
					end
			hub:addLine(" ")
			f:close()
			return 1
			end
		if params[2] == "history" then
		f = io.open(historyfile, "r")
					if f then
						hub:addLine(" Antispam history: ")
						local line = f:read()
						hub:addLine(" ")
						while line do
							line = f:read()
							if not (line == nil) then
									line1 = FromUtf8(line)
									hub:addLine(" " .. line1 .. " ")
							end		
						end
					end	
			f:close()
			return 1
			end
		if	params[2] == "addword" then
			f = io.open(filterfile, "a+")
			if f then
				f:write("\n")
				local word=FromUtf8(params[3])
				f:write(word)
				f:close()
				hub:addLine("       Word " ..word.. " added to Filter.txt", true)
			return 1
			end
		end
		if	params[2] == "addnick" then
			f = io.open(nicksfile, "a+")
			if f then
				f:write("\n")
				local addnick=FromUtf8(params[3])
				f:write(addnick)
				f:close()
				hub:addLine("       Nick " ..addnick.. " added to Filternicks.txt", true)
			return 1
			end
		end
		if	params[2] == "on" then
			if spamfilter == 1 then
				hub:addLine("       Antispam filtering already ONLINE", true)
				return 1
			else
				hub:addLine("       Antispam filtering ONLINE - default", true)
				spamfilter = 1
				PrintDebug( "  Anti-spam filter back online")
				return 1
			end	
		end
		if	params[2] == "off" then
			if spamfilter == 1 then
				hub:addLine("       Antispam filtering OFFLINE", true)
				spamfilter = 0
				PrintDebug( "  Anti-spam filter temporaly offline")
				return 1
			else
				hub:addLine("       Antispam filtering already OFFLINE", true)
				return 1
			end	
		end
		if	params[2] == "texttomain" and params[3] == "on" then
			if copytext == 1 then
				hub:addLine("       Spam text to main chat function already ONLINE", true)
				return 1
			else
				hub:addLine("       Spam text to main chat function temporaly ONLINE", true)
				copytext = 1
				PrintDebug( "  Spam text to main chat function temporaly online")
				return 1
			end	
		end	
		if	params[2] == "texttomain" and params[3] == "off" then
			if copytext == 1 then
				hub:addLine("       Spam text to main chat function OFFLINE - default", true)
				copytext = 0
				PrintDebug( "  Spam text to main chat function offline")
				return 1
			else
				hub:addLine("       Spam text to main chat function already OFFLINE - default", true)
				return 1
			end	
		end
		if params[2] == "readspam" then
			if params[3] == nil then
				PrintDebug("A number needed...")
				return 1
			end	
			spamnumber = params[3]
			local f = io.open(GetConfigPath() .. "scripts/Filterspams.txt", "r")
			if f then
				local line = f:read()
				for line in f:lines() do
					if string.find(line, "SPAM ") then
						if string.find(line, spamnumber) then
							start = 1 
							if string.find(line, "END") then
								start = 0
								PrintDebug("Spam " .. spamnumber .. " readed")
								return 1
							end		
						end
					end
					if start == 1 then
						hub:addLine(line, true)
					end	
					end
				end
				f:close()
				return 1
			end
		end
end
)

if not antispam then
	antispam = {}
end

--hystory function
function antispam.historywrite()
	local f = io.open(historyfile, "a+")
	if f then
		f:write("\n")
		f:write(os.date())
		f:write(" - ")
		if action == 1 then
			f:write("SPAM")
		elseif action == 2 then
			f:write("LongPM")
		elseif action == 3 then
			f:write("Ignored (nicklist)")
		elseif action == 4 then
			f:write("Ignored (ignorelist)")
		else
		end
		f:write(" - ")		
		f:write(nick)
		f:close()
	else
		PrintDebug("Filterhistory.txt is not accessible")
	end	
end

function antispam.spamsfilewrite()
	if protocol == "ADC" then
		--text1 = ToUtf8(text1)
	else
		--text1 = FromUtf8(text1)
	end	
	spamsfile = io.open(GetConfigPath() .. "scripts/Filterspams.txt", "a+")
	if spamsfile then
		spamsfile:write("\nSPAM ")
		spamsfile:write(pmcount)	
		spamsfile:write("\n --------------------------------------------- \n\n")									
		spamsfile:write("Nickname: ")									
		spamsfile:write(nick)
		spamsfile:write("\nProt: ")
		spamsfile:write(protocol)
		spamsfile:write("\nHub Name: ")
		spamsfile:write(hub1)
		spamsfile:write("\n")
		spamsfile:write(os.date())
		if spamtype == normal then
			spamsfile:write("\nText: -normal PM- \n")
		else
			spamsfile:write("\nText: -Hub PM- \n")
		end	
		spamsfile:write(text1)
		spamsfile:write("\n\nSPAM ")
		spamsfile:write(pmcount)
		spamsfile:write(" END ")
		spamsfile:write("\n")		
		spamsfile:close()
	end	
end

function antispam.lenght()
	newline = 0
	len = string.len(text1)
	if not len == nil then
		if len > maxlen then
			if copytext == 1 then
				hub:addLine("PM " .. pmcount .. " too long PM from: "  .. nick .." **" )
				hub:injectChat("PM " .. pmcount .. " text: "  .. text .." **" )
			end
			pmcount = pmcount + 1
			PrintDebug( "  ** " .. "PM " .. pmcount .. " blocked *too long pm* from: "  .. nick .." **" )
			action = 2
			antispam.historywrite()
			antispam.spamsfilewrite()
			ret = 1
		end
	end
end

function antispam.ignore()
ignoreTable = {}
	for line in io.lines(ignorelistfile) do
			if string.find(line, "</IgnoreList>") then
				start = 0
			elseif start == 1 then
				a,b,ignorenick = string.find(line, "Nick=\"(.-)\"")
				ignoreTable[ignorenick] = 1
			elseif string.find(line, "<IgnoreList>") then
				start = 1
			end
	end
	if ignoreTable[nick] then
		PrintDebug( " ".. nick .. " is ignored - by ignorelist")
		action = 4
		ignorelist = ignorelist + 1
		totalpmcount = totalpmcount + 1
		antispam.historywrite()
		ret = 1
	end
end	

function antispam.nickfiltering()
n = io.open(nicksfile, "r")
	if n then
		nicks = n:read()
		while 1 do
			nicks = n:read()
			if nicks == nil then break
			else
			if string.find(nick, nicks ) then
				PrintDebug(" ".. nick .. " is ignored - by nicklist")
				action = 3
				nicklist = nicklist + 1
				totalpmcount = totalpmcount + 1			
				antispam.historywrite()
				ret = 1
				break
			end
			end
		end
	end
n:close()
end

function antispam.filter()
pmTable = {}
if fav == 1 then
	for line in io.lines(Favorites) do
		if string.find(line, "</Users>") then
			start = 0
		elseif start == 1 then
			a,b,favnick = string.find(line, "Nick=\"(.-)\"")
			pmTable[favnick] = 1
		elseif string.find(line, "<Users>") then
			start = 1
		end
	end
end	
if not pmTable[nick] then	
	local f = io.open(filterfile, "r")
	if f then
		line = f:read()
		while line do
			line = f:read()
			if not (line == nil) then
				if string.find(text1, line ) then
					pmcount = pmcount + 1
					totalpmcount = totalpmcount + 1
					PrintDebug( "  ** " .. "PM " .. pmcount .. " blocked *SPAM* from: "  .. nick .." **" )
					action = 1
					antispam.historywrite()
					antispam.spamsfilewrite()
					ret = 1
					break
				end
			end		
		end
		f:close()
		if string.find(text1,'\n') then
			antispam.lenght()	
		end
	else
		PrintDebug( "  ** Filter.txt is not present in /acripts folder or not acessible!!! **" )
	end
else		
	totalpmcount = totalpmcount + 1
end
end	
--hubPM event
dcpp:setListener( "hubPm", "pmlistener",
function( hub, user, text )
hub1 = hub:getHubName()
nick = user:getNick()
text1 = text
protocol = hub:getProtocol()
ret = 0
spamtype = hub
if ignorefromlist == 1 then
	antispam.ignore()
	if ret == 1 then
		ret = 0	
		return 1
	end
end
if nickfiltering == 1 then
	antispam.nickfiltering()
	if ret == 1 then
		ret = 0	
		return 1
	end	
end					
if spamfilter == 1 then
	antispam.filter()
	if ret == 1 then
		ret = 0	
		return 1
	end		
	end
end	
)

-- ordinary PM event
dcpp:setListener( "pm", "pmlistener",
function( hub, user, text )
hub1 = hub:getHubName()
nick = user:getNick()
text1 = text
protocol = hub:getProtocol()
ret = 0
spamtype = normal
if ignorefromlist == 1 then
	antispam.ignore()
	if ret == 1 then
		ret = 0
		return 1
	end
end
if nickfiltering == 1 then
	antispam.nickfiltering()
	if ret == 1 then
		ret = 0	
		return 1
	end	
end					
if spamfilter == 1 then
	antispam.filter()
	if ret == 1 then
		ret = 0	
		return 1
	end		
	end
end	
)
PrintDebug("  ** Loaded anti-spam filter v1.2 **") 
