
##x import Base.sort

function printList(levels)
  for l in levels    println(l.energy)   end
end

"""
`Basics.sort()`  ... sorts various object due to different criteria

  + `("multiplet: by energy", multiplet::Multiplet)`  
    ... to sort all levels in the multiplet into a sequence of increasing energy; a (new) multiplet::Multiplet is returned.
"""
function Basics.sort(sa::String, multiplet::Multiplet)
    !(sa == "multiplet: by energy")   &&   error("Unsupported keystring = $sa")

    sortedLevels = Base.sort( multiplet.levels , lt=isless)
    newLevels = Level[];   index = 0
    for lev in sortedLevels
        index = index + 1
        push!(newLevels, Level(lev.J, lev.M, lev.parity, index, lev.energy, lev.relativeOcc, lev.hasStateRep, lev.basis, lev.mc) )
    end
    
    newMultiplet = JAC.Multiplet(multiplet.name, newLevels)
    
    return( newMultiplet )  
end

    
"""
  + `("multiplet: by energy", multiplet::JAC.Hfs.IJF_Multiplet)`  
    ... to sort all hyperfine levels in the multiplet into a sequence of increasing energy; a (new) multiplet::JAC.Hfs.IJF_Multiplet 
        is returned.
"""
function Basics.sort(sa::String, multiplet::JAC.Hfs.IJF_Multiplet)
    !(sa == "multiplet: by energy")   &&   error("Unsupported keystring = $sa")

    sortedLevels = Base.sort( multiplet.levelFs , lt=isless)
    newLevels = JAC.Hfs.IJF_Level[];   index = 0
    for lev in sortedLevels
        index = index + 1
        push!(newLevels, JAC.Hfs.IJF_Level(lev.I, lev.F, lev.M, lev.parity, lev.energy, lev.hasStateRep, lev.basis, lev.mc) )
    end
    
    newMultiplet = JAC.Hfs.IJF_Multiplet(multiplet.name, newLevels)
    
    return( newMultiplet )  
end


