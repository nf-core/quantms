//
// ProteinQuant
//

params.resolve_conflict = [:]
params.pro_quant = [:]
params.msstatsconverter = [:]

include { IDCONFLICTRESOLVER } from '../../modules/local/openms/idconflictresolver/main' addParams( options: params.resolve_conflict)
include { PROTEINQUANTIFIER } from '../../modules/local/openms/proteinquantifier/main' addParams( options: params.pro_quant )
include { MSSTATSCONVERTER } from '../../modules/local/openms/msstatsconverter/main' addParams( options: params.msstatsconverter )

workflow PROTEINQUANT {
    take:
    conflict_file
    expdesign_file

    main:
    ch_version = Channel.empty()

    IDCONFLICTRESOLVER(conflict_file)
    ch_version = ch_version.mix(IDCONFLICTRESOLVER.out.version)

    PROTEINQUANTIFIER(IDCONFLICTRESOLVER.out.pro_resconf, expdesign_file)
    ch_version = ch_version.mix(PROTEINQUANTIFIER.out.version)

    MSSTATSCONVERTER(IDCONFLICTRESOLVER.out.pro_resconf, expdesign_file)
    ch_version = ch_version.mix(MSSTATSCONVERTER.out.version)

    emit:
    msstats_csv = MSSTATSCONVERTER.out.out_msstats
    out_mztab   = PROTEINQUANTIFIER.out.out_mztab

    version     = ch_version
}