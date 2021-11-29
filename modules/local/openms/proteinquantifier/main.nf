// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process PROTEINQUANTIFIER {
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:[:], publish_by_meta:[]) }

    conda (params.enable_conda ? "bioconda::bumbershoot bioconda::comet-ms bioconda::crux-toolkit=3.2 bioconda::fido=1.0 conda-forge::gnuplot bioconda::luciphor2 =2020_04_03 bioconda::msgf_plus=2021.03.22 openms::openms=2.7.0pre bioconda::pepnovo=20101117 bioconda::percolator=3.5 bioconda::sirius-csifingerid=4.0.1
bioconda::thermorawfileparser=1.3.4 bioconda::xtandem=15.12.15.2 openms::openms-thirdparty=2.7.0pre" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://ftp.pride.ebi.ac.uk/pride/data/tools/quantms-dev.sif"
    } else {
        container "quay.io/bigbio/quantms:dev"
    }

    input:
    path epi_filt_resolve
    path pro_quant_exp

    output:
    path "protein_out.csv", emit: protein_out
    path "peptide_out.csv", emit: peptide_out
    path "*.mzTab", emit: out_mztab
    path "*.log"
    path "*.version.txt", emit: version

    script:
    def software = getSoftwareName(task.process)

    include_all = params.include_all ? "-include_all" : ""
    fix_peptides = params.fix_peptides ? "-fix_peptides" : ""
    normalize = params.normalize ? "-consensus:normalize" : ""

    """
    ProteinQuantifier \\
        -in ${epi_filt_resolve} \\
        -design ${pro_quant_exp} \\
        -out protein_out.csv \\
        -mztab out.mzTab \\
        -peptide_out peptide_out.csv \\
        -top $params.top \\
        -average $params.average \\
        ${include_all} \\
        ${fix_peptides} \\
        -ratios \\
        -threads $task.cpus \\
        ${normalize} \\
        -debug 100 \\
        > pro_quant.log

    echo \$(ProteinQuantifier 2>&1) > ${software}.version.txt
    """
}
