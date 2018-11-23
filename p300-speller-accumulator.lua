
function arrayMax(a)
    if #a == 0 then return nil, nil end
    local maxIdx, maxValue = 0, a[0]
    for i = 1, (#a -1 ) do
        if maxValue < a[i] then
            maxIdx, maxValue = i, a[i]
        end
    end
    return maxIdx, maxValue
end

-- For handling target fifo

List = {}
function List.new ()
	return {first = 0, last = -1}
end

function List.pushright (list, value)
	local last = list.last + 1
	list.last = last
	list[last] = value
end

function List.popleft (list)
	local first = list.first
	if first > list.last then
		error("list is empty")
	end
	local value = list[first]
	list[first] = nil        -- to allow garbage collection
	list.first = first + 1
	return value
end

function List.isempty (list)
	if list.first > list.last  then
		return true
	else
		return false
	end
end

local serverudp

-- this function is called when the box is initialized
function initialize(box)

	dofile(box:get_config("${Path_Data}") .. "/plugins/stimulation/lua-stimulator-stim-codes.lua")

	row_base = _G[box:get_setting(2)]
	col_base = _G[box:get_setting(3)]
	segment_start = _G[box:get_setting(4)]
	segment_stop = _G[box:get_setting(5)]

	-- 0 inactive, 1 segment started, 2 segment stopped (can vote)
	segment_status = 0

	-- the idea is to push the flash states to the fifo, and when predictions arrive (with some delay), they are matched in oldest-first fashion.
	target_fifo = List.new()

	-- box:log("Info", string.format("pop %d %d", id[1], id[2]))

	row_votes = {}
	col_votes = {}

	do_debug = true


  socket = require('socket')
  print(socket._VERSION)

  serverudp = socket.udp()
  serverudp:setsockname("*", 7788)
  serverudp:settimeout(0)

end

-- this function is called when the box is uninitialized
function uninitialize(box)
  local host, port = "10.17.2.54", 7788
  -- load namespace
  -- convert host name to ip address
  local ip = assert(socket.dns.toip(host))
  -- create a new UDP object
  local udp = assert(socket.udp())
  -- contact daytime host
  assert(udp:sendto("finishplot", ip, port))
  -- retrieve the answer and print results
end

function flushbuffer()
  serverudp:settimeout(1)
  val, ips, ports = serverudp:receivefrom()
  while true do
    serverudp:settimeout(1)
    val, ips, ports = serverudp:receivefrom()
    if (val == nil) or string.len(val)<=0 then
      break
    end
  end
end

function process(box)
	-- loops until box is stopped
	while box:keep_processing() do

		-- first, parse the timeline stream
		for stimulation = 1, box:get_stimulation_count(2) do
			-- gets the received stimulation
			local identifier, date, duration = box:get_stimulation(2, 1)
      -- gets stimulation
			box:log("Info", string.format("Stimulation %010x,%5.0f at %f (now = %f)", identifier, identifier, date, duration))

			-- discards it
			box:remove_stimulation(2, 1)

			if identifier == segment_start then
				if do_debug then
					box:log("Info", string.format("Trial start"))
					box:log("Info", string.format("Clear votes"))
				end
				-- zero the votes

				target_fifo = List.new()

				segment_status = 1
			end

			-- Does the identifier code a flash? if so, put into fifo
			if segment_status == 1 and identifier >= row_base and identifier <= OVTK_StimulationId_LabelEnd then
        box:log("Info", string.format("Label"))

			end

			if identifier == segment_stop then
				if do_debug then
					box:log("Info", string.format("Trial stop"))
				end
				segment_status = 2
			end

		end


		if segment_status == 2 and List.isempty(target_fifo) then
			-- output the vote after the segment end when we've matched all predictions

			-- local maxRowIdx, maxRowValue = arrayMax(row_votes)
			-- local maxColIdx, maxColValue = arrayMax(col_votes)
      --
			-- if maxRowValue == 0 and maxColValue == 0 then
			-- 	box:log("Warning", string.format("Classifier predicted 'no p300' for all flashes of the trial"));
			-- end
      --
			-- if do_debug then
			-- 	local rowVotes = 0
			-- 	local colVotes = 0
			-- 	for ir, val in pairs(row_votes) do
			-- 		rowVotes = rowVotes + val
			-- 	end
			-- 	for ir, val in pairs(col_votes) do
			-- 		colVotes = colVotes + val
			-- 	end
      --
			-- 	box:log("Info", string.format("Vote [%d %d] wt [%d,%d]", maxRowIdx+row_base, maxColIdx+col_base, maxRowValue, maxColValue))
			-- 	box:log("Info", string.format("  Total [%d %d]", rowVotes, colVotes))
			-- end


      --client=socket.tcp()
      --client:connect('www.itba.edu.ar', 80)
      --cookie=client:receive()
      --print(cookie)

      flushbuffer()

      -- change here to the host an port you want to contact
      local host, port = "10.17.2.54", 7788
      -- load namespace
      -- convert host name to ip address
      local ip = assert(socket.dns.toip(host))
      -- create a new UDP object
      local udp = assert(socket.udp())
      -- contact daytime host
      assert(udp:sendto("1", ip, port))
      -- retrieve the answer and print results



      retries = 0
      while retries < 10 do
        assert(udp:sendto("1", ip, port))
        -- retrieve the answer and print results
        -- udp:settimeout(10+retries)

        serverudp:settimeout(10+retries)
        val, ips, ports = serverudp:receivefrom()

        --val = udp:receive()
        --box:log("Info", val)
        if (val ~= nil) and string.len(val)>0 then
          break
        end
        retries = retries + 1
        --box:log("Info", string.format('Retrying %d',retries))
        box:sleep()

      end

      if (val ~= nil) and string.len(val)>0 then

        --box:log("Info", string.sub(val,2,3))
        --box:log("Info", string.sub(val,5,6))

        --val = tonumber(val)
        r = tonumber(string.sub(val,2,3))
        c = tonumber(string.sub(val,5,6))
      else
        r = 0
        c = 0
      end

      box:log("Info", string.format('%d,%d',r,c))
      assert(udp:sendto("2", ip, port))

			local now = box:get_current_time()

			--box:send_stimulation(1, maxRowIdx + row_base, now, 0)
			--box:send_stimulation(2, maxColIdx + col_base, now, 0)

      box:send_stimulation(1, r + row_base, now, 0)
      box:send_stimulation(2, c + col_base, now, 0)

			segment_status = 0
		end

		box:sleep()
	end
end
