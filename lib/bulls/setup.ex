# Setups the supervisor and children
# Based on Tuck's scratch
defmodule Bulls.Setup do 
    use Supervisor

    def start_link(_arg) do 
        Supervisor.start_link(__MODULE__, :ok);
    end 

    @impl true 
    def init(:ok) do
        children = [
            {Registry, name: Bulls.Registry, keys: :unique},
            {DynamicSupervisor, name: Bulls.Sup, strategy: :one_for_one}
        ]
        Supervisor.init(children, strategy: :one_for_one)
    end 
end 