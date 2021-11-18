defmodule QueueInterface do

	def handle_call(:healthCheck, _from, {consumers}) do
		{:reply, :healthCheck, {consumers}}
	end

	def handle_call({:addConsumer, consumer}, _from, {consumers}) do
		{:reply, :ok, {consumers ++ [consumer]}}
	end

	def handle_call(:getConsumers, _from, {consumers}) do
		{:reply, consumers, {consumers}}
	end

end