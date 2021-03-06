using Libdl,WignerD

function wig3j(j2,j3,m2,m3)
	
	m2,m3 = Int32(m2),Int32(m3)
	m1 = Int32(m2 + m3)

	j2,j3 = Int32(j2),Int32(j3)
	len = Int32(j2+j3+1)

	exitstatus = zero(Int32)

	w3j = zeros(Float64,len)

	lib=Libdl.dlopen(joinpath(dirname(pathof(WignerD)),"shtools_wrapper.so"))
	sym=Libdl.dlsym(lib,:wigner3j_wrapper)

	ccall(sym,Cvoid,
		(Ref{Float64}, 	#w3j
			Ref{Int32},	#len
			# Ref{Int32},	#jmin
			# Ref{Int32},	#jmax
			Ref{Int32},	#j2
			Ref{Int32},	#j3
			Ref{Int32},	#m1
			Ref{Int32},	#m2
			Ref{Int32},	#m3
			Ref{Int32}),#exitstatus
		w3j,len, j2, j3, m1, m2,m3, exitstatus)

	Libdl.dlclose(lib)
	
	return w3j
end