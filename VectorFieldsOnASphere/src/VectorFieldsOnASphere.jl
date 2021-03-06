module VectorFieldsOnASphere

using LabelledArrays

import LinearAlgebra: norm,normalize
import Base: +,-,*,/,==,≈

export +,-,*,/,==,≈

using PointsOnASphere

export CartesianVector,SphericalVector,HelicityVector,SphericalPolarVector,unitvector

abstract type VectorField end

const vector_types = (:CartesianVector,:SphericalVector,:SphericalPolarVector,:HelicityVector)

const cartesian_components = @SLVector Float64 (:x,:y,:z)
const spherical_components = @SLVector ComplexF64 (:p, :z, :m)
const spherical_polar_components = @SLVector Float64 (:r, :θ, :ϕ)
const helicity_components = @SLVector ComplexF64 (:p, :z, :m)

# Vector fields evaluated at a point
struct CartesianVector <: VectorField
	components :: AbstractArray
	pt::Point3D
end

struct SphericalVector <: VectorField
	components :: AbstractArray
	pt::Point3D
end

struct SphericalPolarVector <: VectorField
	components :: AbstractArray
	pt::Point3D
end

struct HelicityVector <: VectorField
	components :: AbstractArray
	pt::Point3D
end

const complex_basis = Union{SphericalVector,HelicityVector}
const real_basis = Union{CartesianVector,SphericalPolarVector}
const fixed_basis = Union{CartesianVector,SphericalVector}
const rotating_basis = Union{SphericalPolarVector,HelicityVector}

const CtoS = [-1/√2	im/√2	0
		 0		0		1
		 1/√2	im/√2	0]

const StoC = CtoS'
const SPtoH = CtoS
const HtoSP = StoC

# Matrix to transform from cartesian to spherical coordinates
function CartesianToSpherical(v::CartesianVector)
	components = cartesian_components(CtoS*v.components...)
	SphericalVector(components,v.pt)
end

function CartesianToSphericalPolar(v::CartesianVector)
	M = [sin(v.pt.θ)cos(v.pt.ϕ)	cos(v.pt.θ)cos(v.pt.ϕ)	-sin(v.pt.ϕ)
		 sin(v.pt.θ)sin(v.pt.ϕ)	cos(v.pt.θ)sin(v.pt.ϕ)	cos(v.pt.ϕ)
		 cos(v.pt.θ)			-sin(v.pt.θ)					0]'

	components = spherical_polar_components(M*v.components...)
	SphericalPolarVector(components,v.pt)
end

CartesianToHelicity(v::CartesianVector) = SphericalPolarToHelicity(CartesianToSphericalPolar(v))

function SphericalToCartesian(v::SphericalVector)
	components = cartesian_components(real.(StoC*v.components)...)
	CartesianVector(components,v.pt)
end

function SphericalToSphericalPolar(v::SphericalVector)
	M = [-sin(v.pt.θ)cis(-v.pt.ϕ)/√2	-cos(v.pt.θ)cis(-v.pt.ϕ)/√2	im/√2*cis(-v.pt.ϕ)
		 cos(v.pt.θ)			-sin(v.pt.θ)					0
		 sin(v.pt.θ)cis(v.pt.ϕ)/√2	cos(v.pt.θ)cis(v.pt.ϕ)/√2	im/√2*cis(v.pt.ϕ)]'

	components = spherical_polar_components(real.(M*v.components)...)
	SphericalPolarVector(components,v.pt)
end

SphericalToHelicity(v::SphericalVector) = SphericalPolarToHelicity(SphericalToSphericalPolar(v))

function SphericalPolarToCartesian(v::SphericalPolarVector)
	M = [sin(v.pt.θ)cos(v.pt.ϕ)	cos(v.pt.θ)cos(v.pt.ϕ)	-sin(v.pt.ϕ)
		 sin(v.pt.θ)sin(v.pt.ϕ)	cos(v.pt.θ)sin(v.pt.ϕ)	cos(v.pt.ϕ)
		 cos(v.pt.θ)			-sin(v.pt.θ)					0]

	components = M*v.components
	CartesianVector(components,v.pt)
end

function SphericalPolarToSpherical(v::SphericalPolarVector)
	M = [-sin(v.pt.θ)cis(-v.pt.ϕ)/√2	-cos(v.pt.θ)cis(-v.pt.ϕ)/√2	im/√2*cis(-v.pt.ϕ)
		 cos(v.pt.θ)			-sin(v.pt.θ)					0
		 sin(v.pt.θ)cis(v.pt.ϕ)/√2	cos(v.pt.θ)cis(v.pt.ϕ)/√2	im/√2*cis(v.pt.ϕ)]

	components = spherical_components(M*v.components...)
	SphericalVector(components,v.pt)
end

function SphericalPolarToHelicity(v::SphericalPolarVector)
	components = helicity_components(SPtoH*v.components...)
	HelicityVector(components,v.pt)
end

HelicityToCartesian(v::HelicityVector) = SphericalPolarToCartesian(HelicityToSphericalPolar(v))

HelicityToSpherical(v::HelicityVector) = SphericalPolarToSpherical(HelicityToSphericalPolar(v))

function HelicityToSphericalPolar(v::HelicityVector)
	components = spherical_polar_components(real.(HtoSP*v.components)...)
	SphericalPolarVector(components,v.pt)
end


# Assume radius vector by default if coordinates are not specified
SphericalPolarVector(x::Point3D) = SphericalPolarVector(spherical_polar_components(x.r,0,0),x)
# Assume point on unit sphere if distance from origin is not specified
SphericalPolarVector(n::Point2D) = SphericalPolarVector(spherical_polar_components(1,0,0),Point3D(1,n))

CartesianVector(x::SphericalPoint) = SphericalPolarToCartesian(SphericalPolarVector(x))
SphericalVector(x::SphericalPoint) = SphericalPolarToSpherical(SphericalPolarVector(x))
HelicityVector(x::SphericalPoint) = SphericalPolarToHelicity(SphericalPolarVector(x))

CartesianVector(v::CartesianVector) = v
CartesianVector(v::SphericalVector) = SphericalToCartesian(v)
CartesianVector(v::SphericalPolarVector) = SphericalPolarToCartesian(v)
CartesianVector(v::HelicityVector) = HelicityToCartesian(v)

HelicityVector(v::HelicityVector) = v
HelicityVector(v::CartesianVector) = CartesianToHelicity(v)
HelicityVector(v::SphericalVector) = SphericalToHelicity(v)
HelicityVector(v::SphericalPolarVector) = SphericalPolarToHelicity(v)

SphericalVector(v::SphericalVector) = v
SphericalVector(v::CartesianVector) = CartesianToSpherical(v)
SphericalVector(v::SphericalPolarVector) = SphericalPolarToSpherical(v)
SphericalVector(v::HelicityVector) = HelicityToSpherical(v)

SphericalPolarVector(v::SphericalPolarVector) = v
SphericalPolarVector(v::CartesianVector) = CartesianToSphericalPolar(v)
SphericalPolarVector(v::SphericalVector) = SphericalToSphericalPolar(v)
SphericalPolarVector(v::HelicityVector) = HelicityToSphericalPolar(v)

twoD_types = Union{Point2D,Tuple{<:Real,<:Real}}
threeD_types = Union{Point3D,Tuple{<:Real,<:Real,<:Real}}

CartesianVector(x,y,z,pt::threeD_types) = CartesianVector(cartesian_components(x,y,z),Point3D(pt))
SphericalVector(p,z,m,pt::threeD_types) = SphericalVector(spherical_components(p,z,m),Point3D(pt))
SphericalPolarVector(r,θ,ϕ,pt::threeD_types) = SphericalPolarVector(spherical_polar_components(r,θ,ϕ),Point3D(pt))
HelicityVector(p,z,m,pt::threeD_types) = HelicityVector(helicity_components(p,z,m),Point3D(pt))

CartesianVector(x,y,z,n::twoD_types) = CartesianVector(x,y,z,Point3D(1,n))
SphericalVector(p,z,m,n::twoD_types) = SphericalVector(p,z,m,Point3D(1,n))
SphericalPolarVector(r,θ,ϕ,n::twoD_types) = SphericalPolarVector(r,θ,ϕ,Point3D(1,n))
HelicityVector(p,z,m,n::twoD_types) = HelicityVector(p,z,m,Point3D(1,n))

for T in vector_types
	# Iterables
	@eval $(T)(v,n::SphericalPoint) = $(T)(v[1],v[2],v[3],n)
end

(==)(v1::T,v2::T) where T<:VectorField = v1 === v2
(≈)(v1::T,v2::T) where T<:VectorField = (v1.components ≈ v2.components) && (v1.pt === v2.pt)

norm(v::T) where T<:real_basis = norm(v.components)
function norm(v::T) where T<:complex_basis
	real(√( v.components.z^2 - 2v.components.p*v.components.m ))
end

normalize(v::T) where T<:real_basis = v/norm(v)

normalize(v::SphericalVector) = SphericalVector(normalize(CartesianVector(v)))
normalize(v::HelicityVector) = HelicityVector(normalize(SphericalPolarVector(v)))

unitvector(v::VectorField) = normalize(v)

(+)(v1::T,v2::T) where T<:fixed_basis = T(v1.components + v2.components,v1.pt)
(-)(v1::T,v2::T) where T<:fixed_basis = T(v1.components - v2.components,v2.pt)

function (+)(v1::T,v2::T) where T<:rotating_basis
	if v1.pt === v2.pt
		return T(v1.components + v2.components,v1.pt)
	elseif (v1.pt.θ == v2.pt.θ) && (v1.pt.ϕ == v2.pt.ϕ)
		# in this case the points are radially separated, 
		# and the basis vectors are aligned
		return T(v1.components + v2.components,v1.pt)
	else
		v1C = CartesianVector(v1)
		v2C = CartesianVector(v2)
		T(v1C + v2C)
	end
end

function (-)(v1::T,v2::T) where T<:rotating_basis
	if v1.pt === v2.pt
		return T(v1.components - v2.components,v2.pt)
	elseif (v1.pt.θ == v2.pt.θ) && (v1.pt.ϕ == v2.pt.ϕ)
		# in this case the points are radially separated, 
		# and the basis vectors are aligned
		return T(v1.components - v2.components,v2.pt)
	else
		v1C = CartesianVector(v1)
		v2C = CartesianVector(v2)
		T(v1C - v2C)
	end
end

# Scaling
(*)(v::T,c::Number) where T<:VectorField = T(v.components.*c,v.pt)
(*)(c::Number,v::T) where T<:VectorField = T(v.components.*c,v.pt)
(/)(v::T,c::Number) where T<:VectorField = T(v.components./c,v.pt)

# display
function Base.show(io::IO, v::VectorField)
    compact = get(io, :compact, false)

    print(io,round.(v.components,sigdigits=3)," at $(v.pt)")
    
end

function Base.show(io::IO, ::MIME"text/plain", v::VectorField)
    println(io,"Vector with components $(v.components)")
    print(io,"Defined at $(v.pt)")
end


end # module
