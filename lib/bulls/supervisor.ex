# For creating the supervisor
# Based on Tuck's scratch
defmodule Bulls.Sup do 
    def start_child(spec) do 
        DynamicSupervisor.start_child(__MODULE__, spec);
    end 
end 