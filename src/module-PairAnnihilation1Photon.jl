
"""
`module  JAC.PairAnnihilation1Photon`  ... a submodel of JAC that contains all methods for computing positron-bound-electron pair annihilation 
                                           (PEPA) with single-photon emission cross sections and rates; e^+ + |i(N)> --> |f(N-1)> + photon;
                                           it is using JAC, JAC.ManyElectron, JAC.Radial.
"""
module PairAnnihilation1Photon 

    using JAC, JAC.ManyElectron, JAC.Radial
    global JAC_counter = 0


    """
    `struct  PairAnnihilation1Photon.Settings`  ... defines a type for the details and parameters in computing positron-bound-electron pair 
             annihilation (PEPA) with single-photon emission cross sections and rates; e^+ + |i(N)> --> |f(N-1)> + photon.

        + multipoles              ::Array{EmMultipole}           ... Specifies the multipoles of the radiation field that are to be included.
        + gauges                  ::Array{UseGauge}              ... Specifies the gauges to be included into the computations.
        + positronEnergies        ::Array{Float64,1}             ... List of positron energies.
        + printBeforeComputation  ::Bool                         ... True, if all energies and lines are printed before their evaluation.
        + selectLines             ::Bool                         ... True, if lines are selected individually for the computations.
        + selectedLines           ::Array{Tuple{Int64,Int64},1}  ... List of lines, given by tupels (inital-level, final-level).
    """
    struct Settings 
        multipoles                ::Array{EmMultipole}
        gauges                    ::Array{UseGauge}
        positronEnergies          ::Array{Float64,1} 
        printBeforeComputation    ::Bool
        selectLines               ::Bool
        selectedLines             ::Array{Tuple{Int64,Int64},1} 
    end 


    """
    `JAC.PairAnnihilation1Photon.Settings()`  ... constructor for the default values of pair-annihilation photon line computations
    """
    function Settings()
        Settings(EmMultipole[], UseGauge[], Float64[], false, false, Tuple{Int64,Int64}[])
    end


     # `Base.show(io::IO, settings::PairAnnihilation1Photon.Settings)`  
     #		... prepares a proper printout of the variable settings::PairAnnihilation1Photon.Settings.
    function Base.show(io::IO, settings::PairAnnihilation1Photon.Settings) 
        println(io, "multipoles:               $(settings.multipoles)  ")
        println(io, "gauges:                   $(settings.gauges)  ")
        println(io, "positronEnergies:         $(settings.positronEnergies)  ")
        println(io, "printBeforeComputation:   $(settings.printBeforeComputation)  ")
        println(io, "selectLines:              $(settings.selectLines)  ")
        println(io, "selectedLines:            $(settings.selectedLines)  ")
    end


    """
    `struct  PairAnnihilation1Photon.Channel`  ... defines a type for a positron-bound-electron pair annihilation (PEPA) with single-photon 
             emission channel that specifies all quantum numbers, phases and amplitudes.

        + multipole      ::EmMultipole          ... Multipole of the photon absorption.
        + gauge          ::EmGauge              ... Gauge for dealing with the (coupled) radiation field.
        + kappa          ::Int64                ... partial-wave of the incoming free positron
        + symmetry       ::LevelSymmetry        ... total angular momentum and parity of the scattering state
        + phase          ::Float64              ... phase of the partial wave
        + amplitude      ::Complex{Float64}     ... PairAnnihilation1PhotonChannel amplitude associated with the given channel.
   """
    struct  Channel
        multipole        ::EmMultipole
        gauge            ::EmGauge
        kappa            ::Int64
        symmetry         ::LevelSymmetry
        phase            ::Float64
        amplitude        ::Complex{Float64}
    end


    """
    `struct  PairAnnihilation1Photon.Line`  ... defines a type for a positron-bound-electron pair-annihilation (photon) line that may 
                                                include the definition of channels.

        + initialLevel   ::Level                 ... initial-(state) level
        + finalLevel     ::Level                 ... final-(state) level
        + positronEnergy ::Float64                ... Energy of the (incoming free) positron.
        + photonEnergy   ::Float64                ... Energy of the emitted photon.
        + crossSection   ::EmProperty             ... Cross section for this pair-annihilation (photon) line.
        + hasChannels    ::Bool                   ... Determines whether the individual (sub-) channels are defined in terms of their 
                                                      free-positron energy, kappa, multipole, etc., or not.
        + channels       ::Array{PairAnnihilation1Photon.Channel,1}  ... List of PairAnnihilation1Photon.Channels of this line.
    """
    struct  Line
        initialLevel     ::Level
        finalLevel       ::Level
        positronEnergy   ::Float64
        photonEnergy     ::Float64
        crossSection     ::EmProperty
        hasChannels      ::Bool
        channels         ::Array{PairAnnihilation1Photon.Channel,1}
    end


    """
    `JAC.PairAnnihilation1Photon.Line()`  ... 'empty' constructor for a pair-annihilation (photon) line between a specified initial and 
                                              final level.
    """
    function Line()
        Line(Level(), Level(), 0., 0., EmProperty(0., 0.), false, PairAnnihilation1Photon[] )
    end


    # `Base.show(io::IO, line::PairAnnihilation1Photon.Line)`  ... prepares a proper printout of the variable line::PairAnnihilation1Photon.Line.
    function Base.show(io::IO, line::PairAnnihilation1Photon.Line) 
        println(io, "initialLevel:      $(line.initialLevel)  ")
        println(io, "finalLevel:        $(line.finalLevel)  ")
        println(io, "positronEnergy:    $(line.positronEnergy)  ")
        println(io, "photonEnergy:      $(line.photonEnergy)  ")
        println(io, "crossSection:      $(line.crossSection)  ")
        println(io, "hasChannels:       $(line.hasChannels)  ")
        println(io, "channels:          $(line.channels)  ")
    end


    """
    `JAC.PairAnnihilation1Photon.computeAmplitudesProperties(line::PairAnnihilation1Photon.Line, grid::Radial.Grid, 
                                                             settings::PairAnnihilation1Photon.Settings)`  ... to compute all amplitudes and 
         properties of the given line; a line::PairAnnihilation1Photon.Line is returned for which the amplitudes and properties are now evaluated.
    """
    function  computeAmplitudesProperties(line::PairAnnihilation1Photon.Line, grid::Radial.Grid, settings::PairAnnihilation1Photon.Settings)
        global JAC_counter
        newChannels = PairAnnihilation1Photon.Channel[]
        for channel in line.channels
            # Generate a continuum orbital
            JAC_counter = JAC_counter + 1
            if   JAC_counter < 20   println("PairAnnihilation1Photon.computeAmplitudes..-aa: warning ... no cont. orbital is generated.")  end
            phase  = 0.
            # Define a proper continuum basis from the initialLevel.basis and the continuum orbital
            JAC_counter = JAC_counter + 1
            if   JAC_counter < 20   println("PairAnnihilation1Photon.computeAmplitudes..-ab: warning ... no coninuum basis is yet generated.") end
            # Compute the transition matrix for the continuum and the initial-state basis
            JAC_counter = JAC_counter + 1
            if   JAC_counter < 20   println("PairAnnihilation1Photon.computeAmplitudes..-ac: warning ... no transition matrix is computed.") end
            # matrix    = JAC.PhotoIonization.computeMatrix(channel.multipole, channel.gauge, line.omega, line.finalLevel.basis, 
            #                                               line.initialLevel.basis, grid, settings)
            # amplitude = line.finalLevel.mc * matrix * line.initialLevel.mc 
            amplitude = 1.0 
            push!( newChannels, PairAnnihilation1Photon.Channel( channel.multipole, channel.gauge, channel.kappa, channel.symmetry, 
                                                                 phase, amplitude) )
        end
        # Calculate the photonrate and angular beta if requested
        JAC_counter = JAC_counter + 1
        if   JAC_counter < 20   println("PairAnnihilation1Photon.computeAmplitudesProperties-ba: warning ... cs set to -1.") end
        crossSection = EmProperty(-1., -1.)
        line = PairAnnihilation1Photon.Line( line.initialLevel, line.finalLevel, line.positronEnergy, line.photonEnergy, 
                                             crossSection, true, newChannels)
        return( line )
    end


    """
    `JAC.PairAnnihilation1Photon.computeLines(finalMultiplet::Multiplet, initialMultiplet::Multiplet, grid::Radial.Grid, 
                                              settings::PairAnnihilation1Photon.Settings; output::Bool=true)`  ... to compute the 
         pair-annihilation single-photon emission amplitudes and all properties as requested by the given settings. A list of 
         lines::Array{PairAnnihilation1Photon.Lines} is returned.
    """
    function  computeLines(finalMultiplet::Multiplet, initialMultiplet::Multiplet, grid::Radial.Grid, settings::PairAnnihilation1Photon.Settings; 
                           output::Bool=true)
        lines = JAC.PairAnnihilation1Photon.determineLines(finalMultiplet, initialMultiplet, settings)
        # Display all selected lines before the computations start
        if  settings.printBeforeComputation    JAC.PairAnnihilation1Photon.displayLines(lines)    end
        # Calculate all amplitudes and requested properties
        newLines = PairAnnihilation1Photon.Line[]
        for  line in lines
            newLine = JAC.PairAnnihilation1Photon.computeAmplitudesProperties(line, grid, settings) 
            push!( newLines, newLine)
        end
        # Print all results to screen
        JAC.PairAnnihilation1Photon.displayResults(lines)
        #
        if    output    return( lines )
        else            return( nothing )
        end
    end


    """
    `JAC.PairAnnihilation1Photon.determineChannels(finalLevel::Level, initialLevel::Level, settings::PairAnnihilation1Photon.Settings)`  
         ... to determine a list of pair-annihilation single-photon emission Channel for a transitions from the initial to final level and by 
         taking into account the particular settings of for this computation; an Array{PairAnnihilation1Photon.Channel,1} is returned.
    """
    function determineChannels(finalLevel::Level, initialLevel::Level, settings::PairAnnihilation1Photon.Settings)
        channels = PairAnnihilation1Photon.Channel[];   
        symi = LevelSymmetry(initialLevel.J, initialLevel.parity);    symf = LevelSymmetry(finalLevel.J, finalLevel.parity) 
        for  mp in settings.multipoles
            for  gauge in settings.gauges
                symList = JAC.AngularMomentum.allowedMultipoleSymmetries(symi, mp)
                ##x println("mp = $mp   symi = $symi   symList = $symList")
                for  symt in symList
                    kappaList = JAC.AngularMomentum.allowedKappaSymmetries(symt, symf)
                    for  kappa in kappaList
                        # Include further restrictions if appropriate
                        if     string(mp)[1] == 'E'  &&   gauge == BasicTypes.UseCoulomb      
                            push!(channels, PairAnnihilation1Photon.Channel(mp, JAC.Coulomb,   kappa, symt, 0., Complex(0.)) )
                        elseif string(mp)[1] == 'E'  &&   gauge == BasicTypes.UseBabushkin    
                            push!(channels, PairAnnihilation1Photon.Channel(mp, JAC.Babushkin, kappa, symt, 0., Complex(0.)) )  
                        elseif string(mp)[1] == 'M'                                
                            push!(channels, PairAnnihilation1Photon.Channel(mp, JAC.Magnetic,  kappa, symt, 0., Complex(0.)) ) 
                        end 
                    end
                end
            end
        end
        return( channels )  
    end


    """
    `JAC.PairAnnihilation1Photon.determineLines(finalMultiplet::Multiplet, initialMultiplet::Multiplet, 
                                                settings::PairAnnihilation1Photon.Settings)` ... to determine a list of 
         PairAnnihilation1Photon.Line's for transitions between levels from the initial- and final-state multiplets, and  by taking into account 
         the particular selections and settings for this computation; an Array{PairAnnihilation1Photon.Line,1} is returned. Apart from the 
         level specification, all physical properties are set to zero during the initialization process.
    """
    function  determineLines(finalMultiplet::Multiplet, initialMultiplet::Multiplet, settings::PairAnnihilation1Photon.Settings)
        if    settings.selectLines    selectLines   = true;   selectedLines = JAC.determine("selected lines", settings.selectedLines)
        else                          selectLines   = false
        end
    
        lines = PairAnnihilation1Photon.Line[]
        for  i = 1:length(initialMultiplet.levels)
            for  f = 1:length(finalMultiplet.levels)
                if  selectLines  &&  !(haskey(selectedLines, (i,f)) )    continue   end
                for  ep in settings.positronEnergies
                    omega = ep - (finalMultiplet.levels[f].energy - initialMultiplet.levels[i].energy) + 2* JAC.give("mc^2")
                    if  omega < 0    continue   end  

                    channels = JAC.PairAnnihilation1Photon.determineChannels(finalMultiplet.levels[f], initialMultiplet.levels[i], settings) 
                    push!( lines, PairAnnihilation1Photon.Line(initialMultiplet.levels[i], finalMultiplet.levels[f], ep, omega, 
                                                               EmProperty(0., 0.), true, channels) )
                end
            end
        end
        return( lines )
    end


    """
    `JAC.PairAnnihilation1Photon.displayLines(lines::Array{PairAnnihilation1Photon.Line,1})`  ... to display a list of lines and channels that 
         have been selected due to the prior settings. A neat table of all selected transitions and energies is printed but nothing is returned 
         otherwise.
    """
    function  displayLines(lines::Array{PairAnnihilation1Photon.Line,1})
        println(" ")
        println("  Selected pair-annihilation single-photon emission lines:")
        println(" ")
        println("  ", JAC.TableStrings.hLine(175))
        sa = "  ";   sb = "  "
        sa = sa * JAC.TableStrings.center(18, "i-level-f"; na=2);                                sb = sb * JAC.TableStrings.hBlank(20)
        sa = sa * JAC.TableStrings.center(18, "i--J^P--f"; na=4);                                sb = sb * JAC.TableStrings.hBlank(22)
        sa = sa * JAC.TableStrings.center(38, "Energies  " * JAC.TableStrings.inUnits("energy"); na=4);              
        sb = sb * JAC.TableStrings.center(38, " i--f       positron      omega"; na=4)
        sa = sa * JAC.TableStrings.flushleft(57, "List of multipoles, gauges, kappas and total symmetries"; na=4)  
        sb = sb * JAC.TableStrings.flushleft(57, "partial (multipole, gauge, total J^P)                  "; na=4)
        println(sa);    println(sb);    println("  ", JAC.TableStrings.hLine(175)) 
        #   
        for  line in lines
            sa  = "  ";    isym = LevelSymmetry( line.initialLevel.J, line.initialLevel.parity)
                           fsym = LevelSymmetry( line.finalLevel.J,   line.finalLevel.parity)
            sa = sa * JAC.TableStrings.center(18, JAC.TableStrings.levels_if(line.initialLevel.index, line.finalLevel.index); na=2)
            sa = sa * JAC.TableStrings.center(18, JAC.TableStrings.symmetries_if(isym, fsym); na=4)
            energy = line.initialLevel.energy - line.finalLevel.energy
            sa = sa * @sprintf("%.5e", Basics.convert("energy: from atomic", energy))              * "  "
            sa = sa * @sprintf("%.5e", Basics.convert("energy: from atomic", line.positronEnergy)) * "  "
            sa = sa * @sprintf("%.5e", Basics.convert("energy: from atomic", line.photonEnergy))   * "    "
            kappaMultipoleSymmetryList = Tuple{Int64,EmMultipole,EmGauge,LevelSymmetry}[]
            for  i in 1:length(line.channels)
                push!( kappaMultipoleSymmetryList, (line.channels[i].kappa, line.channels[i].multipole, line.channels[i].gauge, 
                                                    line.channels[i].symmetry) )
            end
            wa = JAC.TableStrings.kappaMultipoleSymmetryTupels(85, kappaMultipoleSymmetryList)
            sb = sa * wa[1];    println( sb )  
            for  i = 2:length(wa)
                sb = JAC.TableStrings.hBlank( length(sa) ) * wa[i];    println( sb )
            end
        end
        println("  ", JAC.TableStrings.hLine(175))
        #
        return( nothing )
    end


    """
    `JAC.PairAnnihilation1Photon.displayResults(lines::Array{PairAnnihilation1Photon.Line,1})`  ... to list all results, energies, cross sections, 
         etc. of the selected lines. A neat table is printed but nothing is returned otherwise.
    """
    function  displayResults(lines::Array{PairAnnihilation1Photon.Line,1})
        println(" ")
        println("  Pair-annihilation single-photon emission cross sections:")
        println(" ")
        println("  ", JAC.TableStrings.hLine(128))
        sa = "  ";   sb = "  "
        sa = sa * JAC.TableStrings.center(18, "i-level-f"; na=2);                                sb = sb * JAC.TableStrings.hBlank(20)
        sa = sa * JAC.TableStrings.center(18, "i--J^P--f"; na=4);                                sb = sb * JAC.TableStrings.hBlank(22)
        sa = sa * JAC.TableStrings.center(38, "Energies  " * JAC.TableStrings.inUnits("energy"); na=4);              
        sb = sb * JAC.TableStrings.center(38, " i--f       positron      omega"; na=4)
        sa = sa * JAC.TableStrings.center(10, "Multipoles"; na=1);                              sb = sb * JAC.TableStrings.hBlank(13)
        sa = sa * JAC.TableStrings.center(30, "Cou -- Cross section -- Bab"; na=3)      
        sb = sb * JAC.TableStrings.center(30, JAC.TableStrings.inUnits("cross section") * "          " * 
                                              JAC.TableStrings.inUnits("cross section"); na=3)
        println(sa);    println(sb);    println("  ", JAC.TableStrings.hLine(128)) 
        #   
        for  line in lines
            sa  = "  ";    isym = LevelSymmetry( line.initialLevel.J, line.initialLevel.parity)
                           fsym = LevelSymmetry( line.finalLevel.J,   line.finalLevel.parity)
            sa = sa * JAC.TableStrings.center(18, JAC.TableStrings.levels_if(line.initialLevel.index, line.finalLevel.index); na=2)
            sa = sa * JAC.TableStrings.center(18, JAC.TableStrings.symmetries_if(isym, fsym); na=4)
            energy = line.initialLevel.energy - line.finalLevel.energy
            sa = sa * @sprintf("%.5e", Basics.convert("energy: from atomic", energy))              * "  "
            sa = sa * @sprintf("%.5e", Basics.convert("energy: from atomic", line.positronEnergy)) * "  "
            sa = sa * @sprintf("%.5e", Basics.convert("energy: from atomic", line.photonEnergy))   * "     "
            multipoles = EmMultipole[]
            for  ch in line.channels
                multipoles = push!( multipoles, ch.multipole)
            end
            multipoles = unique(multipoles);   mpString = JAC.TableStrings.multipoleList(multipoles) * "          "
            sa = sa * JAC.TableStrings.flushleft(11, mpString[1:10];  na=2)
            sa = sa * @sprintf("%.6e", Basics.convert("cross section: from atomic", line.crossSection.Coulomb))     * "    "
            sa = sa * @sprintf("%.6e", Basics.convert("cross section: from atomic", line.crossSection.Babushkin))   * "    "
            println(sa)
        end
        println("  ", JAC.TableStrings.hLine(128))
        #
        return( nothing )
    end

end # module
