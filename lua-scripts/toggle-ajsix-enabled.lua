ardour {                                                                                                                                                      
    ["type"]    = "EditorAction",                                                                                                                             
    name        = "AJ_JSiX Toggle Enabled",                                                                                                                     
    description = "Toggle enabled/disabled for all aj-ysfx instances (including MB)"                                                                            
  }                                                                                                                                                             
                                                                                                                                                                
  function factory()                                                                                                                                          
    return function()

      -- Collect all aj-ysfx PluginInsert processors
      local inserts = {}
      local routes  = Session:get_routes()
                                                                                                                                                                
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
              table.insert(inserts, { pi = pi, route = route:name() })                                                                                          
            end
          end                                                                                                                                                   
                                                                                                                                                              
          i = i + 1
        until false

        ::continue_route::
      end

      if #inserts == 0 then
        print("No aj-ysfx instances found.")
        return                                                                                                                                                  
      end
                                                                                                                                                                
      -- If any instance is active, deactivate all; otherwise activate all.                                                                                   
      local any_active = false
      for _, entry in ipairs(inserts) do
        if entry.pi:active() then any_active = true; break end
      end                                                                                                                                                       
   
      local action = any_active and "disable" or "enable"                                                                                                       
      local count  = 0                                                                                                                                        

      for _, entry in ipairs(inserts) do
        if any_active then
          entry.pi:deactivate()
        else                                                                                                                                                    
          entry.pi:activate()
        end                                                                                                                                                     
        print(string.format("[%s]  %s", action, entry.route))                                                                                                 
        count = count + 1
      end

      print(string.format("\n%s: %d instances", action, count))                                                                                                 
    end
  end         