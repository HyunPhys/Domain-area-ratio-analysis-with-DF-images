function opts = setDefault(opts,field,val)
if ~isfield(opts,field), opts.(field)=val; end
end