process PROTEOMICSLFQ {
    tag "${expdes.baseName}"
    label 'process_high'

    conda "bioconda::openms=2.9.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/openms:2.9.1--h135471a_0' :
        'quay.io/biocontainers/openms:2.9.1--h135471a_0' }"

    input:
    path(mzmls)
    path(id_files)
    path(expdes)
    path(fasta)

    output:
    path "${expdes.baseName}_openms.mzTab", emit: out_mztab
    path "${expdes.baseName}_openms.consensusXML", emit: out_consensusXML
    path "*msstats_in.csv", emit: out_msstats optional true
    path "*triqler_in.tsv", emit: out_triqler optional true
    path "debug_mergedIDs.idXML", emit: debug_mergedIDs optional true
    path "debug_mergedIDs_inference.idXML", emit: debug_mergedIDs_inference optional true
    path "debug_mergedIDsGreedyResolved.idXML", emit: debug_mergedIDsGreedyResolved optional true
    path "debug_mergedIDsGreedyResolvedFDR.idXML", emit: debug_mergedIDsGreedyResolvedFDR optional true
    path "debug_mergedIDsGreedyResolvedFDRFiltered.idXML", emit: debug_mergedIDsGreedyResolvedFDRFiltered optional true
    path "debug_mergedIDsFDRFilteredStrictlyUniqueResolved.idXML", emit: debug_mergedIDsFDRFilteredStrictlyUniqueResolved optional true
    path "*.log", emit: log
    path "versions.yml", emit: version

    script:
    def args = task.ext.args ?: ''
    def msstats_present = params.quantification_method == "feature_intensity" ? "-out_msstats ${expdes.baseName}_msstats_in.csv" : ""
    def triqler_present = (params.quantification_method == "feature_intensity") && (params.add_triqler_output) ? "-out_triqler ${expdes.baseName}_triqler_in.tsv" : ""
    def decoys_present = (params.quantify_decoys || ((params.quantification_method == "feature_intensity") && params.add_triqler_output)) ? '-PeptideQuantification:quantify_decoys' : ''

    """
    ProteomicsLFQ \\
        -threads ${task.cpus} \\
        -in ${(mzmls as List).join(' ')} \\
        -ids ${(id_files as List).join(' ')} \\
        -design ${expdes} \\
        -fasta ${fasta} \\
        -protein_inference ${params.protein_inference_method} \\
        -quantification_method ${params.quantification_method} \\
        -targeted_only ${params.targeted_only} \\
        -mass_recalibration ${params.mass_recalibration} \\
        -transfer_ids ${params.transfer_ids == 'off' ? 'false' : params.transfer_ids} \\
        -protein_quantification ${params.protein_quant} \\
        -alignment_order ${params.alignment_order} \\
        ${decoys_present} \\
        -psmFDR ${params.psm_level_fdr_cutoff} \\
        -proteinFDR ${params.protein_level_fdr_cutoff} \\
        -picked_proteinFDR ${params.picked_fdr} \\
        -out_cxml ${expdes.baseName}_openms.consensusXML \\
        -out ${expdes.baseName}_openms.mzTab \\
        ${msstats_present} \\
        ${triqler_present} \\
        $args \\
        2>&1 | tee proteomicslfq.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ProteomicsLFQ: \$(ProteomicsLFQ 2>&1 | grep -E '^Version(.*)' | sed 's/Version: //g' | cut -d ' ' -f 1)
    END_VERSIONS
    """
}
