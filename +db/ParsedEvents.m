classdef ParsedEvents < handle
properties
	States
	Events
end

methods
	function obj = ParsedEvents(pe_struct)
		obj.States = pe_struct.States;
		obj.Events = pe_struct.Events;
	end

	function [stateslist, pokeslist] = getStatePokes(obj)
		stateslist = fieldnames(obj.States);
		all_pokes = getPokeList;

		for sx = 1:
	end

	function eventslist = getStates(obj)
		stateslist = fieldnames(obj.States)
	end
	