ardour {                                                                                                                                                      
    ["type"]    = "EditorAction",                                                                                                                               
    name        = "AJ_JSiX Assign Channels",                                                                                                                    
    description = "Assign sequential Bank/Channel to all aj-ysfx instances"                                                                                     
  }                                                                                                                                                             
                                                                                                                                                                
  function factory()                                                                                                                                            
    return function()
                                                                                                                                                                
      local counters = { mono_st = 1, dm = 1 }                                                                                                                  
      local MAX      = { mono_st = 64, dm = 32 }
                                                                                                                                                                
      local function param_name(plugin, j)
        local n = "?"
        pcall(function() n = plugin:parameter_label(j) end)
        return n                                                                                                                                                
      end
                                                                                                                                                                
      local function detect_variant(plugin)
        local p0 = param_name(plugin, 0)
        local p1 = param_name(plugin, 1)
        if p0:find("Drive", 1, true) then return "mb"      end
        if p1:find("Left",  1, true) then return "dm"      end                                                                                                  
        return "mono_st"
      end                                                                                                                                                       
                  
      local function assign(pi, variant)
        local c = counters[variant]
        local bank, ch, bank_norm, ch_norm, ch_display                                                                                                          
   
        if variant == "dm" then                                                                                                                                 
          bank       = math.floor((c - 1) / 4)
          ch         = (c - 1) % 4
          bank_norm  = bank / 7                                                                                                                                 
          ch_norm    = ch   / 3
          ch_display = ch * 2 + 1                                                                                                                               
        else      
          bank       = math.floor((c - 1) / 8)
          ch         = (c - 1) % 8                                                                                                                              
          bank_norm  = bank / 7
          ch_norm    = ch   / 7                                                                                                                                 
          ch_display = ch + 1
        end

        local ok0 = ARDOUR.LuaAPI.set_plugin_insert_param(pi, 0, bank_norm)                                                                                     
        local ok1 = ARDOUR.LuaAPI.set_plugin_insert_param(pi, 1, ch_norm)
                                                                                                                                                                
        counters[variant] = (c % MAX[variant]) + 1                                                                                                              
        return bank + 1, ch_display, ok0 and ok1
      end                                                                                                                                                       
                  
      local routes = Session:get_routes()
      local assigned = 0

      for route in routes:iter() do
        if route:is_master() or route:is_monitor() then goto continue_route end
                                                                                                                                                                
        local i = 0
        repeat                                                                                                                                                  
          local proc = route:nth_plugin(i)
          if proc:isnil() then break end

          local pi = proc:to_insert()                                                                                                                           
          if not pi:isnil() then
            local plugin = pi:plugin(0)                                                                                                                         
            if not plugin:isnil() and plugin:label() == "aj-ysfx" then
              local variant = detect_variant(plugin)
              if variant ~= "mb" then
                local bank, ch, ok = assign(pi, variant)                                                                                                        
                print(string.format("[%s]  %-25s  %s  Bank %-2d  Ch %d",
                  ok and "assigned" or "FAILED",                                                                                                                
                  route:name(), variant, bank, ch))
                assigned = assigned + 1                                                                                                                         
              else
                print(string.format("[skip-mb]  %s", route:name()))                                                                                             
              end 
            end
          end

          i = i + 1
        until false

        ::continue_route::                                                                                                                                      
      end
                                                                                                                                                                
      print(string.format("\nAssigned: %d", assigned))
    end
  end